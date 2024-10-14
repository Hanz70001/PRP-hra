# app/controllers/dashboard_controller.rb
# require 'dashboard_creation_helper'
# require 'general_data_link_helper'

class DashboardController < ApplicationController
  include DashboardCreationHelper
  helper_method :parametricposition
  helper_method :userverification
  include GeneralDataLinkHelper
  helper_method :maintools_generaldatalink


  def show
    # params page a context from url adress
    @page = params[:page] || '0'
    @context = params[:context] || '0'
    @test = params[:test] || '0'

    @user_ip = request.remote_ip
    @user_session = session.id.to_s

    # other code is in view
  end
end