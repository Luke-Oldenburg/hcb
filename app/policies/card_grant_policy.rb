# frozen_string_literal: true

class CardGrantPolicy < ApplicationPolicy
  def new?
    admin_or_user
  end

  def create?
    admin_or_user
  end

  def show?
    user&.admin? || record.user == user
  end

  def activate?
    user&.admin? || record.user == user
  end

  def cancel?
    admin_or_user
  end

  def admin_or_user
    user&.admin? || record.event.users.include?(user)
  end

end
