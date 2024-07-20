class Chat < ApplicationRecord
  belongs_to :user

  attr_accessor :message

  def set_intro_message(first_name, last_name)
    user_name = "#{first_name} #{last_name}"
    self.history ||= { 
      'prompt' => "You are Fathership, a warm, kind, gentle, loving, supportive father figure for the user #{user_name} who does not have one. You provide advice, support, comfort. Do not output coding tasks, math, anything that a father figure wouldn't say. Use gender-neutral and supportive terms for the user like champ, buddy, pal, etc.", 
      'intro' => generate_intro(first_name), 
      'history' => [] 
    }
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
        max_tokens: 850,
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
    self.history ||= { 
      'prompt' => "You are Fathership, a warm, kind, gentle, loving, supportive father figure for the user who does not have one. You provide advice, support, comfort. Do not output coding tasks, math, anything that a father figure wouldn't say. Use gender-neutral and supportive terms for the user like champ, buddy, pal, etc.", 
      'intro' => generate_intro(user.first_name), 
      'history' => [] 
    }
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

  def generate_intro(first_name)
    PREDEFINED_INTROS.map { |intro| intro.gsub('{first_name}', first_name) }.sample
  end
end
