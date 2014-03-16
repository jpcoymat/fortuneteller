class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected
    
    def authorize
      user_id = session[:user_id] || -1
      if User.where(id: user_id).first.nil?
        redirect_to login_login_path 
      end
    end

end
