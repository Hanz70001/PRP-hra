class AjaxController < ApplicationController
  protect_from_forgery with: :null_session

  include GeneralDataLinkHelper
  include DashboardCreationHelper
  helper_method :maintools_generaldatalink
  helper_method :gdltools_performfunction
  helper_method :createnewcontext

  def data_incoming
    begin
      # load data from json body
      # incomingdata = params[:_json] || params[:ajax][:_json]
      incomingdata = JSON.parse(request.body.read)

      url = incomingdata['url']
      datapacks = incomingdata['sendingdatapacks']

      # now get context id
      uri = URI.parse(url)
      context_param = Rack::Utils.parse_query(uri.query)["context"] || '0' # default context is 0

      triggeredupistoload = []
      triggeredupistosave = []
      triggeredredirs = []
      idtotriggerload = "-1" # -1 means no trigger
      idtotriggersave = "-1" # -1 means no trigger
      foundtag = 0

      # process data

      datapacks.each do |element_data|
        element_type = element_data['element_type'] || ''
        upi_trigger = element_data['upi_trigger'] || ''
        generaldatalink = element_data['generaldatalink'] || ''
        click_action = element_data['click_action'] || ''
        inherited_values = element_data['inherited_values'] || ''
        value = element_data['value'] || ''

        idtotriggerload = "-1" # -1 means no trigger
        idtotriggersave = "-1" # -1 means no trigger      

        case element_type
          when "4"
            maintools_generaldatalink("write", generaldatalink, value, inherited_values, context_param)
            idtotriggerload = upi_trigger
          when "5","7"
            click_action_splitted = click_action.split(";")
            click_action_splitted.each do |click_action_single|
              if click_action_single[0] == "#"
                click_action_single.slice!(0)
                maintools_generaldatalink("read", click_action_single, "", inherited_values, context_param)
              else
                case click_action_single
                  when "makewrite", "makesave", "causesave", "save"
                    idtotriggersave = upi_trigger
                  when "makeread", "makeload", "causeload", "load"
                    idtotriggerload = upi_trigger
                  when "login","register"
                    puts "login:" + value
                    loginvalues = value.split(";")
                    if click_action_single == "register"
                      existinguser = User.where(user_name: loginvalues[0]).pluck(:id)
                      if existinguser.nil? || existinguser.empty?
                        # no user, so create
                        newuserid = User.maximum(:id)
                        if newuserid.nil? then newuserid = 0 end
                        newuserid = newuserid + 1
              
                        recordrow = User.find_or_create_by(id: newuserid)

                        recordrow.update(user_name: loginvalues[0])
                        recordrow.update(user_validation: loginvalues[1])
              
                        newcontextid = createnewcontext(newuserid)
              
                        Player.create(contextid: newcontextid, cashbalance: "1000", maxdistance: "0", launchcount: "0")
                      end
                    end

                    # now continue to login
                    logginguser = User.where(user_name: loginvalues[0]).first
                    if logginguser.nil? 
                      # do nothing
                    else
                      if logginguser.user_validation == loginvalues[1]
                        recordrow = User.find_or_create_by(user_name: loginvalues[0])
                        recordrow.update(user_machineid: session.id.to_s)
                        triggeredredirs[0] = 8
                      end
                    end
                  # user project functions ----------------------------------------
                  when "toconstruction"
                    idtotriggerload = upi_trigger
 
                    inherited_values_splitted = inherited_values.split(";")

                    SatelliteTemplate.create(contextid: context_param, moduleid: inherited_values_splitted[0])
                  when "fromconstruction"
                    inherited_values_splitted = inherited_values.split(";")

                    puts "fromconstruction:" + inherited_values_splitted[2]

                    SatelliteTemplate.where(id: inherited_values_splitted[2]).delete_all

                    idtotriggerload = upi_trigger 
                  when "deleteconstruction"
                    SatelliteTemplate.where(contextid: context_param).delete_all

                    idtotriggerload = upi_trigger 
                  when "buildsatellite"
                    newsatellitename = gdltools_readfromcontext(context_param, "21").first

                    puts "budu stavet satelit:" + newsatellitename

                    # check name
                    samenamedsatellites = SatelliteList.where(satellitename: newsatellitename).pluck(:id).first
                    if samenamedsatellites.nil? 
                      puts "satelit bude postaven"

                      # check price
                      cashbalance = Player.where(contextid: context_param).pluck(:cashbalance).first.to_f
                      satelliteprice =  gdltools_performfunction("construction_price", "0", context_param).to_f

                      if satelliteprice > cashbalance
                        puts "nedostatek penez"
                        gdltools_writetocontext(context_param, "20", "Nedostatek peněz!")
                        idtotriggerload = upi_trigger 
                      else
                        # so, create our new satellite
                        puts "jde se stavet satelit"

                        # update cash balance
                        recordrow = Player.find_or_create_by(contextid: context_param)
                        recordrow.update(cashbalance: (cashbalance - satelliteprice).to_s)

                        # create satellite list
                        SatelliteList.create(contextid: context_param, satellitename: newsatellitename)

                        # now create satellite construction
                        satelliteweight =  gdltools_performfunction("construction_weight", "0", context_param).to_i
                        satelliteparts = SatelliteTemplate.where(contextid: context_param).pluck(:moduleid)
                        battery_maxcapacity = 0
                        maxhealth = 100
                        satelliteparts.each do |satellitepart|
                          satellitemodule = SatelliteModule.where(id: satellitepart).first

                          SatelliteConstruction.create(satellitename: newsatellitename, poweronstatus: "Zapnuto",
                            name: satellitemodule.name, image: satellitemodule.image, typeimage: satellitemodule.typeimage, label: satellitemodule.label, 
                            eletricity_prod: satellitemodule.eletricity_prod, eletricity_cons: satellitemodule.eletricity_cons,
                            fuel_maxcapacity: satellitemodule.fuel_maxcapacity, fuel_stateofcharge: satellitemodule.fuel_maxcapacity,
                            fuel_efectivity: satellitemodule.fuel_efectivity, fuel_constype: satellitemodule.fuel_constype,
                            engine_power: satellitemodule.engine_power, engine_cons: satellitemodule.engine_cons,
                            research_rate: satellitemodule.research_rate, research_consumption: satellitemodule.research_consumption,
                            shield_strenght: satellitemodule.shield_strenght, shield_cons: satellitemodule.shield_cons)

                          battery_maxcapacity = battery_maxcapacity + satellitemodule.battery_maxcapacity.to_i
                          maxhealth = maxhealth + satellitemodule.health_bonus.to_i
                        end #satelliteparts.each

                        # now satellite values, starting energy in joules
                        startingenergy = 100000000.0
                        startingspeed = Math.sqrt((2.0 * startingenergy) / satelliteweight.to_f)

                        SatelliteValue.create(satellitename: newsatellitename, image: "", status: "Aktivní", distance: "0",
                          totalweight: satelliteweight.to_s, speed: startingspeed, timeofstart: Time.now.to_i.to_s,
                          battery_maxcapacity: battery_maxcapacity.to_s, battery_stateofcharge: "0",
                          total_eleprod: "0", total_elecons: "0", total_shield: "0", total_resrate: "0", radar_cons: "0",
                          maxhealth: maxhealth.to_s, currenthealth: maxhealth.to_s,
                          danger_time: (Time.now.to_i - 1).to_s, danger_strenght: "0", danger_type: "none", lasttick_time: Time.now.to_i.to_s)

                        # our satellite has been created

                        # satellite tick
                        CyclicLoop.satelliteTick(newsatellitename, context_param)

                        # update status bar
                        gdltools_writetocontext(context_param, "20", "")                    

                        # trigger redir to page 4 and make new satellite current
                        gdltools_writetocontext(context_param, "22", newsatellitename)
                        idtotriggerload = upi_trigger 
                        triggeredredirs[0] = "4"
                      end # check price
                    else
                      puts "satelit s timto jmenem existuje"
                      gdltools_writetocontext(context_param, "20", "Satelit se stejným názvem již existuje!")
                      idtotriggerload = upi_trigger 
                    end # check name

                    # def gdltools_readfromcontext (contexid, rowid)
                    # def gdltools_writetocontext (contextid, rowid, value_to_write)
                  when "gamereset"
                    if gdltools_readfromcontext(context_param, "23").first == "musk"
                      puts "restart hernich dat"
                      SatelliteValue.delete_all
                      Player.delete_all
                      User.delete_all
                      MessageBox.delete_all
                      SatelliteList.delete_all
                      SatelliteTemplate.delete_all
                      SatelliteConstruction.delete_all
                      SatelliteValue.delete_all
                      ContextList.delete_all

                      MessageBox.create(contextid: "Voyager 1", message: "23300000000 Km")
                      MessageBox.create(contextid: "Voyager 2", message: "19900000000 Km")
                    else
                      puts "spatne heslo:" + gdltools_readfromcontext(context_param, "23").first + ";"
                    end
                  when "gamecheat"
                    if gdltools_readfromcontext(context_param, "23").first == "musk"
                      Player.update_all("cashbalance = cashbalance + 500")
                    end
                  else
                    if click_action_single.include?("redir:")
                      redir_splitted = click_action_single.split(":")
                      triggeredredirs[0] = redir_splitted[1]
                    end
                end # case click_action
              end
            end # click_action_splitted.each
        end # case element_type

        # now is something for trigger load?
        foundtag = 0
        if idtotriggerload != "-1"
          triggeredupistoload.each do |triggeredupitoload|
            if triggeredupitoload == idtotriggerload
              foundtag = 1
              break
            end
          end

          if foundtag == 0
            triggeredupistoload[triggeredupistoload.length] = idtotriggerload
          end
        end

        # now is something for trigger save
        foundtag = 0
        if idtotriggersave != "-1"
          triggeredupistosave.each do |triggeredupitosave|
            if triggeredupitosave == idtotriggersave
              foundtag = 1
              break
            end
          end

          if foundtag == 0
            triggeredupistosave[triggeredupistosave.length] = idtotriggersave
          end
        end

      end # datapacks.each do

      # all ok
      render json: { triggeredupistoload: triggeredupistoload, triggeredupistosave: triggeredupistosave, triggeredredirs: triggeredredirs }, status: :ok
    rescue JSON::ParserError
      # wrong incoming data 
      render json: { error: 'data error' }, status: :bad_request
    end
  end

  def query_incoming
    begin
      # load data from json body
      # incomingdata = params[:_json] || params[:ajax][:_json]
      incomingdata = JSON.parse(request.body.read)

      url = incomingdata['url']
      datapacks = incomingdata['sendingdatapacks']

      # now get context id
      uri = URI.parse(url)
      context_param = Rack::Utils.parse_query(uri.query)["context"] || '0' # default context is 0

      # Array to hold the results
      results = []

      # process data
      datapacks.each do |query_data|
        element_id = query_data['element_id'] || ''
        element_gdl = query_data['element_gdl'] || ''
        element_inhvalues = query_data['element_inhvalues'] || ''

        value_to_return = maintools_generaldatalink("read", element_gdl, "", element_inhvalues, context_param)

        results << { element_id: element_id, value: value_to_return }
      end

      # all ok
      render json: { answeredqueries: results }, status: :ok
    rescue JSON::ParserError
      # wrong incoming data 
      render json: { error: 'data error' }, status: :bad_request
    end
  end
end