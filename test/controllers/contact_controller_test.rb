require "test_helper"

class ContactControllerTest < ActionDispatch::IntegrationTest
  test "should get contact page" do
    get contact_url
    assert_response :success
  end
end
