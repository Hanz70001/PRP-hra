require 'securerandom'

module DashboardCreationHelper
  def parametricposition(positiontype, enteredpositionvalues, ancestorpositionvalues, previouspositionvalues, inheritedcyclicvalues)
    returnvalue = ""

    enteredvalues = enteredpositionvalues.split(";")
    ancestorvalues = ancestorpositionvalues.split(";")
    cyclicvalues = inheritedcyclicvalues.split(";")
    previousvalues = previouspositionvalues.split(";")

    case positiontype
      when "basic"
        returnvalue = (enteredvalues[0].to_i + ancestorvalues[0].to_i).to_s + ";" + (enteredvalues[1].to_i + ancestorvalues[1].to_i).to_s
        return returnvalue
      when "cumulative"
        returnvalue = (enteredvalues[0].to_i + ancestorvalues[0].to_i + enteredvalues[2].to_i * cyclicvalues[1].to_i).to_s + ";" + (enteredvalues[1].to_i + ancestorvalues[1].to_i + enteredvalues[3].to_i * cyclicvalues[1].to_i).to_s
        return returnvalue
      when "additive"
        # puts "additive:" + (enteredvalues[0].to_i + previousvalues[0].to_i).to_s + ";" + (enteredvalues[1].to_i + previousvalues[1].to_i).to_s
        returnvalue = (enteredvalues[0].to_i + previousvalues[0].to_i).to_s + ";" + (enteredvalues[1].to_i + previousvalues[1].to_i).to_s
        return returnvalue
    end # case positiontype
  end # parametricposition

  def userverification(user_ip, user_session, demanded_contextid)
    # this function return allowed context for user. If return -1, then no context is allowed
    # first we read server options
    verification_type = ServerOption.where(option_name: "verification_type").pluck(:option_value).first
    verification_type = verification_type.nil? ? "none" : verification_type

    case verification_type
      when "none"
        # pass demanded
        return demanded_contextid
      when "oneip_oneuser"
        user_id = User.where(user_machineid: user_ip).pluck(:id).first
        user_id = user_id.nil? ? "-1" : user_id

        if user_id == "-1"
          # now we create new contextid
          newuserid = User.maximum(:id)
          if newuserid.nil? then newuserid = 0 end
          newuserid = newuserid + 1

          recordrow = User.find_or_create_by(id: newuserid)
          recordrow.update(user_machineid: user_ip)

          newcontextid = createnewcontext(newuserid)

          recordrow = User.find_or_create_by(id: newuserid)
          recordrow.update(user_lastpresence: Time.current)

          return newcontextid
        else
          # this ip adress has active context

          # fill active time for user
          recordrow = User.find_or_create_by(id: user_id)
          recordrow.update(user_lastpresence: Time.current)

          user_contextid = User.where(id: user_id).pluck(:user_contextid).first

          return user_contextid
        end
      when "loginto_sessionid"
        pomusers = User.all
        pomusers.each do |pomuser|
          if pomuser.user_machineid == user_session
            return pomuser.user_contextid
          end
        end

        return "-1"
    end # case verification_type
  end

  def createnewcontext(user_id)
    # create new context into context list a connect to its user
    contextvalues = ContextList.pluck(:context_id)

    # look for first context name not present in context list
    new_value = nil
    loop do
      new_value = SecureRandom.alphanumeric(16)
      break unless contextvalues.include?(new_value)
    end

    ContextList.create(context_id: new_value, context_scopeoflife: "byuser")

    recordrow = User.find_or_create_by(id: user_id)
    recordrow.update(user_contextid: new_value)

    return new_value
  end
end