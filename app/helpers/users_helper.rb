module UsersHelper
  
  def collect_rpusers(some_projects, conflate_users)
    users = collect_users_fast(some_projects, conflate_users)
    return users
  end
  
  def remap_users_to_conflationkey(users)
    # remap prefixes to key: ":conf_key"
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
    
  def update_rpusers_for_map_needing(rpusers, rmusers, user_mapping, debug)
    #call after manual mapping in view
    # delete not mapped (means not used) users
    # add mapping target (:rmuser) if needed
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
            puts "New user for import found: " + rpuser_value[:email] if debug
          end
        else
          # delete unused rpuser
          rpusers.delete(rpuser_id)
        end
      end
    end
    return rpusers
  end  
  
  def get_fullname(fullname_old, email)
    # firstname and lastname are in the same string
    fullname = Hash.new
    fullname[:firstname] = nil
    fullname[:lastname] = nil
    # try to split
    # case 1: space is the delimiter "firstname lastname"
    splitname = fullname_old.split(/\s/)
    if splitname.length == 2
      fullname[:firstname] = splitname[0]
      fullname[:lastname] = splitname[1]      
    end
    # case 2: uppercase letters are the signs "FirstnameLastname" or "Firstname lastname"
    if fullname[:firstname] == nil
      splitname = fullname_old.split(/([A-Z][a-z]*)/)
      if splitname.length == 4
        fullname[:firstname] = splitname[1]
        fullname[:lastname] = splitname[3]      
      end
    end
    # check against errors and use mail
    # case 3: Firstname.Lastname@... or firstname.lastname@...
    #      or FirstnameLastname@... or firstnameLastname@...
    if fullname[:firstname] == nil
      if splitname.length < 4 and email != nil
        email1 = email.split(/[@]/) # ["firstname.lastname","gmx.de"]
        splitname = email1[0].split(/([A-Z]?[a-z]*)([.]?)/) # ["", "firstname", "", "", "Lastname"]
        if splitname.length == 5
          fullname[:firstname] = splitname[1]
          fullname[:lastname] = splitname[4]      
        end 
      end
    end
    # case 4: find login inside email
    #TODO: not done yet
    # case 5: firstname@lastname...
    if email1 != nil
      if fullname[:firstname] == nil
        fullname[:firstname] = email1[0]
      end
      if fullname[:lastname] == nil
        fullname[:lastname] = email1[1]
      end
    end
    # last way out:
    if fullname[:firstname] == nil
      fullname[:firstname] = "Firstname"
    end
    if fullname[:lastname] == nil
      fullname[:lastname] = fullname_old
    end
    return fullname
  end
  
  #user_string = "Firstname Lastname" inside ReqPro
  # rpusers[key] ={:firstname => "Firstname", :lastname => "Lastname", :rmuser => rm-user}
  # if a rpuser is found --> check the rmusers for existenz
  def find_user_by_string(rp_user_string, rpusers)
    rp_fullname = get_fullname(rp_user_string, nil)
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
  
private
  def collect_users_fast(some_projects, conflate_users)
    #get an data path to open an ProjectStructure file
    #collect all prefixes and guids to an array of hash
    # add a possible ":conf_key" (conflation-key)
    users = Hash.new
    some_projects.each_value do |a_project|
      xmldoc = open_xml_file(a_project[:path],"ProjectUserGroups.XML")
      # collect used active users  
      xmldoc.elements.each("PROJECT/Users/User") do |user|
        if user.attributes["Active"] == "True" and user.attributes["EmailAddress"].casecmp("@") == 1
          hash_key = user.attributes["ID"]
          if users[hash_key] == nil #not known
            users[hash_key] = Hash.new
            users[hash_key] [:project] = a_project[:prefix] 
            users[hash_key] [:login] = user.attributes["LoginName"]
            fullname = get_fullname(user.attributes["FullName"],user.attributes["EmailAddress"])
            users[hash_key] [:firstname] = fullname[:firstname]
            users[hash_key] [:lastname] = fullname[:lastname]
            users[hash_key] [:group] = user.attributes["GroupGUID"]
            users[hash_key] [:email] = user.attributes["EmailAddress"]
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
        end 
      end
    end
    return users
  end
  
end