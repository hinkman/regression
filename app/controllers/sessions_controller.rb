class SessionsController < ApplicationController
  skip_before_filter :require_login, :only => [:new, :create]

	def new
		redirect_to root_path if current_user
	end

	def create
		ldap_user = Adauth.authenticate(params[:username], params[:password])
		if ldap_user
        	user = User.return_and_create_from_adauth(ldap_user)
        	session[:user_id] = user.id
        	redirect_to root_path
    	else
        	redirect_to signin_path, :alert => "Invalid Login"
    	end
	end

	def destroy
		session[:user_id] = nil
		redirect_to signin_path
	end
end