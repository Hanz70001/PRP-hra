class HomeController < ApplicationController
  def redirect_to_dashboard
    defaultpage = ServerOption.where(option_name: "defaultpage").pluck(:option_value).first
    defaultpage = defaultpage.nil? ? "0" : defaultpage

    redirect_to "/dashboard?page=" + defaultpage
  end
end