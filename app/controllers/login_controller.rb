class LoginController < ApplicationController

  before_filter :authorize, :except => [:login]

  def login
    if request.post?
      @user = User.authenticate(params[:user_login][:username],params[:user_login][:password])
      if @user
        session[:user_id] = @user.id
        redirect_to dashboard_path 
      else
        flash[:notice] ="Username/password invalid"
        render action: "login"
      end
    end
  end

  def logout
    session[:user_id] = nil
    flash[:notice] = "You have logged out of your session"
    redirect_to login_login_path
  end

end
