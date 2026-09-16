class ExpireHoldJob < ApplicationJob
  queue_as :default

  def perform(hold_id)
    Hold.transaction do
      hold = Hold.lock.find_by(id: hold_id)

      return unless hold
      return unless hold.active?
      return unless hold.expired?

      hold.update!(
        status: :expired
      )
    end

    Rails.cache.delete_matched(
      "trip-search*"
    )
  end
end
