defmodule EmqRedisAuthTest do
  use ExUnit.Case, async: true
  doctest EmqRedisAuth
  require EmqRedisAuth.Compat

  @user "such_user"
  @admin_user "admin_much_user"
  @pass "much_password"
  @wtopic "much/chat/write"
  @wtopic_wildcard "much/wildcard/+"
  @wtopic_wildcard_string "much/wildcard/chat"
  @rtopic "much/chat/read"
  @encrypted_pass "PBKDF2$sha256$1000$jpZlWoGyBrmwDn5L$tBZHHs52NErO9tz5exw1QiJ03f5b/bfq"
  @invalid_credentials {:error, :invalid_credentials}
  @ok :ok
  @mqtt_client_user_record EmqRedisAuth.Compat.mqtt_client(username: @user)
  @mqtt_client_admin_record EmqRedisAuth.Compat.mqtt_client(username: @admin_user)

  setup_all do
    :emqttd_access_control.start_link()
    {:ok, _emttd_redis_auth} = EmqRedisAuth.start(nil, nil)

    EmqRedisAuth.Redis.command(["SET", @admin_user, @encrypted_pass])
    EmqRedisAuth.Redis.command(["SET", @user, @encrypted_pass])
    EmqRedisAuth.Redis.command(["SET", @user <> "-" <> @wtopic, 2])
    EmqRedisAuth.Redis.command(["SET", @user <> "-" <> @wtopic_wildcard, 2])
    EmqRedisAuth.Redis.command(["SET", @user <> "-" <> @rtopic, 1])

    {:ok, []}
  end

  test "when user doesn't exist" do
    mqtt_client = EmqRedisAuth.Compat.mqtt_client(username: "not_user")
    assert EmqRedisAuth.AuthBody.check(mqtt_client, "some_pass", []) == @invalid_credentials
  end

  test "when user exist" do
    assert EmqRedisAuth.AuthBody.check(@mqtt_client_user_record, @pass, []) == @ok
  end

  test "when user can publish topic" do
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_user_record, :publish, @wtopic}, nil) == :allow
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_admin_record, :publish, @wtopic}, nil) == :allow
  end

  test "when non admin user try to publish or subscribe to wildcard topic" do
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_user_record, :publish, "#"}, nil) == :deny
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_user_record, :subscribe, "#"}, nil) == :deny
  end

  test "when user can publish to wildcard topic" do
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_user_record, :publish, @wtopic_wildcard_string}, nil) == :allow
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_admin_record, :publish, @wtopic_wildcard_string}, nil) == :allow
  end

  test "when user can subscribe topic" do
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_user_record, :subscribe, @wtopic}, nil) == :allow
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_user_record, :subscribe, @rtopic}, nil) == :allow

    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_admin_record, :subscribe, @wtopic}, nil) == :allow
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_admin_record, :subscribe, @rtopic}, nil) == :allow
  end

  test "when user cannot subscribe or publish topic" do
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_user_record, :subscribe, "not-valid-topic"}, nil) == :deny
    assert EmqRedisAuth.AclBody.check_acl({@mqtt_client_user_record, :publish, "not-valid-topic"}, nil) == :deny
  end
end
