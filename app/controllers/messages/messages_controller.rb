class Messages::MessagesController < ApplicationController
  before_action :validate_send_message, only: [:send_message]
  before_action :validate_get_message, only: [:get_messages]
  def send_message
    request_body = JSON.parse(request.body.read)
    chat_id = request_body['chat_id']
    user_id = request_body['user_id']
    sender = User.find(user_id).name
    message_text = request_body['message_text']
    message = Message.create(chat_id:, user_id:, message_text:, sender:)
    chat = Chat.find(chat_id).update(updated_at: Time.now)
    if message.persisted? && chat
      render json: { status: 'success', message: 'Message sent successfully' }, status: :ok
    else
      render json: { status: 'failed', error: 'Message sending failed', errors: message.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def get_messages
    request_body = JSON.parse(request.body.read)
    user_id = request_body['user_id']
    chat_id = request_body['chat_id']
    messages = Chat.find(chat_id).messages.order(created_at: :desc).limit(10).map { |message| message.as_json(except: [:created_at, :updated_at]) }
    render json: { status: 'success', message: 'Messages found', messages: messages }, status: :ok
  end

  private

  def send_message_params
    params.require(:message).permit(:chat_id, :user_id, :message_text)
  end

  def validate_send_message
    if send_message_params[:chat_id].nil? || send_message_params[:user_id].nil? || send_message_params[:message_text].nil?
      render json: { status: 'failed', error: 'Invalid parameters' }, status: :unprocessable_entity
    end
    chat = Chat.joins(:users).where(id: send_message_params[:chat_id], users: { id: send_message_params[:user_id] }).first
    return render json: { status: 'failed', error: 'User not found, chat not found, or user is not a member of the chat' }, status: :unprocessable_entity unless chat
  end

  def get_message_params
    params.require(:message).permit(:chat_id, :user_id)
  end

  def validate_get_message
    if get_message_params[:chat_id].nil? || get_message_params[:user_id].nil?
      render json: { status: 'failed', error: 'Invalid parameters' }, status: :unprocessable_entity
    end
    chat = Chat.joins(:users).where(id: get_message_params[:chat_id], users: { id: get_message_params[:user_id] }).first
    return render json: { status: 'failed', error: 'User not found, chat not found, or user is not a member of the chat' }, status: :unprocessable_entity unless chat
  end
end