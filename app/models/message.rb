class Message < ApplicationRecord
    belongs_to :chat
    belongs_to :user
    validates :message_text, presence: true
end
