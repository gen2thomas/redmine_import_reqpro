module UsersHelper
  
  def collect_rpusers(some_projects, conflate_users, loglevel)
    users = collect_users_fast(some_projects, conflate_users, loglevel)
    return users
  end
  
  # remap prefixes to key: ":conf_key"
  def remap_users_to_conflationkey(users)
    remaped_users = nil
    if users != nil
      remaped_users = Hash.new
      users.each_pair do |usr_key,usr_type|
        hash_key = usr_type[:conf_key]
        if remaped_users[hash_key] == nil # not existand
          remaped_users[hash_key] = Hash.new
          remaped_users[hash_key][:projects] = Array.new
          remaped_users[hash_key][:emails] = Array.new
          remaped_users[hash_key][:logins] = Array.new
          remaped_users[hash_key][:names] = Array.new
          remaped_users[hash_key][:groups] = Array.new
        end
        remaped_users[hash_key][:emails].push(usr_type[:email])
        remaped_users[hash_key][:emails].uniq!
        remaped_users[hash_key][:emails].sort!
        remaped_users[hash_key][:logins].push(usr_type[:login])
        remaped_users[hash_key][:logins].uniq!
        remaped_users[hash_key][:logins].sort!
        remaped_users[hash_key][:projects].push(usr_type[:project])
        remaped_users[hash_key][:projects].uniq!
        remaped_users[hash_key][:projects].sort!
        remaped_users[hash_key][:names].push(usr_type[:firstname] + " " + usr_type[:lastname])
        remaped_users[hash_key][:names].uniq!
        remaped_users[hash_key][:names].sort!
        remaped_users[hash_key][:groups].push(usr_type[:group])
        remaped_users[hash_key][:groups].uniq!
        remaped_users[hash_key][:groups].sort!
      end
    end
    return remaped_users
  end
    
  #call after manual mapping in view
  # use array of rmusers
  # delete not mapped (means not used) rpusers from hash
  # add mapping target (:rmuser) if needed
  def update_rpusers_for_map_needing(rpusers, rmusers, user_mapping, loglevel)
    if rpusers != nil
      rpusers.each do |rpuser_id, rpuser_value|
        rmuser_key = user_mapping[rpuser_value[:conf_key]]
        if  rmuser_key != "" and rmuser_key != nil  
          # search for and include rmuser as mapping
          idx = rmusers[:key_for_view].index(rmuser_key)
          if idx != nil
            #add existing user        
            rpuser_value[:rmuser] = rmusers[:rmusers][idx]
          else
            puts "New user for import found: " + rpuser_value[:email] if loglevel > 10
          end
        else
          # delete unused rpuser
          rpusers.delete(rpuser_id)
        end
      end
    end
    return rpusers
  end  
  
  # try to extract firstname and lastname from given 
  # longest string of "fullname", "email.part1", "login" 
  # the two shorter strings can help to extraxt
  def get_fullname(fullname_old, email, login)
    #remove trailing and leading whitespaces and split mail
    longest = fullname_old.strip
    if login!=nil and login!=""
      short1 = login.strip
    else
      short1=""
    end
    if email!=nil and email!=""
      email.strip!
      emailsplit = email.split(/[@]/) # ["firstname.lastname","gmx.de"]
      short2 = emailsplit[0]
      short3 = emailsplit[1].split(/[.]/)[0] if emailsplit[1]!=nil # ["gmx","de"] --> "gmx"
    else
      short2=""
      short3=""
    end
    # get the longest string, except short3
    if short1!=nil and longest.length < short1.length
      short0 = short1
      short1 = longest
      longest = short0
    end
    if short2!=nil and longest.length < short2.length
      short0 = short2
      short2 = longest
      longest = short0
    end
    # start the algorithm
    fullname = Hash.new
    fullname[:firstname] = nil
    fullname[:lastname] = nil
    # try to split
    # case 1: space or special signs ('.', '_') are the delimiter
    #         "Firstname Lastname" or "firstname lastname" or "Firstname lastname" or "firstname Lastname"
    #      or "Firstname.Lastname" or "firstname.lastname"
    if fullname[:firstname] == nil
      splitname = longest.split(/[\s._]/)
      if splitname.length == 2
        fullname[:firstname] = splitname[0].capitalize
        fullname[:lastname] = splitname[1].capitalize
      end
    end
    # case 2: uppercase letters are the signs "FirstnameLastname" or "firstnameLastname"
    if fullname[:firstname] == nil
      splitname = longest.split(/([A-Z][a-z]*)/)
      if splitname.length == 4
        fullname[:firstname] = splitname[1].capitalize
        fullname[:lastname] = splitname[3].capitalize
      end
      if splitname.length == 2
        fullname[:firstname] = splitname[0].capitalize
        fullname[:lastname] = splitname[1].capitalize
      end
    end
    # case 3: Do splitting like case1 and case2 with short1, short2 and check the relevance
    if fullname[:firstname] == nil
      splitnames=[{:relevance => 0,:value=>[]},{:relevance => 0,:value=>[]},{:relevance => 0,:value=>[]},{:relevance => 0,:value=>[]}]
      splitnames[0][:value] = short1.split(/[\s._]/)
      splitnames[1][:value] = short1.split(/([A-Z][a-z]*)/).delete_if {|x| x == "" }
      splitnames[2][:value] = short2.split(/[\s._]/)
      splitnames[3][:value] = short2.split(/([A-Z][a-z]*)/).delete_if {|x| x == "" }
      splitnames.each do |the_hash|
        if the_hash[:value].length == 2
          the_hash[:relevance] = the_hash[:relevance] + 1
          the_hash[:relevance] = the_hash[:relevance] + 1 if longest.include?(the_hash[:value][0])
          the_hash[:relevance] = the_hash[:relevance] + 1 if longest.include?(the_hash[:value][1])
          the_hash[:relevance] = the_hash[:relevance] + 1 if longest.include?(the_hash[:value][0].downcase)
          the_hash[:relevance] = the_hash[:relevance] + 1 if longest.include?(the_hash[:value][1].downcase)
          the_hash[:relevance] = the_hash[:relevance] + 1 if longest.downcase.include?(the_hash[:value][0].downcase)
          the_hash[:relevance] = the_hash[:relevance] + 1 if longest.downcase.include?(the_hash[:value][1].downcase)
        end
      end  
      splitnames = splitnames.sort_by{|splitname| splitname[:relevance] }
      splitname = splitnames[3][:value]
      if splitname.length == 2
        fullname[:firstname] = splitname[0].capitalize
        fullname[:lastname] = splitname[1].capitalize
      end
    end
    # case 4: try to find short1, short2, short3 inside longest
    if fullname[:firstname] == nil
      splitnames=[{:splitter => [short1, short2, short3], :values=>[longest]},
                  {:splitter => [short1, short3, short2], :values=>[longest]},
                  {:splitter => [short2, short3, short1], :values=>[longest]},
                  {:splitter => [short2, short1, short3], :values=>[longest]},
                  {:splitter => [short3, short1, short2], :values=>[longest]},
                  {:splitter => [short3, short2, short1], :values=>[longest]}]
      new_values=Array.new
      splitnames.each do |the_hash|
        the_hash[:splitter].each do |the_splitter|
          the_hash[:values]=new_values.flatten if !new_values.empty?
          new_values=Array.new
          the_hash[:values].each do |the_value|
            splitting = the_value.downcase.split(the_splitter.downcase)
            if splitting.length == 1
              #not found or found at the end
              if splitting[0].downcase != the_value.downcase
                #found at the end
                new_values.push(splitting[0])
                new_values.push(the_splitter)
              end
            end
            if splitting.length == 2
              #found at the beginning or in the middle
              if splitting[0].length==0
                #found at the beginning
                new_values.push(the_splitter)
                new_values.push(splitting[1])
              else
                #found in the middle
                new_values.push(splitting[0])
                new_values.push(the_splitter)
                new_values.push(splitting[1])
              end
            end
          end
        end
      end
      # make the values uniq
      splitvalues=Array.new
      splitnames.each do |splitname|
        splitvalues.push(splitname[:values]) if splitname[:values].count > 1
      end
      if !splitvalues.empty?
        splitvalues.uniq!
        if splitvalues.count > 1
          puts "More than one solution for user found. Take the first one."
        end
        fullname[:firstname] = splitvalues[0][0].capitalize
        fullname[:lastname] = splitvalues[0][1].capitalize
      end
    end
    # case 5: longest => firstname, short1 => lastname, if different
    if fullname[:firstname] == nil
      if longest != short1 and short1!=""
        fullname[:firstname] = longest.capitalize
        fullname[:lastname] = short1.capitalize
      end
    end
    # case 6: short2 => firstname, short1 => lastname, if different
    if fullname[:firstname] == nil
      if short2 != short1 and short1!="" and short2!=""
        fullname[:firstname] = short2.capitalize
        fullname[:lastname] = short1.capitalize
      end
    end
    # case 7: short2 => firstname, short3 => lastname, if different
    if fullname[:firstname] == nil
      if short2 != short3 and short2!="" and short3!=""
        fullname[:firstname] = short2.capitalize
        fullname[:lastname] = short3.capitalize
      end
    end
    # last way out:
    if fullname[:firstname] == nil or fullname[:firstname] == ""
      fullname[:firstname] = "Firstname"
    end
    if fullname[:lastname] == nil or fullname[:lastname] == ""
      fullname[:lastname] = longest.capitalize
    end    
    return fullname
  end
      
  #user_string = "Firstname Lastname" inside ReqPro
  # rpusers[key] ={:firstname => "Firstname", :lastname => "Lastname", :rmuser => rm-user}
  # if a rpuser is found --> check the rmusers for existenz
  def find_user_by_string(rp_user_string, rpusers)
    rp_fullname = get_fullname(rp_user_string, nil, nil)
    found_user = nil
    # best level:
    rpusers.each_value do |a_rpuser|
      if (a_rpuser[:firstname].downcase + a_rpuser[:lastname].downcase) == (rp_fullname[:firstname].downcase + rp_fullname[:lastname].downcase)
        found_user = a_rpuser[:rmuser]
        break
      end 
    end
    # second level:
    if found_user == nil
      rpusers.each_value do |a_rpuser|
        if a_rpuser[:firstname].downcase.include?(rp_fullname[:firstname].downcase + rp_fullname[:lastname].downcase)
          found_user = a_rpuser[:rmuser]
          break
         end
      end
    end
    # third level:
    if found_user == nil
      rpusers.each_value do |a_rpuser|
        if a_rpuser[:lastname].downcase == rp_fullname[:lastname].downcase
          found_user = a_rpuser[:rmuser]
          break
        end
      end
    end
    # last levels without mapping
    if found_user == nil
      if rp_fullname[:firstname] != nil and rp_fullname[:lastname] != nil
        found_user = User.find(:all, :conditions => {:lastname => rp_fullname[:lastname], :firstname => rp_fullname[:firstname]})[0]
      end
    end
    if found_user == nil
      if rp_fullname[:lastname] != nil
        found_user = User.find_by_lastname(rp_fullname[:lastname]) || User.find_by_firstname(rp_fullname[:lastname]) || User.find_by_login(rp_fullname[:lastname])
      end
    end
    if found_user == nil
      if rp_fullname[:firstname] != nil
        found_user = User.find_by_firstname(rp_fullname[:firstname]) || User.find_by_lastname(rp_fullname[:firstname]) || User.find_by_login(rp_fullname[:firstname])
      end
    end
    return found_user
  end
  
  # create project custom field for RPUID
  # give back an succesfull saved UserCustomField
  def create_user_custom_field_for_rpuid(loglevel)
    new_user_custom_field = UserCustomField.find_by_name("RPUID")
    if new_user_custom_field == nil
      new_user_custom_field = UserCustomField.new
      new_user_custom_field.name = "RPUID"
      new_user_custom_field.field_format = "string"
      new_user_custom_field.default_value = ""
      new_user_custom_field.min_length = "0"
      new_user_custom_field.max_length = "0"
      new_user_custom_field.possible_values = ""
      new_user_custom_field.is_required = "0"
      new_user_custom_field.regexp = ""
      new_user_custom_field.visible = "1"
      new_user_custom_field.editable = "0"
      if !new_user_custom_field.save
        debugger
        puts "Error: Unable to create user custom field for RPUID"
        debugger
      end
    else
      puts "User custom field for RPUID already exist." if loglevel > 10
    end
    return new_user_custom_field
  end
   
  # each user have to have an "RPUID" custom field
  # the corresponding redmine user is given back
  def user_find_by_rpuid(rpuid)
    custom_value = CustomValue.find(:first, :conditions => { :value => rpuid, :customized_type => "User" })
    if custom_value == nil
      return nil
    end
    return User.find_by_id(custom_value.customized_id)
  end
  
