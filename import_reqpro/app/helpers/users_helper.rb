module UsersHelper
  
  def collect_users(some_projects)
    users = collect_users_fast(some_projects)
    return users
  end
  
  def remap_users_to_project_prefix(users, conflate_users)
    # remap prefixes to key: .project+:prefix
    # if conflation is allowed, project is not used for key (all projects have (nearly) the same users)
    # take same prefixes of several projects together
    # fill in only needed or not tested req types (status = "+" or "?")
    remaped_users = Hash.new
    users.each_pair do |usr_key,usr_type|
      case conflate_users
      when "email"
        hash_key = usr_type[:email]
      when "login"
        hash_key = usr_type[:login]
      when "name"
        hash_key = usr_type[:firstname] + " " + usr_type[:lastname]
      else
        hash_key = usr_type[:project] + "." + usr_type[:login] + "." + usr_type[:email]
      end 
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
    return remaped_users
  end
  
  def update_users_for_map_needing(users, user_mapping, conflate_users)
    #call after manual mapping in view
    # delete not mapped (means not used) users
    # add :mapping target if needed      
    users.each do |key, usr|
      #generate conflation dependent key 
      case conflate_users
      when "email"
        usr[:conf_key] = usr[:email]
      when "login"
        usr[:conf_key] = usr[:login]
      when "name"
        usr[:conf_key] = usr[:firstname] + " " + usr[:lastname]
      end
      # update
      if user_mapping[usr[:conf_key]] == nil
        users.delete(key) # entry not used 
      else
        usr[:mapping] = user_mapping[usr[:conf_key]][:rm_user]
      end   
    end
    return users
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
  
private
  def collect_users_fast(some_projects)
    #get an data path to open an ProjectStructure file
    #collect all prefixes and guids to an array of hash
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
        end 
      end
    end
    return users
  end
  
end