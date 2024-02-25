# frozen_string_literal: true

class ReceiptPolicy < ApplicationPolicy
  def destroy?
    user&.admin? ||
      (record&.receiptable&.event&.users&.include?(user) && unlocked?) ||
      # Checking if receiptable is nil prevents unauthorized
      # deletion when user no longer has access to an org
      (record&.receiptable.nil? && record&.user == user)
  end

  def link?
    record.receiptable.nil? && record.user == user
  end

  private

  def unlocked?
    !record&.receiptable.respond_to?(:locked) ? true : !record.receiptable.locked?
  end

end
