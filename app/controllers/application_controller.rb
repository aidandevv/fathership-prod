class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # Override the path to which Devise redirects after sign in
  def after_sign_in_path_for(resource)
    chats_path
  end

  # Override the path to which Devise redirects after sign up
  def after_sign_up_path_for(resource)
    chats_path
  end
end
