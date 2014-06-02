class UsersController < ApplicationController

  before_filter :authorize
  before_action :set_user, only: [:edit,:update,:destroy, :reset_password]
   
  def index
    @users = User.find(session[:user_id]).organization.users
  end

  def new
    @user = User.new
    @organization = User.find(session[:user_id]).organization
  end
 
  def create
    @user = User.new(user_params)
    if @user.save
      flash[:notice] = "User created succesfully"
      redirect_to users_path
    else
       flash[:notice] = "Error creating users"
       @organization = User.find(session[:user_id]).organization
       render action: "new"
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:notice] = "User updated succesfully"
      redirect_to users_path
    else
      flash[:notice] = "Error updating  users"
      render action: "edit"
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path
  end

  def reset_password
  end

  protected

    def user_params
      params.require('user').permit(:organization_id, :username, :email, :first_name, :last_name, :dob, :password_confirmation, :password)
    end

    def set_user
      @user = User.find(params[:id])
    end

end
