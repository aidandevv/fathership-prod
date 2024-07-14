class UserAccountController < ApplicationController
  before_action :authenticate_user!
  def account_modification
  end
end
