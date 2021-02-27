class CanonicalTransactionPolicy < ApplicationPolicy
  def show?
    admin_or_teammember
  end

  def export?
    admin_or_teammember
  end

  def waive_fee?
    user&.admin?
  end

  def unwaive_fee?
    user&.admin?
  end

  def mark_bank_fee?
    user&.admin?
  end

  private

  def admin_or_teammember
    user&.admin? || record&.event&.users&.include?(user)
  end
end
