# frozen_string_literal: true

class LoginCodeMailer < ApplicationMailer
  def send_code(email_address, pretty_login_code)
    @pretty_login_code = pretty_login_code

    mail(to: email_address,
         subject: "Hack Club Login Code: #{@pretty_login_code}",
         from: "Hack Club <login@#{DOMAIN}>",
         reply_to: "HCB <hcb@#{DOMAIN}>")
  end

end
