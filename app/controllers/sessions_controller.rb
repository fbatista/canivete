# frozen_string_literal: true

class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: lambda {
    redirect_to new_session_url, alert: t("flash.alert.try_again_later")
  }

  def new; end

  def create
    if (user = User.authenticate_by(params.expect(session: [:email_address, :password])))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: t("flash.alert.invalid_credentials")
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: t("flash.notice.signed_out")
  end
end
