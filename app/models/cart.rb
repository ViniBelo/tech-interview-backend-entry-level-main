class Cart < ApplicationRecord
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }

  def mark_as_abandoned = update(abandoned: true)

  def abandoned_for_a_week_or_more?
    return false unless abandoned?

    last_interaction_at.before?(7.days.ago)
  end

  def remove_if_abandoned
    destroy if abandoned_for_a_week_or_more?
  end
end
