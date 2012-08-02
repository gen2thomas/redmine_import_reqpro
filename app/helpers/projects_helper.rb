module ProjectsHelper
  
  # collect all available projects from the given array of pathes
  # add prefixes for external projects depend on one project
  # if deep check allowed, prefix include sign:
  #"+" needed, "-" not available, "*" not needed
  #otherwise "?" not tested
  def collect_projects(data_pathes, deep_check_ext_projects)
    # generate the projects content
    available_projects = collect_available_projects(data_pathes)
    # add external projects
    available_projects.each_value do |a_project|
      data_path = a_project[:path]
      #check for external projects
      external_projects = collect_external_projects(data_path, deep_check_ext_projects, available_projects)
      external_prefixes = external_prefixes_to_string(external_projects)
      a_project[:extprefixes] = external_prefixes
    end
    return available_projects
  end
  
  # make an sorted array of key for the view
  def projects_sorted_array_of_key(some_projects)
    if some_projects != nil
      # alphabethical order of name
      some_projects_sorted = some_projects.sort_by {|key,value| value[:name]}
      some_projects_sorted.each do |a_project|
        a_project.delete_at(1) # delete content, only keys needed
      end
      some_projects_sorted.flatten!
    end
    return some_projects_sorted
  end
  
  # delete not needed projects
  #needed projects is a array of the prefixes for the projects
  def update_projects_for_needing(some_projects, needed_projects)
    if needed_projects == nil
      #no project is needed
      some_projects=nil
    else
      some_projects.each do |p_key, p_value|
        next if p_value == nil or p_key == nil
        if needed_projects.index(p_value[:prefix]) == nil
          some_projects.delete(p_key)
        end
      end
    end
    return some_projects
  end
  
  #find member in actual project using name string in an attribute
  #1.) looking for name string inside rpusers
  #2.) looking for rpuser inside redmine users
  #3.) looking for membership inside the actual project
  def find_project_rpmember(userstring, rpusers, project, debug)
    found_user = find_user_by_string(userstring, rpusers)
    #check for members of project
    if found_user != nil
      if Member.find(:all, :conditions => { :user_id => found_user[:id], :project_id => project.id })[0] == nil
        puts "This user is not member of the project: " + found_user[:login] + "<-->" + project[:identifier] if debug
        found_user = nil # force user to nil because he is not allowed at this project
      end
    end
    return found_user
  end
  
  #make some rpusers (should be already an rmuser) to member of 
  #her rpproject(should be already an rmproject)
  #1.) found each rpuser for this rmproject
  #2.) check for rmuser was already generated from this rpuser
  #3.) make this rmuser (same like rpuser) to member of this rmproject (same like his rpproject) if not already done
  #3a) make the member an "Reporter", except the user is the given author --> "Manager"
  def update_project_members_with_roles(rmproject, rpusers, rpproject_author_rpid)
    if rpusers != nil
      rpusers.each do |a_rpid, a_rpuser|
        if a_rpuser[:project] != nil
          if a_rpuser[:project].downcase == rmproject[:identifier]
            rmuser = a_rpuser[:rmuser]
            if rmuser != nil
              if Member.find(:all, :conditions => { :user_id => rmuser[:id], :project_id => rmproject.id })[0] == nil
                new_member = Member.new
                new_member.user = rmuser
                new_member.project = rmproject 
                new_member.mail_notification = false
                if a_rpid == rpproject_author_rpid
                  new_member.roles.push(Role.find_by_name("Manager")) # use Manager for Project author
                else
                  new_member.roles.push(Role.find_by_name("Reporter")) # use reporter as default
                end
                new_member.roles.uniq!
                if !new_member.save()
                  debugger
                  puts "Err: Unable to save project member: " + rmproject[:identifier] + ", login:  " + rmuser[:login]
                  debugger
                  return false
                end
              else
                puts "Member already exist: " + rmuser[:login] if @debug
              end
            else
              debugger
              puts "Err: Requested user not found: " + a_rpuser[:user_id]
              debugger
              return false
            end
          end
        else
          debugger
          #TODO: bug#11155: Mapping to a user which is not inside rp project but exist already within redmine niO
          # this bug was not reproducable
          puts "Err: User without project found: " + a_rpuser[:login]
          debugger
        end
      end
    end
    return true
  end
  
  # create project custom field for RPUID
  def create_project_custom_field_for_rpuid(debug)
    the_name="RPUID"
    new_project_custom_field = ProjectCustomField.find_by_name(the_name)
    if new_project_custom_field == nil
      new_project_custom_field = ProjectCustomField.new 
      new_project_custom_field.name = the_name
      new_project_custom_field.field_format = "string"
      new_project_custom_field.default_value = ""
      new_project_custom_field.min_length = "0"
      new_project_custom_field.max_length = "0"
      new_project_custom_field.possible_values = ""
      new_project_custom_field.searchable = "1"
      new_project_custom_field.is_required = "0"
      new_project_custom_field.regexp = ""
      new_project_custom_field.visible = "1"
      if !new_project_custom_field.save
        debugger
        puts "Unable to create project custom field for RPUID"
        debugger
      end
    else
      puts "Project custom field for RPUID already exist." if debug
    end
    return new_project_custom_field
  end
  
  # each project have to have an "RPUID" custom field
  # the corresponding redmine project is given back
  def project_find_by_rpuid(rpuid)
    custom_value = CustomValue.find(:first, :conditions => { :value => rpuid, :customized_type => "Project" })
    if custom_value == nil
      return nil
    end
    return Project.find_by_id(custom_value.customized_id)
  end
  
private

  #collect all GUID and prefixes of all available projects
  #data_pathes is an array of all used pathes on local system
  def collect_available_projects(data_pathes)
    available_projects = Hash.new
    data_pathes.each do |data_path|
    (
      xmldocmain = open_xml_file(data_path,"Project.XML")
      hash_key = xmldocmain.elements["Project"].attributes["ID"]
      if available_projects[hash_key] == nil # not already known
        available_projects[hash_key] = Hash.new
        available_projects[hash_key] [:prefix] = xmldocmain.elements["Project"].attributes["Prefix"]
        available_projects[hash_key] [:path] = data_path
        available_projects[hash_key] [:author_rpid] = xmldocmain.elements["Project"].attributes["AuthorGUID"]
        available_projects[hash_key] [:name] = xmldocmain.elements["Project"].attributes["Name"]
        available_projects[hash_key] [:description] = xmldocmain.elements["Project"].attributes["Description"]
        available_projects[hash_key] [:date] = xmldocmain.elements["Project"].attributes["VersionDateTime"]
      end
    )
    end
    return available_projects    
  end
  
end