class LoginController < ApplicationController

  before_filter :authorize, :except => [:login]

  def login
    if request.post?
      @user = User.authenticate(params[:user_login][:username],params[:user_login][:password])
      if @user
        session[:user_id] = @user.id
        redirect_to main_index_path 
      else
        flash[:notice] ="Usuario/contrasena invalida"
        render action: login
      end
    end
  end

  def logout
    session[:user_id] = nil
    flash[:notice] = "Su sesion ha terminado"
    redirect_to login_login_path
  end

end
