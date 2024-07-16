class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show, :edit, :update, :destroy, :chat_with_assistant]
  before_action :authorize_user!, only: [:show, :edit, :update, :destroy, :chat_with_assistant]

  rescue_from ActiveRecord::RecordNotFound, with: :chat_not_found

  layout 'chat'

  # Predefined intros
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

  # GET /chats or /chats.json
  def index
    @chats = Chat.none
    if current_user.chats.any?
      redirect_to chat_url(current_user.chats.last)
    end
  end

  # GET /chats/1 or /chats/1.json
  def show
    @intro_message = PREDEFINED_INTROS.sample if @chat.history.blank?
  end

  # GET /chats/new
  def new
    @chat = Chat.new
  end

  # GET /chats/1/edit
  def edit
  end

  # POST /chats or /chats.json
  def create
    @chat = Chat.new(user_id: current_user.id)

    respond_to do |format|
      if @chat.save
        format.html { redirect_to chat_url(@chat) }
        format.json { render :show, status: :created, location: @chat }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chat.errors, status: :unprocessable_entity }
        format.turbo_stream
      end
    end
  end

  # PATCH/PUT /chats/1 or /chats/1.json
  def update
    respond_to do |format|
      if @chat.update(chat_params)
        format.html { redirect_to chat_url(@chat) }
        format.json { render :show, status: :ok, location: @chat }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chat.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chats/1 or /chats/1.json
  def destroy
    @chat = Chat.find(params[:id])
    @chat.destroy
    respond_to do |format|
      format.html { redirect_to chats_url}
      format.json { head :no_content }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@chat)) }
    end
  end

  # POST /chats/1/chat_with_assistant
  def chat_with_assistant
    message = params[:message]

    if @chat.add_message(message)
      render json: { response: @chat.latest_response }, status: :ok
    else
      render json: { error: 'Failed to get response from assistant' }, status: :unprocessable_entity
    end
  end

  private

  def authorize_user!
    unless @chat.user == current_user
      render 'chats/unauthorized', status: :forbidden
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_chat
    @chat = Chat.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def chat_params
    params.require(:chat).permit(:message)
  end

  def chat_not_found
    render 'chats/chat_not_found', status: :not_found
  end
end
