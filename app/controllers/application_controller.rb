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
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end
end
