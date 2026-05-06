# frozen_string_literal: true

class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: lambda {
    redirect_to new_registration_url, alert: t("flash.alert.try_again_later")
  }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: t("flash.notice.welcome_signed_up")
    elsif request.headers["Turbo-Frame"] == "modal"
      render turbo_stream: turbo_stream.replace(
        "modal",
        partial: "registrations/modal",
        locals: { user: @user, email_address: params[:email_address] }
      ), status: :unprocessable_entity
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [:name, :email_address, :password, :password_confirmation, :organizer])
  end
end
