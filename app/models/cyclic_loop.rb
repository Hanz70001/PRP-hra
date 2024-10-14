class CyclicLoop
  def self.ContextDisposal
    # clearing of unused contexts
    loop do
      actual_time = Time.current

      # now set disposal time type
      contextdisposal_timetype = ServerOption.where(option_name: "contextdisposal_timetype").pluck(:option_value).first
      contextdisposal_timetype = contextdisposal_timetype.nil? ? "none" : contextdisposal_timetype

      case contextdisposal_timetype
        when "none"
          puts "no cycling loop"
          return # quit this cyclic loop
        when "midnight"
          # so, empty all tables: users, contextlist and context, baskets
          User.delete_all
          Context.delete_all
          ContextList.delete_all

          # and wait until next midnight
          sleep 120 # wait two minutes for case next formula returns zero time
          midnight = actual_time.end_of_day

          seconds_until_midnight = (midnight - actual_time).to_i
          sleep seconds_until_midnight
      end # case contextdisposal_timetype
    end
  end # self.ContextDisposal

  def self.gameTick
    loop do
      satellitelist = SatelliteList.all
      satellitelist.each do |satellite|
        satelliteTick(satellite.satellitename, satellite.contextid)
      end #satellitelist.each do |satellite|
      sleep 10
    end
  end

  def self.satelliteTick(satellitename, contextid, recursiveindicator = 0)
    # local variables
    local_i1 = 0

    # rates
    lowtimerate = 1 # one second equals to
    bigtimerate = 365 # one second equals to

    satellitevalues = SatelliteValue.where(satellitename: satellitename).first

    case satellitevalues.status
      when "Aktivní"
        # continue
      when "Zničený"
      when "Signál ztracen"
        # do not continue
        return
      when "Opuštěná "
        # save result       
        SatelliteValue.where(satellitename: satellitename).delete_all
        SatelliteConstruction.where(satellitename: satellitename).delete_all
        SatelliteList.where(satellitename: satellitename).delete_all
        # done here
        return
    end # case satellitevalues.status

    # time in seconds
    timefromlasttick = Time.now.to_i - satellitevalues.lasttick_time.to_i

    # now compute all actual values
    electricity_production = 0
    electricity_consumption = 0
    research_ratebonus = 10 # money per 100 000 km
    shield_strenght = 0
    engine_power = 0
    radar_consumption = 200 

    satelliteparts = SatelliteConstruction.where(satellitename: satellitename)
    satelliteparts.each do |satellitepart|
      if satellitepart.poweronstatus == "Zapnuto" || satellitepart.poweronstatus == "Zapnuto "
        # electricity production is determined by fuel_constype
        # fueltype electricity production
        case satellitepart.fuel_constype
          when "none"
            # so nothing
          when "solar"
            # decreases by more distance. 100% production is at begining, decreasing. 1AU = 100%; 2AU = 50%
            electricity_production = electricity_production + (satellitepart.eletricity_prod.to_f * (150000.0 / (satellitevalues.distance.to_f + 150000.0))).to_i
            satellitepart.fuel_efectivity = format('%.1f', (150000.0 / (satellitevalues.distance.to_f + 150000.0) * 100.0))
          when "static"
            # all time same constumption
            local_i1 = satelliteparts.fuel_stateofcharge.to_i - (timefromlasttick * lowtimerate)
            if local_i1 > 0
              electricity_production = electricity_production + satellitepart.eletricity_prod.to_i
              satellitepart.fuel_efectivity = "100"
              satellitepart.fuel_stateofcharge = local_i1.to_s
            else
              satellitepart.fuel_efectivity = "0"
              satellitepart.fuel_stateofcharge = "0"
              satellitepart.poweronstatus == "Vypnuto"
            end
          when "decreasing"
            local_i1 = satellitepart.fuel_stateofcharge.to_i - (timefromlasttick * lowtimerate)
            if local_i1 > 0
              electricity_production = electricity_production + (satellitepart.eletricity_prod.to_f * (local_i1.to_f / satellitepart.fuel_maxcapacity.to_f)).to_i
              satellitepart.fuel_efectivity = format('%.1f', (local_i1.to_f / satellitepart.fuel_maxcapacity.to_f * 100.0))
              satellitepart.fuel_stateofcharge = local_i1.to_s
            else
              satellitepart.fuel_efectivity = "0"
              satellitepart.fuel_stateofcharge = "0"
              satellitepart.poweronstatus == "Vypnuto"
            end
        end #case satellitepart.fuel_constype

        recordrow2 = SatelliteConstruction.find_or_create_by(id: satellitepart.id)
        recordrow2.update(fuel_efectivity: satellitepart.fuel_efectivity)

        # electricity consumption
        electricity_consumption = electricity_consumption + satellitepart.eletricity_cons.to_i

        # other values
        research_ratebonus = research_ratebonus + satellitepart.research_rate.to_i
        shield_strenght = shield_strenght + satellitepart.shield_strenght.to_i
        engine_power = engine_power + satellitepart.engine_power.to_i
        radar_consumption = radar_consumption + satellitepart.research_consumption.to_i
      end
    end # satelliteparts.each do |satellitepart|

    # maximum bonus for radar consumption is 75%
    if radar_consumption < 50 then radar_consumption = 50 end
    electricity_consumption = electricity_consumption + radar_consumption

    # save founded values
    recordrow = SatelliteValue.find_or_create_by(satellitename: satellitename)
    recordrow.update(total_eleprod: electricity_production.to_s)
    recordrow.update(total_elecons: electricity_consumption.to_s)
    recordrow.update(total_resrate: research_ratebonus.to_s)
    recordrow.update(total_shield: shield_strenght.to_s)

    # if recursiveindicator id higher than 0 it means we need only check values
    if recursiveindicator > 0 then return end

    # now check energy, whether we will use baterries?
    if electricity_consumption > electricity_production
      energydemand = (electricity_consumption - electricity_production) * lowtimerate * timefromlasttick
      batteryenergy = satellitevalues.battery_stateofcharge.to_i - energydemand
      if batteryenergy > 0
        # we have power in baterry
        electricity_production = electricity_consumption
        recordrow.update(battery_stateofcharge: batteryenergy.to_s)
      end
    end

    # now check if there is enought eletricity
    if electricity_consumption > electricity_production
      # and its first iteration, so we try to turn on every energy sources
      satelliteparts.each do |satellitepart|
        if satellitepart.fuel_constype != "none"
          recordrow2 = SatelliteConstruction.find_or_create_by(id: satellitepart.id)
          recordrow2.update(poweronstatus: "Zapnuto")
        end
      end # satelliteparts.each do |satellitepart|

      # and then compute again
      satelliteTick(satellitename, contextid, 1)

      satellitevalues = SatelliteValue.where(satellitename: satellitename).first
      electricity_production = satellitevalues.total_eleprod.to_i
      electricity_consumption = satellitevalues.total_elecons.to_i
    end

    # now have we enough energy?
    if electricity_consumption > electricity_production
      recordrow.update(status: "Signál ztracen")
      recordrow.update(total_eleprod: "0")
      recordrow.update(total_elecons: "0")
      recordrow.update(speed: "0")    
      return  
    end

    # we have enough energy, we can continue
    # moreover energy will be stored into baterries
    if electricity_production > electricity_consumption  
      energytostore = (electricity_production - electricity_consumption) * lowtimerate * timefromlasttick
      batteryenergy = satellitevalues.battery_stateofcharge.to_i + energytostore
      if batteryenergy > satellitevalues.battery_maxcapacity.to_i
        batteryenergy = satellitevalues.battery_maxcapacity.to_i
      end
      recordrow.update(battery_stateofcharge: batteryenergy.to_s)
    end

    # okay, we have done all electricity and modules
    # now speed and distance
    deltaspeed = (engine_power.to_f / satellitevalues.totalweight.to_f) * lowtimerate.to_f * timefromlasttick.to_f
    # is in m/s addition from last tick
    newspeed = satellitevalues.speed.to_f + deltaspeed
    recordrow.update(speed: newspeed.to_s)

    # now compute distance, which is in thousand kilometers
    newdistance = satellitevalues.distance.to_f + (newspeed / 1000000.0 * bigtimerate.to_f)
    distancechange = newdistance - satellitevalues.distance.to_f
    recordrow.update(distance: newdistance)

    # money income
    moneyincome = distancechange * satellitevalues.total_resrate.to_f / 100.0
    cashbalance = Player.where(contextid: contextid).pluck(:cashbalance).first.to_f
    recordrow2 = Player.find_or_create_by(contextid: contextid)
    recordrow2.update(cashbalance: (cashbalance + moneyincome).to_s)

    # now event handling
    if Time.now.to_i > satellitevalues.danger_time.to_i
      danger_damage = satellitevalues.danger_strenght.to_i - shield_strenght
      if danger_damage < 0 then danger_damage = 0 end
      newhealth = satellitevalues.currenthealth.to_i - danger_damage
      if newhealth < 0 then newhealth = 0 end
      recordrow.update(currenthealth: newhealth.to_s)
      if newhealth < 1
        recordrow.update(status: "Zničený")
        recordrow.update(total_eleprod: "0")
        recordrow.update(total_elecons: "0")
        recordrow.update(speed: "0")    
      return  
      end

      # new event
      danger_newtime = Time.now.to_i + (10800 + (rand(180) * 60)) / lowtimerate
      danger_strength = (newdistance / 1000000.0 * 10.0 + rand(20)).to_i
      recordrow.update(danger_time: danger_newtime.to_s)
      recordrow.update(danger_strenght: danger_strength.to_s)
    end

    # statistics
    recordrow2 = MessageBox.find_or_create_by(contextid: satellitename)
    recordrow2.update(message: satellitevalues.distance.to_i.to_s + "000 Km")

    # and finnaly, update lasttick_time
    recordrow.update(lasttick_time: Time.now.to_i.to_s)

    # and all done
  end
end