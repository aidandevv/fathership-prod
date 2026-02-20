require "test_helper"

class SupportControllerTest < ActionDispatch::IntegrationTest
  test "should get support page" do
    get support_url
    assert_response :success
  end
end
