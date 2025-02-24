# frozen_string_literal: true

class EmployeeMailer < ApplicationMailer
  def invitation
    @employee = params[:employee]

    mail to: @employee.user.email_address_with_name, subject: "Get paid by #{@employee.event.name} as a 1099 contractor", from: hcb_email_with_name_of(@employee.event)
  end

  def approved
    @payment = params[:payment]
    @employee = @payment.employee

    mail to: @employee.user.email_address_with_name, subject: "[Payroll] Approved: #{@payment.title}", from: hcb_email_with_name_of(@employee.event)
  end

  def rejected
    @payment = params[:payment]
    @employee = @payment.employee

    mail to: @employee.user.email_address_with_name, subject: "[Payroll] Rejected: #{@payment.title}", from: hcb_email_with_name_of(@employee.event)
  end

  def review_requested
    @payment = params[:payment]
    @employee = @payment.employee

    mail to: @employee.event.users.excluding(@employee.user).map(&:email_address_with_name),
         subject: "[Payroll / #{@employee.event.name}] Review Requested: #{@payment.title}"
  end

  def failed
    @payment = params[:payment]
    @employee = @payment.employee
    @reason = params[:reason]

    mail subject: "[Payroll] Transfer for #{@payment.name} failed to send", to: @employee.user.email_address_with_name
  end

end
