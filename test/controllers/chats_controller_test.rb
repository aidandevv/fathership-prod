require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @chat = chats(:one)
    sign_in @user
  end

  test "index redirects to most recent chat" do
    get chats_url
    assert_redirected_to chat_url(@chat)
  end

  test "should create chat" do
    assert_difference("Chat.count") do
      post chats_url
    end

    assert_redirected_to chat_url(Chat.last)
  end

  test "should show chat" do
    get chat_url(@chat)
    assert_response :success
  end

  test "should update chat with new message" do
    patch chat_url(@chat), params: { chat: { message: "I need help staying focused." } }

    assert_redirected_to chat_url(@chat)
    @chat.reload
    assert_equal "I need help staying focused.", @chat.send(:turns).last["user"]
    assert_predicate @chat.latest_response, :present?
  end

  test "should destroy chat" do
    assert_difference("Chat.count", -1) do
      delete chat_url(@chat)
    end

    assert_redirected_to chats_url
  end
end
