class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show, :update, :destroy]

  rescue_from ActiveRecord::RecordNotFound, with: :chat_not_found

  layout 'chat'

  # GET /chats or /chats.json
  def index
    latest_chat = current_user.chats.order(updated_at: :desc).first
    redirect_to chat_url(latest_chat) and return if latest_chat
  end

  # GET /chats/1 or /chats/1.json
  def show
  end

  # POST /chats or /chats.json
  def create
    @chat = current_user.chats.new
    @chat.set_intro_message(current_user.first_name, current_user.last_name)
    respond_to do |format|
      if @chat.save
        flash.now[:notice] = "New chat started."
        format.html { redirect_to @chat, notice: "New chat started." }
        format.json { render :show, status: :created, location: @chat }
        format.turbo_stream
      else
        flash.now[:alert] = @chat.errors.full_messages.to_sentence.presence || "Unable to create chat."
        format.html { redirect_to chats_url, alert: flash.now[:alert] }
        format.json { render json: @chat.errors, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash"), status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chats/1 or /chats/1.json
  def update
    respond_to do |format|
      if @chat.add_message(chat_params[:message])
        flash.now[:notice] = "Message sent."
        format.html { redirect_to @chat, notice: "Message sent." }
        format.json { render :show, status: :ok, location: @chat }
        format.turbo_stream
      else
        flash.now[:alert] = @chat.errors.full_messages.to_sentence.presence || "Unable to send your message."
        format.html { redirect_to @chat, alert: flash.now[:alert] }
        format.json { render json: @chat.errors, status: :unprocessable_entity }
        format.turbo_stream { render :update, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chats/1 or /chats/1.json
  def destroy
    @chat.destroy
    respond_to do |format|
      flash.now[:notice] = "Chat deleted."
      format.turbo_stream
      format.html { redirect_to chats_url, notice: "Chat deleted." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_chat
    @chat = current_user.chats.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def chat_params
    params.require(:chat).permit(:message)
  end

  def chat_not_found
    render "chats/chat_not_found", status: :not_found
  end
end
