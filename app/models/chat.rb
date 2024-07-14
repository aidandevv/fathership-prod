# == Schema Information
#
# Table name: chats
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  history    :json
#  q_and_a    :string           default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Chat < ApplicationRecord
  belongs_to :user

  attr_accessor :message

  def message=(message)
    self.history = { 'prompt' => message, 'history' => [] } if history.blank?

    messages = [
      { 'role' => 'system', 'content' => history['prompt'] }
    ]
    q_and_a.each do |question, answer|
      messages << { 'role' => 'user', 'content' => question }
      messages << { 'role' => 'assistant', 'content' => answer }
    end
    messages << { 'role' => 'user', 'content' => message } if messages.size > 1

    response_raw = client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages:,
        temperature: 0.7,
        max_tokens: 500,
        top_p: 1,
        frequency_penalty: 0.0,
        presence_penalty: 0.6
      }
    )


    self.history['history'] << response_raw

    Rails.logger.debug response_raw
    response = JSON.parse(response_raw.to_json, object_class: OpenStruct)

    self.q_and_a << [message, response.choices[0].message.content]
  end
  def list_name
    if q_and_a.any?
      "Your \'#{q_and_a.last.first}\' conversation"
    else
      "Empty conversation"
    end
  end
  
  private

  def client
    OpenAI::Client.new
  end
end
