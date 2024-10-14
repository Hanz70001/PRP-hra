module GeneralDataLinkHelper
  # here are declared main functions for dashboard creation

  # first important block of functions are functions for general data link --------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------------------------------------------------------------------------
  # while reading return value is array of values collected with formula. there can be more formulas splited by ; symbol
  # while writing, value_to_write is written to every formula. So there can be multiple writes. If formula is pointing to field of data, write is done everywhere
  # 1) first of all, formula contains "expressions to process" marked between $ symbols, which are processed first
  #   result of parsing this expression is some value. In this expression inheritedvalues are used
  #   also inherited values are in this step loaded and replaced by value
  # 2) in second step, formula is splitten to its parts divided by ; mark
  #   every this part is processed to its primitive state which is database reference or raw value
  #   while reading, database reference is rereferenced to value(s). while writing, value is written to address, represented by database reference
  #
  # now explanation of behavior of tool functions and other parts:
  #
  # inheritedvalues:
  #   there are six inherited variables, which are provided
  #   three parental variables and three cyclic variables: p1; p2; p3; c1; c2; c3; oX
  #   parental are reference ids of page, panel and element
  #   cyclic values are provided by cycling this way: if on page panel reference is cyclic, internal cycle id is provided to c1. c2 and c3 variables are provided by panel reference for element
  #   value of variables is determined by cycling type
  #   other variables oX (where X is index) are optional and are provided by cycling type
  #   while some variable is needed and not provided, its value is determined as zero
  #   "u" variable is for contextid
  #
  # formula functions:
  #   database functions:
  #     dbref (tablename, identifier, columnname) - process these 3 values into database reference
  #     readctxt (identifier) - same as db reading, amend tablename as t_context and select default column
  #     writectxt (identifier, valuetowrite) - same as db reading, amend tablename as t_context and select default column
  #     readdb (databasereference) - read values from db
  #     writedb (databasereference, valuetowrite) - write values to db
  #   contiditonal and aritmetic functions:
  #     if (condition, valueontrue, valueonfalse) - returns corresponding value
  #     aritmetic (leftvalue, sing, rightvalue) - returns value
  #
  # database reference
  #   example: "@t_elements, 1, posx"
  #   first parameter is table name
  #   second parameter is key found in identification row
  #   third parameter is in which column is required value
  #   if database reference is for context table, then contexid isn required in reference and is suplemented in function tree

  # Main function for reading or writing data based on a formula. ----------------------------------------
  def maintools_generaldatalink(action, formula, value_to_write, inheritedvalues, contextid)
    # local store of variables
    localformula = formula

    # Step 1: Parse the formula expressions and replaces them by values -----
    localformula = gdltools_parseexpression(localformula, inheritedvalues, contextid)
    
    # now expressions are replaced by values

    # here is declaration of returning value
    returningvalue = []
    localreturningvalue = []

    # Step 2: now we process all formula parts --------
    
    formulaparts = localformula.split(";")
    formulaparts.each_with_index do |formulapart, index|
      # now parse formula to its primitive state
      formulaparts[index] = gdltools_parseformula(formulapart, contextid)

      # now action
      if (action == "read")
        if (gdltools_isdatabasereference(formulaparts[index]) == true)
          localreturningvalue = gdltools_readfromdb(formulaparts[index], contextid)
        else
          localreturningvalue[0] = formulaparts[index]
        end

        # now save into result  
        for i in 0...localreturningvalue.length 
          returningvalue[returningvalue.length] = localreturningvalue[i]
        end
      else
        # write action

        if (gdltools_isdatabasereference(formulaparts[index]) == true)
          localreturningvalue = gdltools_writetodb(formulaparts[index], value_to_write, contextid)
        else
          # do nothing
        end
      end # if action
    end # formulaparts.each

    # everything should be done, so return collected value (also for write action, but shouldnt be used)
    return returningvalue.flatten
  end

  # now helping functions -------------------------------------------
  # This function processes and evaluates expressions marked with $
  def gdltools_parseexpression(formula, inheritedvalues, contextid)
    # now select $ expressions
    selectmode = 0

    startingformula = formula
    finalformula = []
    localformula = []
    startposition = -1
    finallength = 0

    for i in 0...startingformula.length
      if (startingformula[i] == "$")
        if (selectmode == 0)
          startposition = i
          localformula = []
          selectmode = 1
        else
          localformula = gdltools_parseexpressionpart(localformula, inheritedvalues, contextid).to_s
          selectmode = 0
          for j in 0...localformula.length
            finalformula[finallength] = localformula[j]
            finallength = finallength + 1
          end
        end
      else
        if (selectmode == 1)
          localformula[i - startposition - 1] = startingformula[i]
        else
          finalformula[finallength] = startingformula[i]
          finallength = finallength + 1
        end
      end # if symbol $
    end # for i

    return finalformula.join("")
  end

  # parse exresion between $$
  def gdltools_parseexpressionpart(formulapart, inheritedvalues, contextid)
    # first of all, this split formula into parts

    inheritedvaluessplited = inheritedvalues.split(";")

    currentpart = 0
    mode = 0
    localvariable = []

    dividedparts = []
    signafterpart = []

    for i in 0...formulapart.length
      if mode == 0
        case formulapart[i]
          when " "
            # do nothing 
          when "p", "c", "o"
            mode = 1
          when "\""
            mode = 2
            localvariable = []
          when "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"
            mode = 3
            localvariable = []
            localvariable[0] = formulapart[i]
          when "+", "-", "*", "/", "=", "&", "|", "%", "!", ">", "<"
            mode = 5
          when "u"
            dividedparts[currentpart] = contextid.to_s

            currentpart = currentpart + 1
        end
      else    
        case mode
          when 1
            localvariable = formulapart[i].to_i
            if formulapart[i - 1] == "c"
              localvariable = localvariable + 3
            end
            if formulapart[i - 1] == "o"
              localvariable = localvariable + 6
            end

            if localvariable >= inheritedvaluessplited.length
              dividedparts[currentpart] = 0
            else
              dividedparts[currentpart] = inheritedvaluessplited[localvariable]
            end

            currentpart = currentpart + 1
            mode = 0
          when 2
            if formulapart[i] == "\""
              dividedparts[currentpart] = localvariable
              currentpart = currentpart + 1
              mode = 0
            else
              localvariable[localvariable.length] = formulapart[i]
            end
          when 3, 4
            if formulapart[i] == "1" || formulapart[i] == "2" || formulapart[i] == "3" || formulapart[i] == "4" || formulapart[i] == "5" ||
              formulapart[i] == "6" || formulapart[i] == "7" || formulapart[i] == "8" || formulapart[i] == "9" || formulapart[i] == "0"

              localvariable[localvariable.length] = formulapart[i]
            else
              if formulapart[i] == "."
                localvariable[localvariable.length] = formulapart[i]
                mode = 4
              else
                if mode == 3
                  dividedparts[currentpart]  = localvariable.to_i
                else
                  dividedparts[currentpart] = localvariable.to_f
                end
                currentpart = currentpart + 1
                mode = 0
              end
            end
          when 5
            if formulapart[i - 1] == "-"
              if formulapart[i] == "1" || formulapart[i] == "2" || formulapart[i] == "3" || formulapart[i] == "4" || formulapart[i] == "5" ||
                formulapart[i] == "6" || formulapart[i] == "7" || formulapart[i] == "8" || formulapart[i] == "9" || formulapart[i] == "0"

                mode = 3
                localvariable = []
                localvariable[0] = formulapart[i - 1]
                localvariable[1] = formulapart[i]
              else
                signafterpart[currentpart] = "-"
                mode = 0
              end
            else
              signafterpart[currentpart] = formulapart[i - 1]
              if formulapart[i] == " "
              else
                signafterpart[currentpart] = signafterpart[currentpart] + formulapart[i]
              end
              mode = 0
            end
        end # case mode
      end # if mode == 0
    end # for i

    # now parts are splitted and analysed with their sign, inherited values are replaced by value
    finalvalue = dividedparts[0]

    for i in 1...dividedparts.length
      case signafterpart[i - 1]
        # aritmetic
        when "+"
          finalvalue = finalvalue + dividedparts[i]
        when "-"
          finalvalue = finalvalue - dividedparts[i]
        when "*"
          finalvalue = finalvalue * dividedparts[i]
        when "/"
          finalvalue = finalvalue / dividedparts[i]
        when "%"
          finalvalue = finalvalue % dividedparts[i]
        # logic
        when "=="
          if finalvalue == dividedparts[i]
            finalvalue = true
          else
            finalvalue = false
          end
        when "!="
          if finalvalue != dividedparts[i]
            finalvalue = true
          else
            finalvalue = false
          end
        when ">"
          if finalvalue > dividedparts[i]
            finalvalue = true
          else
            finalvalue = false
          end
        when "<"
          if finalvalue < dividedparts[i]
            finalvalue = true
          else
            finalvalue = false
          end
        when ">="
          if finalvalue >= dividedparts[i]
            finalvalue = true
          else
            finalvalue = false
          end
        when "<="
          if finalvalue <= dividedparts[i]
            finalvalue = true
          else
            finalvalue = false
          end
        when "||"
          if finalvalue || dividedparts[i] == true
            finalvalue = true
          else
            finalvalue = false
          end
        when "&&"
          if finalvalue && dividedparts[i] == true
            finalvalue = true
          else
            finalvalue = false
          end
      end # case sign
    end # for i

    # everything is done, so return final value
    return finalvalue
  end

  # this function makes formula to its atomic state by processing it, returning simplified formula
  # this function can be recursive called
  def gdltools_parseformula(formula, contextid)
    formulatoreturn = formula

    functionname = ""
    functionparams = ""
    actualparam = ""

    mode = 0
    bracketlevel = 0

    # first of all, fucntion look if formula is function

    if formulatoreturn.include?("(")
      # process as function
      
      for i in 0...formulatoreturn.length
        if mode == 0
          if formulatoreturn[i] == "("
            mode = 1
            bracketlevel = 1
            actualparam = []
          else
            functionname[functionname.length] = formulatoreturn[i]
          end
        else
          # now we are processing parameters

          # counting bracket level

          case formulatoreturn[i]
            when "("
              bracketlevel = bracketlevel + 1
            when ")"
              bracketlevel = bracketlevel - 1
          end

          if bracketlevel == 0 || (formulatoreturn[i] == "," && bracketlevel == 1)
            # parameter separator

            #is function?
            if actualparam.include?("(")
              # so recursive process
              actualparam = gdltools_parseformula(actualparam, contextid)
              if actualparam.nil?
                actualparam = ""
              end
            end

            # copy actual parameter to params
            if actualparam.is_a?(Integer)
              actualparam = actualparam.to_s
            end

            for j in 0...actualparam.length
              functionparams[functionparams.length] = actualparam[j]
            end # for j

            functionparams[functionparams.length] = ";"

            # empty actual param
            actualparam = ""
          else
            actualparam[actualparam.length] = formulatoreturn[i].to_s
          end
        end # if mode
      end # for i

      # delete last ; in parameters
      if functionparams.length > 0
        functionparams[functionparams.length - 1] = " "
      end

      # perform funciton
      formulatoreturn = gdltools_performfunction(functionname, functionparams, contextid)

      return formulatoreturn
    else
      # its only value
      return formulatoreturn
    end 
    # returns above
  end

  # run functions in general data link, returns its result
  def gdltools_performfunction(functionname, functionparams, contextid)
    returnvalue = ""

    splittedparams = functionparams.split(";")

    case functionname.strip
      when "dbref"
        returnvalue = "@" + splittedparams[0].strip.gsub(/\A"|"\z/, '') + ", " + splittedparams[1].strip.gsub(/\A"|"\z/, '') + ", " + splittedparams[2].strip.gsub(/\A"|"\z/, '') + ""
        return returnvalue
      when "readctxt"  
        returnvalue = gdltools_readfromcontext(contextid, splittedparams[0])
        return returnvalue[0]
      when "writectxt"  
        gdltools_writetocontext(contextid, splittedparams[0], splittedparams[1])
        return returnvalue
      when "readdb"  
        returnvalue = gdltools_readfromdb(splittedparams[0], contextid)
        return returnvalue[0]
      when "writedb"  
        gdltools_writetodb(splittedparams[0], splittedparams[1], contextid)
        return returnvalue
      when "deldbrecord"
        case splittedparams[0].gsub('"', '')
          when "t_elements"
            Element.where(id: splittedparams[1]).delete_all
          when "t_panels"
            Panel.where(id: splittedparams[1]).delete_all
          when "t_pages"
            Page.where(id: splittedparams[1]).delete_all
          when "t_contexts"
            Context.where(id: splittedparams[1]).delete_all
          when "t_context_lists"
            ContextList.where(id: splittedparams[1]).delete_all
          when "t_context_templates"
            ContextTemplate.where(id: splittedparams[1]).delete_all
          when "t_users"
            User.where(id: splittedparams[1]).delete_all
          when "t_serveroptions"
            ServerOption.where(id: splittedparams[1]).delete_all
          when "t_possiblevalues"
            PossibleValue.where(id: splittedparams[1]).delete_all
        end # case splittedparams[0]
      when "dbcutout"
        # params: table, matching row, matching value, required rowo
        table_name = splittedparams[0].gsub('"', '').gsub(' ', '')
        matching_row = (splittedparams[1].strip.gsub('"', '')).to_sym # convert to symbol
        matching_value = splittedparams[2].gsub('"', '').gsub(' ', '')
        required_row = (splittedparams[3].strip.gsub('"', '')).to_sym # convert to symbol
        case table_name
          when "t_modules"
            results = SatelliteModule.pluck(required_row)   
          when "t_satellite_template"  
            results = SatelliteTemplate.where(contextid: contextid).pluck(required_row)  
          when "t_satellite_list"  
            results = SatelliteList.where(contextid: contextid).pluck(required_row)  
          when "t_satellite_construction" 
            results = SatelliteConstruction.where(satellitename: matching_value).pluck(required_row)   
          when "t_messagebox"
            results = MessageBox.order(Arel.sql("CAST(SUBSTRING(message, 1, LENGTH(message)-4) AS INTEGER) DESC")).limit(10).pluck(:id)    
        end # case table_name
        results = results.nil? ? [] : results
        results = results.empty? ? [] : results
        return results
      when "inconstruction"
        results = SatelliteTemplate.where(contextid: contextid, moduleid: splittedparams[0].gsub('"', '').gsub(' ', '')).pluck(:id)
        if results.empty?
          return "0"
        else
          return results.length.to_s
        end
      when "construction_price"
        results = SatelliteTemplate.where(contextid: contextid).pluck(:moduleid)  
        results = results.nil? ? [] : results
        results = results.empty? ? [] : results
        totalprice = 0
        results.each do |result|
          totalprice =  totalprice + SatelliteModule.where(id: result).pluck(:price).first.to_i
        end
        return totalprice.to_s
      when "construction_weight"
        results = SatelliteTemplate.where(contextid: contextid).pluck(:moduleid)  
        results = results.nil? ? [] : results
        results = results.empty? ? [] : results
        totalweight = 295
        results.each do |result|
          totalweight =  totalweight + SatelliteModule.where(id: result).pluck(:weight).first.to_i
        end
        if totalweight < 195 then totalweight = 195 end
        return totalweight.to_s
      when "satellitecount"
        results = SatelliteList.where(contextid: contextid)
        results = results.nil? ? [] : results
        results = results.empty? ? [] : results
        return results.length.to_s
      when "timeuntil"
        remainingseconds = splittedparams[0].to_i - Time.now.to_i
        hours = remainingseconds / 3600
        minutes = (remainingseconds % 3600) / 60
        remainingtime = format("%02dh:%02dm", hours, minutes)
        return remainingtime
      when "ifnottext"
        if splittedparams[0].gsub(' ', '') == splittedparams[1].gsub(' ', '')
          return "false"
        else
          return "true"
        end
      when "if"  
        if splittedparams[0] == true
          returnvalue = splittedparams[1]
        else
          returnvalue = splittedparams[2]
        end
        return returnvalue
      when "addtext"
        returnvalue = splittedparams[0].gsub('"', '').to_s + splittedparams[1].gsub('"', '').to_s
        return returnvalue
      when "aritmetic"
        splittedparams[0] = splittedparams[0].gsub('"', '').to_i
        splittedparams[2] = splittedparams[2].gsub('"', '').to_i
        case splittedparams[1].gsub('"', '')
          # aritmetic
          when "+"
            returnvalue = splittedparams[0] + splittedparams[2]
          when "-"
            returnvalue = splittedparams[0] - splittedparams[2]
          when "*"
            returnvalue = splittedparams[0] * splittedparams[2]
          when "/"
            returnvalue = splittedparams[0] / splittedparams[2]
          when "%"
            returnvalue = splittedparams[0] % splittedparams[2]
          # logic
          when "=="
            if splittedparams[0] == splittedparams[2]
              returnvalue = true
            else
              returnvalue = false
            end
          when "!="
            if splittedparams[0] != splittedparams[2]
              returnvalue = true
            else
              returnvalue = false
            end
          when ">"
            if splittedparams[0] > splittedparams[2]
              returnvalue = true
            else
              returnvalue = false
            end
          when "<"
            if splittedparams[0] < splittedparams[2]
              returnvalue = true
            else
              returnvalue = false
            end
          when ">="
            if splittedparams[0] >= splittedparams[2]
              returnvalue = true
            else
              returnvalue = false
            end
          when "<="
            if splittedparams[0] <= splittedparams[2]
              returnvalue = true
            else
              returnvalue = false
            end
          when "||"
            if splittedparams[0] || splittedparams[2] == true
              returnvalue = true
            else
              returnvalue = false
            end
          when "&&"
            if splittedparams[0] && splittedparams[2] == true
              returnvalue = true
            else
              returnvalue = false
            end
        end # case sign 
        return returnvalue
      when "maxdbid"
        case splittedparams[0].gsub('"', '').gsub(' ', '')
          when "t_elements"
            returnvalue = Element.maximum(:id)
            if returnvalue.nil?
              returnvalue = "0"
            end
          when "t_panels"
            returnvalue = Panel.maximum(:id)
            if returnvalue.nil?
              returnvalue = "0"
            end
          when "t_pages"
            returnvalue = Page.maximum(:id)
            if returnvalue.nil?
              returnvalue = "0"
            end
          when "t_contexts"
            returnvalue = Context.maximum(:id)
            if returnvalue.nil?
              returnvalue = "0"
            end
          when "t_context_lists"
            returnvalue = ContextList.maximum(:id)
            if returnvalue.nil?
              returnvalue = "0"
            end
          when "t_context_templates"
            returnvalue = ContextTemplate.maximum(:id)
            if returnvalue.nil?
              returnvalue = "0"
            end
          when "t_users"
            returnvalue = User.maximum(:id)
            if returnvalue.nil?
              returnvalue = "0"
            end
          when "t_serveroptions"
            returnvalue = ServerOption.maximum(:id)
            if returnvalue.nil?
              returnvalue = "0"
            end
          when "t_possiblevalues"
            returnvalue = PossibleValue.maximum(:id)
            if returnvalue.nil?
              returnvalue = "0"
            end
          when "t_modules"
            returnvalue = SatelliteModule.maximum(:id)
            if returnvalue.nil?
              returnvalue = "0"
            end
        end # splittedparams[0]
        return returnvalue
      when "decimalplaces3"
        unformatted_number = splittedparams[0].to_f
        formatted_number = format('%.3f', unformatted_number)
        return formatted_number
      when "decimalplaces0"
        return splittedparams[0].to_i.to_s
      when "tomegaunit"
        unformatted_number = splittedparams[0].to_f / 1000000.0
        formatted_number = format('%.1f', unformatted_number)
        return formatted_number
    end # case functionname

    # if no function found, returns blank
    return returnvalue
  end

  # database reference is text starting by @ and having 3 values, this function returns boolean value
  def gdltools_isdatabasereference(controledtext)
    if controledtext.nil?
      return false
    end

    if controledtext[0] == "@"
      testvariable = controledtext.split(",")
      if testvariable.length == 3
        return true
      else
        return false
      end
    else
      return false
    end
  end

  # this function read from db specified by database reference
  def gdltools_readfromdb(databasereferenceformula, contextid)
    return gdltools_actionwithdb(databasereferenceformula, "read", 0, contextid)
  end

  # this function writes to db specified by database reference
  def gdltools_writetodb(databasereferenceformula, value_to_write, contextid)
    return gdltools_actionwithdb(databasereferenceformula, "write", value_to_write, contextid)
  end

  def gdltools_actionwithdb(databasereferenceformula, action, value_to_write, contextid)
    entryparameters = databasereferenceformula.split(",")

    table_name = entryparameters[0][1..-1]
    search_param = entryparameters[1].gsub(' ', '')
    column_name = (entryparameters[2].strip.gsub('"', '')).to_sym # convert to symbol

    results = []

    case table_name
      when "t_elements", "elements", "ele"
        if action == "read"
          results = Element.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = Element.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      when "t_panels", "panels"
        if action == "read"
          results = Panel.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = Panel.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      when "t_panels_bypid"
        if action == "read"
          results = Panel.where(panel_id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = Panel.find_or_create_by(panel_id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      when "t_pages", "pages"
        if action == "read"
          results = Page.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = Page.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end    
      when "t_pages_bypid"
        if action == "read"
          results = Page.where(page_id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = Page.find_or_create_by(page_id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end   
      when "t_users", "users"
        if action == "read"
          results = User.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = User.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end    
      when "t_users_byname"
        if action == "read"
          results = User.where(user_name: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = User.find_or_create_by(user_name: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end  
      when "t_context_list", "t_context_lists", "contextlist"
        if action == "read"
          results = ContextList.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = ContextList.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end      
      when "t_serveroptions", "serveroptions"
        if action == "read"
          results = ServerOption.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = ServerOption.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      when "t_possiblevalues", "possiblevalues", "pvalues"
        if action == "read"
          results = PossibleValue.where(group_name: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = PossibleValue.find_or_create_by(group_name: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end      
      when "t_possiblevalues_byid"
        if action == "read"
          results = PossibleValue.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = PossibleValue.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end     
      when "t_context_template", "t_context_templates"
        if action == "read"
          results = ContextTemplate.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = ContextTemplate.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      when "t_context", "context", "contexts", "t_contexts"
        if action == "read"
          results = Context.where(context_id: contextid.to_s, row_id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          # gdltools_writetocontext(contextid, search_param, value_to_write) 
          recordrow = Context.find_or_create_by(context_id: contextid.to_s, row_id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      # user project data links -------------------------------------------------------------------------------
      when "t_modules"
        if action == "read"
          results = SatelliteModule.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = SatelliteModule.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      when "t_satellite_values"
        if action == "read"
          results = SatelliteValue.where(satellitename: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = SatelliteValue.find_or_create_by(satellitename: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      when "t_satellite_construction"
        if action == "read"
          results = SatelliteConstruction.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = SatelliteConstruction.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      when "t_players"
        if action == "read"
          results = Player.where(contextid: contextid).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = Player.find_or_create_by(contextid: contextid)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      when "t_messagebox"
        if action == "read"
          results = MessageBox.where(id: search_param).pluck(column_name)
          results = results.empty? ? "#" : results
        else
          recordrow = MessageBox.find_or_create_by(id: search_param)
          recordrow.update(column_name => value_to_write)
          return value_to_write
        end
      # -------------------------------------------------------------------------------------------------------
      else 
        results[0] = "unknown table: " + table_name
        return results     
    end # case entryparameters[0]

    if results.nil?
      results = []
      results[0] = "db read error"
    end

    return results
  end

  # this function read from context
  def gdltools_readfromcontext (contexid, rowid)
    results = Context.where(context_id: contexid, row_id: rowid).pluck(:row_value)
    results = results.nil? ? "#" : results
    return results
  end
 
  # this function writes context
  def gdltools_writetocontext (contextid, rowid, value_to_write)
    recordrow = Context.find_or_create_by(context_id: contextid, row_id: rowid)
    recordrow.update(row_value: value_to_write)
    return value_to_write
  end
end