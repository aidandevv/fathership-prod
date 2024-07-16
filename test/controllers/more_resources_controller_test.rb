require "test_helper"

class MoreResourcesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get more_resources_index_url
    assert_response :success
  end
end
