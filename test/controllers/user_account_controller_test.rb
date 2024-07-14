require "test_helper"

class UserAccountControllerTest < ActionDispatch::IntegrationTest
  test "should get account_modification" do
    get user_account_account_modification_url
    assert_response :success
  end
end
