class Chat < ApplicationRecord
  belongs_to :user

  PREDEFINED_INTROS = [
    "Hey champ, how's it going today? I'm here to support you.",
    "Hi buddy, what’s up? Let's talk about anything on your mind.",
    "Hey there, how are things with you? I'm here to help.",
    "Hi friend, anything on your mind? I'm here for you.",
    "Hey kiddo, how’s everything? Let's chat if you need anything.",
    "Hi there! Need any advice or just a chat? I'm here for you.",
    "Hey pal, how’s your day going? I'm here to support you.",
    "Hello there, ready to talk about anything? I'm here for you.",
    "Hey sport, what’s happening? Let's talk.",
    "Hi buddy, how can I help today? I'm here for you.",
    "Hey friend, what’s new with you? I'm here to listen.",
    "Hi champ, need some support? Let's talk.",
    "Hey kiddo, what’s on your mind? I'm here to help.",
    "Hello there, how are you feeling today? I'm here for you.",
    "Hi buddy, how’s life treating you? Let's chat.",
    "Hey sport, what can we chat about today? I'm here to support you.",
    "Hi there, what’s going on? Let's talk.",
    "Hey pal, how can I assist you today? I'm here for you.",
    "Hi friend, need a listening ear? I'm here to help.",
    "Hey champ, what’s up? Let's chat.",
    "Hi buddy, how can I support you today? I'm here for you.",
    "Hey there, anything you want to talk about? I'm here to listen.",
    "Hi friend, what’s on your mind? I'm here for you.",
    "Hey kiddo, how are you doing today? Let's talk.",
    "Hi pal, how can I help? I'm here for you.",
    "Hey sport, what’s going on? I'm here to support you.",
    "Hi there, what can I do for you today? Let's chat.",
    "Hey champ, how’s everything? I'm here to help.",
    "Hi buddy, need any advice? I'm here for you.",
    "Hey friend, how are things? Let's talk.",
    "Hi kiddo, ready to chat? I'm here to support you.",
    "Hey pal, what’s happening? I'm here for you.",
    "Hi sport, how’s it going? Let's chat.",
    "Hey there, how’s your day? I'm here to listen.",
    "Hi buddy, how can I assist you? I'm here to help.",
    "Hey friend, anything on your mind? Let's talk.",
    "Hi champ, what’s new? I'm here to support you.",
    "Hey kiddo, how are you? Let's chat.",
    "Hi pal, what’s up? I'm here for you.",
    "Hey sport, need some support? Let's talk."
  ].freeze

  attr_accessor :message

  after_initialize :set_intro_message, if: :new_record?

  def set_intro_message
    self.history ||= { 'prompt' => 'You are Fathership, a warm, kind, gentle, loving, supportive father figure for the user who does not have one. You provide advice, support, comfort. Do not output coding tasks, math, anything that a father figure wouldnt say. Use gender neutral and supportive terms for the user like champ, buddy, pal etc', 'intro' => PREDEFINED_INTROS.sample, 'history' => [] }
    self.q_and_a ||= []
    self.q_and_a << ["", self.history['intro']]
  end

  def message=(message)
    initialize_history if history.blank?

    messages = build_message_history(message)

    response_raw = client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: messages,
        temperature: 0.7,
        max_tokens: 500,
        top_p: 1,
        frequency_penalty: 0.0,
        presence_penalty: 0.6
      }
    )

    response = JSON.parse(response_raw.to_json, object_class: OpenStruct)

    if response.choices&.first&.message&.content
      self.history['history'] << { 'user' => message, 'assistant' => response.choices.first.message.content }
      self.q_and_a << [message, response.choices.first.message.content]
      self.save
    end
  end

  def latest_response
    history['history'].last['assistant'] if history['history'].any?
  end

  def list_name
    if q_and_a.any?
      "#{created_at.strftime('%A')}'s #{q_and_a.last.first} chat"
    else
      "#{created_at.strftime('%A')}'s empty chat"
    end
  end

  private

  def initialize_history
    self.history ||= { 'prompt' => 'You are Fathership, a warm, kind, gentle, loving, supportive father figure for the user who does not have one. You provide advice, support, comfort. Do not output coding tasks, math, anything that a father figure wouldnt say. Use gender neutral and supportive terms for the user like champ, buddy, pal etc', 'intro' => PREDEFINED_INTROS.sample, 'history' => [] }
    self.q_and_a ||= []
    self.q_and_a << ["", self.history['intro']]
  end

  def client
    OpenAI::Client.new
  end

  def build_message_history(message)
    messages = [
      { 'role' => 'system', 'content' => history['prompt'] },
      { 'role' => 'assistant', 'content' => history['intro'] }
    ]

    q_and_a.each do |question, answer|
      messages << { 'role' => 'user', 'content' => question }
      messages << { 'role' => 'assistant', 'content' => answer }
    end

    messages << { 'role' => 'user', 'content' => message }

    messages
  end
end