private

  #get an data path to open an ProjectUserGroups file
  #collect all users to an array of hash
  # add a possible ":conf_key" (conflation-key)
  def collect_users_fast(some_projects, conflate_users, loglevel)
    users = Hash.new
    some_projects.each_value do |a_project|
      if a_project[:path] != nil
        xmldoc = open_xml_file(a_project[:path],"ProjectUserGroups.XML", loglevel)
        if xmldoc != nil
          # collect used active users  
          xmldoc.elements.each("PROJECT/Users/User") do |user|
            if user.attributes["Active"] == "True" and user.attributes["EmailAddress"].casecmp("@") == 1
              hash_key = user.attributes["ID"]
              if users[hash_key] == nil #not known
                users[hash_key] = Hash.new
                users[hash_key] [:project] = a_project[:prefix]
                users[hash_key] [:email] = user.attributes["EmailAddress"] 
                users[hash_key] [:login] = user.attributes["LoginName"]
                fullname = get_fullname(user.attributes["FullName"], users[hash_key] [:email], users[hash_key] [:login])
                users[hash_key] [:firstname] = fullname[:firstname]
                users[hash_key] [:lastname] = fullname[:lastname]
                users[hash_key] [:group] = user.attributes["GroupGUID"]
              else
                #this should never be the case --> better is to raise an error in that case 
                #make an array and add the next project
                users[hash_key] [:project] = users[hash_key] [:project].to_a 
                users[hash_key] [:project].push(a_project[:prefix])
                users[hash_key] [:project].uniq!
                users[hash_key] [:project].sort!
              end
              case conflate_users
              when "email"
                users[hash_key][:conf_key] = users[hash_key][:email]
              when "login"
                users[hash_key][:conf_key] = users[hash_key][:login]
              when "name"
                users[hash_key][:conf_key] = users[hash_key][:firstname] + " " + users[hash_key][:lastname]
              else
                #most uniq key without conflation
                users[hash_key][:conf_key] = users[hash_key][:project] + "." + users[hash_key][:login] + "." + users[hash_key][:email]
              end
            end #user.attributes["Active"] == "True" and user.attributes["EmailAddress"].casecmp("@") == 1
          end #xmldoc.elements.each("PROJECT/Users/User") 
        end #a_project[:path] != nil
      end #xmldoc != nil
    end #some_projects.each_value
    return users
  end
  
end