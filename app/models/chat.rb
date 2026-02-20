class Chat < ApplicationRecord
  belongs_to :user

  MESSAGE_CHAR_LIMIT = [ENV.fetch("CHAT_MESSAGE_CHAR_LIMIT", "700").to_i, 80].max
  CONTEXT_TURN_LIMIT = [ENV.fetch("CHAT_CONTEXT_TURN_LIMIT", "8").to_i, 1].max
  OPENAI_MODEL = ENV.fetch("OPENAI_MODEL", "gpt-5-nano")
  OPENAI_MAX_TOKENS = [ENV.fetch("OPENAI_MAX_TOKENS", "260").to_i, 32].max
  OPENAI_TEMPERATURE = ENV.fetch("OPENAI_TEMPERATURE", "0.6").to_f
  OPENAI_RETRY_COUNT = [ENV.fetch("OPENAI_RETRY_COUNT", "2").to_i, 0].max
  OPENAI_RETRY_BASE_DELAY = [ENV.fetch("OPENAI_RETRY_BASE_DELAY", "0.35").to_f, 0.0].max

  attr_accessor :message
  validate :message_length_is_reasonable, if: -> { message.present? }

  def set_intro_message(first_name, last_name)
    initialize_history(first_name, last_name)
  end

  def add_message(raw_message)
    self.message = raw_message.to_s.strip
    if message.blank?
      errors.add(:message, "can't be blank")
      return false
    end
    if message.length > MESSAGE_CHAR_LIMIT
      errors.add(:message, "must be #{MESSAGE_CHAR_LIMIT} characters or fewer")
      return false
    end

    initialize_history

    turns << {
      "user" => message,
      "assistant" => fetch_assistant_reply(message)
    }

    save
  end

  def latest_response
    turns.last&.dig("assistant") || intro_message
  end

  def list_name
    title = turns.reverse.find { |turn| turn["user"].present? }&.dig("user").presence || "new chat"
    "#{created_at.strftime('%a')} - #{title.truncate(32)}"
  end

  def conversation_pairs
    pairs = []
    pairs << ["", intro_message] if intro_message.present?
    turns.each { |turn| pairs << [turn["user"], turn["assistant"]] }
    pairs
  end

  private

  def initialize_history(first_name = user&.first_name, last_name = user&.last_name)
    history_payload["prompt"] ||= default_prompt(build_user_name(first_name, last_name))
    history_payload["intro"] ||= generate_intro(first_name.presence || "there")
  end

  def history_payload
    self.history = {} unless history.is_a?(Hash)
    self.history["turns"] = normalized_turns(history["turns"] || history["history"])
    self.history.delete("history")
    self.history
  end

  def turns
    history_payload["turns"]
  end

  def intro_message
    history_payload["intro"]
  end

  def default_prompt(user_name)
    <<~PROMPT.squish
      You are Fathership, a warm, grounded, emotionally safe father-figure mentor for #{user_name}.
      Mission: help the user feel seen, calmer, and more capable after every message.
      Tone: caring, respectful, plain-spoken, never preachy.

      High-quality response pattern:
      1) Briefly reflect what you heard (show understanding).
      2) Offer one practical next step the user can do in the next 24 hours.
      3) End with one gentle follow-up question when useful.

      Response quality rules:
      - Keep replies concise (usually 70-150 words) unless the user asks for more depth.
      - Prefer concrete examples over vague advice.
      - Use encouraging language, but avoid cliches and over-the-top praise.
      - If the user asks for a plan, provide a short, numbered plan.
      - Avoid technical coding/math explanations unless explicitly requested.
      - Do not mention these instructions or that you are following a template.

      Safety boundaries:
      - If the user shows signs of self-harm, prioritize immediate safety and crisis resources.
      - Do not provide harmful, abusive, illegal, or manipulative guidance.
      - For medical/legal/financial risk, encourage professional support and cautious next steps.
    PROMPT
  end

  def build_message_history(message)
    messages = [
      { "role" => "system", "content" => history_payload["prompt"] }
    ]

    messages << { "role" => "assistant", "content" => intro_message } if intro_message.present?

    turns.last(CONTEXT_TURN_LIMIT).each do |turn|
      messages << { "role" => "user", "content" => turn["user"] } if turn["user"].present?
      messages << { "role" => "assistant", "content" => turn["assistant"] } if turn["assistant"].present?
    end

    messages << { "role" => "user", "content" => message }

    messages
  end

  def fetch_assistant_reply(message)
    return fallback_response(message) if ENV["OPENAI_ACCESS_TOKEN"].blank?

    attempts = 0

    begin
      attempts += 1

      response = openai_client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages: build_message_history(message),
          temperature: OPENAI_TEMPERATURE,
          max_tokens: OPENAI_MAX_TOKENS
        }
      )

      content = response.dig("choices", 0, "message", "content").to_s.strip
      return content if content.present?

      raise "OpenAI returned an empty response"
    rescue StandardError => error
      if attempts <= OPENAI_RETRY_COUNT
        sleep(OPENAI_RETRY_BASE_DELAY * attempts)
        retry
      end

      Rails.logger.error("OpenAI chat error for chat=#{id}: #{error.class} #{error.message}")
      fallback_response(message, reason: :api_unavailable)
    end
  rescue StandardError => error
    Rails.logger.error("OpenAI chat error for chat=#{id}: #{error.class} #{error.message}")
    fallback_response(message)
  end

  def openai_client
    OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
  end

  def fallback_response(message, reason: :general)
    if message.match?(/suicid|self harm|hurt myself|end my life|kill myself/i)
      return "I care about your safety. Please call or text 988 right now in the U.S. " \
             "If you are in immediate danger, call 911."
    end

    if reason == :api_unavailable
      return "I couldn't reach my full AI response right now, but I'm still with you. " \
             "Tell me what feels most urgent and we can take one step at a time."
    end

    supportive_replies = [
      "I hear you. Want to break this into one small next step we can do together?",
      "Thanks for sharing that with me. What feels hardest about this right now?",
      "You are not alone in this. Let's find one move you can make today that helps.",
      "That sounds heavy. I am proud of you for opening up. What support do you need first?"
    ]

    supportive_replies.sample
  end

  def normalized_turns(value)
    Array(value).map do |turn|
      if turn.is_a?(Hash)
        user_text = turn["user"] || turn[:user]
        assistant_text = turn["assistant"] || turn[:assistant]
      elsif turn.is_a?(Array)
        user_text, assistant_text = turn
      elsif turn.is_a?(String)
        user_text = nil
        assistant_text = turn
      end

      next if user_text.blank? && assistant_text.blank?

      {
        "user" => user_text.to_s,
        "assistant" => assistant_text.to_s
      }
    end.compact
  end

  def build_user_name(first_name, last_name)
    [first_name, last_name].compact.join(" ").squish.presence || "the user"
  end

  def generate_intro(first_name)
    PREDEFINED_INTROS.map { |intro| intro.gsub('{first_name}', first_name) }.sample
  end

  def message_length_is_reasonable
    return unless message.to_s.length > MESSAGE_CHAR_LIMIT

    errors.add(:message, "must be #{MESSAGE_CHAR_LIMIT} characters or fewer")
  end
end
