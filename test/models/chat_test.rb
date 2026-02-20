require "test_helper"

class ChatTest < ActiveSupport::TestCase
  setup do
    @chat = chats(:one)
  end

  test "add_message stores a user and assistant turn" do
    assert @chat.add_message("Can you give me a small win for today?")

    @chat.reload
    turn = @chat.send(:turns).last
    assert_equal "Can you give me a small win for today?", turn["user"]
    assert_predicate turn["assistant"], :present?
  end

  test "rejects messages longer than configured limit" do
    long_message = "a" * (Chat::MESSAGE_CHAR_LIMIT + 1)

    assert_not @chat.add_message(long_message)
    assert_includes @chat.errors.full_messages.to_sentence, Chat::MESSAGE_CHAR_LIMIT.to_s
  end

  test "conversation pairs include intro" do
    pairs = @chat.conversation_pairs
    assert_equal "", pairs.first.first
    assert_predicate pairs.first.last, :present?
  end
end
