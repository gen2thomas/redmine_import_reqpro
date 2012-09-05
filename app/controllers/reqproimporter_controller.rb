#require 'tempfile'
require 'rexml/document'
require File.dirname(__FILE__) + '/../../app/helpers/files_helper'
require File.dirname(__FILE__) + '/../../app/helpers/projects_helper'
require File.dirname(__FILE__) + '/../../app/helpers/ext_projects_helper'
require File.dirname(__FILE__) + '/../../app/helpers/users_helper'
require File.dirname(__FILE__) + '/../../app/helpers/requirement_types_helper'
require File.dirname(__FILE__) + '/../../app/helpers/attributes_helper'
require File.dirname(__FILE__) + '/../../app/helpers/requirements_issues_helper'

include REXML
include FilesHelper
include ProjectsHelper
include ExtProjectsHelper
include UsersHelper
include RequirementTypesHelper
include AttributesHelper
include RequirementsIssuesHelper

class ReqproimporterController < ApplicationController
  unloadable
    
  ISSUE_ATTRS = [:assigned_to, :author, :category, :priority, :status,
      :start_date, :due_date, :done_ratio, :estimated_hours, :watchers]

  def initialize
    @@attr_debugger = Array.new
    @debug = true
  end
  
  def index
    @progress_percent = [0,0]
  end

  def listprojects
    #list all projects with some informations and external project prefixes
    #--------------------
    # read a textfile which include all the project directories with path
    # at the local machine
    if params[:file] == nil
      flash.now[:error] = l_or_humanize("label_no_file")
      return false
    end
    @@original_filename = params[:file].original_filename
    @original_filename = @@original_filename # need for view
    actual_data = params[:file].read
    deep_check_ext_projects = params[:deep_check_ext_projects]
    #collect data pathes in an array
    collected_data_pathes = string_data_pathes_to_array(actual_data)
    #--------------------
    # generate the header for view
    @headers = Array.new
    @headers = ["label_import", "label_prefix", "label_projectname", "label_description", "label_date", "label_extproj_prefixes"]
    #--------------------
    # generate the projects content
    @@some_projects = collect_projects(collected_data_pathes, deep_check_ext_projects)
    if @@some_projects == nil
      flash.now[:error] = l_or_humanize("label_no_project")
      return false
    end
    @projects_keys_sorted = projects_sorted_array_of_key(@@some_projects) # need for view
    @projects_for_view = @@some_projects # need for view
    @progress_percent = [0, 20]
  end
  
  def matchusers
    @original_filename = @@original_filename # need for view
    # collect users of all available projects and add conflation key
    if @@some_projects == nil # need this test because browser back key
      flash.now[:error] = l_or_humanize("label_no_project_to_import_go_to_file_dialog")
      return false
    end
    @@some_projects = update_projects_for_needing(@@some_projects, params[:import_this_projects])
    if @@some_projects == nil
      flash.now[:error] = l_or_humanize("label_no_project_to_import")
      return false
    end
    # generate the default header for view
    @headers = Array.new
    @headers = ["label_prefixed_login", "label_user_email", "label_mapped_user_email", "label_more_info"]
    @@rpusers = collect_rpusers(@@some_projects, params[:conflate_users])
    # remap used users to :conf_key (conflation key)
    @rpusers_for_view = remap_users_to_conflationkey(@@rpusers)
    if @rpusers_for_view != nil
      #for displaying in alphabethical order (conf_key)
      @rpusers_keys_sorted = @rpusers_for_view.keys.sort
    end
    # entries in list fields for already existend redmine users 
    @@redmine_users = Hash.new
    @@redmine_users[:rmusers] = Array.new
    @@redmine_users[:key_for_view] = Array.new
    @conflate_users = params[:conflate_users] #used for view
    User.find(:all).each do |usr|
      case @conflate_users
      when "login"
        if usr[:login].length > 2
          @@redmine_users[:key_for_view].push(usr[:login])
          @@redmine_users[:rmusers].push(usr)
        end
        @headers = ["label_prefixed_email", "label_user_login", "label_mapped_user_login", "label_more_info"]
      when "name"
        if usr[:lastname].length > 2
          @@redmine_users[:key_for_view].push(usr[:firstname] + " " + usr[:lastname]) 
          @@redmine_users[:rmusers].push(usr)
        end
        @headers = ["label_prefixed_email", "label_user_name", "label_mapped_user_name", "label_more_info"]
      else
        #default for "email" and "none" 
        if usr[:mail].casecmp("@") == 1
          @@redmine_users[:key_for_view].push(usr[:mail])
          @@redmine_users[:rmusers].push(usr)
        end
      end
    end
    @rmusers_for_view = @@redmine_users[:key_for_view]
    @progress_percent = [0, 40]
    #mapping now in variable "params[:fields_map_user]"
  end
  
  def matchtrackers
    @original_filename = @@original_filename # need for view
    @@user_update_allowed = params[:user_update_allowed]
    deep_check_req_types = params[:deep_check_req_types]
    conflate_req_types = params[:conflate_req_types]
    # delete unused rpusers, add equivalent rmuser  
    @@rpusers = update_rpusers_for_map_needing(@@rpusers, @@redmine_users, params[:fields_map_user], @debug)
    # collect req types of all available projects
    @@requirement_types = collect_requirement_types(@@some_projects, deep_check_req_types)
    # generate the header for view
    @headers = Array.new
    @headers = ["label_prefixed_reqtype", "label_mapped_reqtype", "label_reqname"]
    # remap used req types to "Project.Prefix" and take same prefixes of several projects together if conflating
    # :rt_prefix => {:name => "name", :project=>["p_prefix1","p_prefix2"]}
    @req_types_for_view = remap_req_types_to_project_prefix(@@requirement_types, conflate_req_types)
    if @req_types_for_view != nil
      #for displaying in alphabethical order (project.prefix)
      @req_types_keys_sorted = @req_types_for_view.keys.sort
    end
    # entries in list fields 
    @trackers = Array.new
    Tracker.find(:all).each do |tr|
      @trackers.push(tr[:name])
    end
    #mapping now in variable "params[:fields_map_tracker]"
    @progress_percent = [0, 60]
  end
  
  def matchversions
    @original_filename = @@original_filename # need for view
    @@tracker_mapping = set_tracker_mapping(params[:fields_map_tracker])
    if @@tracker_mapping.empty?
      flash.now[:error] = l_or_humanize("label_no_trackermapping")
      return false
    end
    deep_check_attributes = params[:deep_check_attributes]
    @@requirement_types = update_requ_types_for_map_needing(@@requirement_types, @@tracker_mapping)
    # make a list of used attributes in requirement types
    used_attributes_in_rts = make_attr_list_from_requirement_types(@@requirement_types)
    # collect attributes of all available projects
    @@attributes = collect_attributes(@@some_projects, @@requirement_types, used_attributes_in_rts, deep_check_attributes)
    # prepare header for view
    @headers = Array.new
    @headers = ["label_prefixed_projects", "label_used_attribute_for_version"]
    # remap {Project1=>[P1_Attrlabel1, P1_Attrlabel2], Project2=>[P2_Attrlabel1, P2_Attrlabel2]}
    # @projects_with_attributes_for_view = remap_attributlabels_to_projectprefix(@@attributes)
    @projects_with_versionattributes_for_view = remap_listattrlabels_to_projectid(@@attributes)
    @projects_for_view = @@some_projects
    @attrs_for_view = @@attributes
    #mapping now in variable "params[:fields_map_version]"
    @progress_percent = [0, 70]
  end
  
  def matchattributes
    @original_filename = @@original_filename # need for view
    @@versions_mapping = set_versions_mapping(params[:fields_map_version], @@attributes)
    @@version_update_allowed = params[:version_update_allowed]
    conflate_attributes = params[:conflate_attributes]
    # headers for view
    @headers = Array.new
    @headers = ["label_prefixed_attributes", "label_mapped_attributes", "label_datatype_values"]
    # remap again (attributes for versions will deselect) 
    # to "Project.AttrLabel" and take same prefixes of several projects together if conflating
    # needing: ":attrlabel", ":project"=>[], ":rtprefix"=>[], ":datatype", ":itemtext"=>[]
    @novattributes_for_view = remap_noversionattributes_to_attrlabel(@@attributes, @@versions_mapping, conflate_attributes)
    if @novattributes_for_view != nil
      #for displaying in alphabethical order (:label)
      @novattributes_keys_sorted = @novattributes_for_view.keys.sort
    end
    # search for all known attributes
    @@known_attributes = Hash.new
    @attrs = Array.new
    ISSUE_ATTRS.each do |attri|
      key = l_or_humanize(attri, :prefix=>"field_")
      @attrs.push(key)
      @@known_attributes[key] = Hash.new
      @@known_attributes[key][:custom_field_id] = "" 
    end
    IssueCustomField.find(:all).each do |cu_fi|
      key = cu_fi[:name]
      @attrs.push(key)
      @@known_attributes[key] = Hash.new
      @@known_attributes[key][:custom_field_id] = cu_fi[:id]
    end
    @attrs.uniq!
    @attrs.sort!
    #mapping now in variable "params[:fields_map_attribute]"
    @progress_percent = [0, 80]
  end
  
  def do_import_and_result
    @original_filename = @@original_filename # need for view
    attributes_mapping = set_attributes_mapping(params[:fields_map_attribute])
    issue_update_allowed = params[:issue_update_allowed]
    import_parent_relation = params[:import_parent_relation_allowed]
    import_internal_relations = params[:import_internal_relation_allowed]
    import_external_relations = params[:import_external_relation_allowed]
    #delete unused attributes
    @@attributes = update_attributes_for_map_needing(@@attributes, @@versions_mapping, attributes_mapping)
    @@import_results = {:users => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                        :projects => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                        :trackers => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                        :versions => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                        :attributes => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                        :issues => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                        :issue_internal_relations => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                        :issue_external_relations => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                        :sum => {:imported => 0, :updated => 0, :failed => 0, :sum =>0}
                       }
    # users
    @@rpusers = create_all_users_and_update(@@rpusers, @@user_update_allowed)
    # new requirement types (key is the ID):
    #@@requirement_types, @@tracker_mapping (:rt_prefix=> {:tr_name, :trid})
    @@tracker_mapping = create_all_trackers_and_update_mapping(@@tracker_mapping)
    # add all needed attributes as custom fields
    # new attributes for requirements (Key is the ID): #@@attributes
    #new attributes for requirements - remapped to key = :project+:attrlabel+:status (or without :project):
    @@known_attributes = create_all_customfields(@@known_attributes, @@attributes, attributes_mapping, @@versions_mapping, @@tracker_mapping)
    # new projects: @@some_projects[:rpid][:rmid] => Project id inside redmine
    @@some_projects = create_all_projects(@@some_projects, @@tracker_mapping, @@rpusers)
    # create all versions
    new_versions_mapping = create_all_versions(@@versions_mapping, @@attributes, @@version_update_allowed, @debug)
    # now import all issues from each ReqPro project 
    return_hash_from_issues = create_all_issues(@@some_projects, @@requirement_types, @@attributes, new_versions_mapping, @@known_attributes, @@rpusers, issue_update_allowed, @debug)
    # update parents
    if import_parent_relation
      puts "Wait for update parents" if @debug
      update_issue_parents(return_hash_from_issues[:rp_req_unique_names], @debug)
    end
    #update internal and/or external traces
    if (import_internal_relations or import_external_relations)
      puts "Wait for create issue relations from traces" if @debug
      create_all_issuerelations(return_hash_from_issues[:rp_relation_list], import_internal_relations, import_external_relations, @debug)
    end
    # make the content for table
    @imp_res_header = [:imported, :updated, :failed]
    @imp_res_first_column = [:projects, :users, :trackers, :versions, :attributes, :issues, :issue_internal_relations, :issue_external_relations]
    @imp_res_header.each do |column|
      @imp_res_first_column.each do |row|
        @@import_results[:sum][column] += @@import_results[row][column]
        @@import_results[row][:sum] += @@import_results[row][column]
      end
    end
    @imp_res = @@import_results
    @progress_percent = [100, 100]
  end
   
private
  
  def set_tracker_mapping(tracker_map)
    tracker_mapping = Hash.new
    tracker_map.each do |rt_prefix,tr_name|
      if tr_name != ""
        tracker_mapping[rt_prefix]=Hash.new
        tracker_mapping[rt_prefix][:tr_name]=tr_name.gsub(/[^\w\s\'\-]/,"_") # replace all non ok characters with "_"
      end 
    end
    return tracker_mapping
  end
  
  # convert mapping hash {proj1_id => attr1label, proj2_id => attr1label, proj3_id => attr2label}
  # to hash {proj1_id => attr1_id, proj2_id => attr1_id, proj3_id => attr2_id}
  def set_versions_mapping(versions_map, attributes)
    vmap_new = Hash.new
    if versions_map != nil and attributes != nil
      versions_map.each do |v_key, v_val|
        vval_new = attribute_find_by_projectid_and_attrlabel(attributes, v_key, v_val)
        if vval_new != nil
          vmap_new[v_key] = vval_new.to_a.flatten[0] # the key of hash
        end
      end
    end
    return vmap_new
  end
  
  # create a hash {rpattrprefix1[:attr_name] => attr_name1, rpattrprefix2[:attr_name] => attr_name1, rpattrprefix3[:attr_name] => attr_name2} 
  def set_attributes_mapping(attributes_map)
    attributes_mapping = Hash.new
    if attributes_map != nil
      attributes_map.each do |reqproattr_prefix, attr_name|
        if attr_name != ""
          attributes_mapping[reqproattr_prefix]=Hash.new
          attributes_mapping[reqproattr_prefix][:attr_name]=attr_name
        end 
      end
    end
    return attributes_mapping
  end
  
  # create new redmine users from rp-users
  def create_all_users_and_update(rp_users, update_allowed)
    # looking for existend users because while importing multiple projects
    # can cause double users which will cause an error while save the user
    if rp_users != nil
      #TODO: koennen das nicht auch mehrere admins sein?
      admin_user = User.find_by_admin(true) #new user modifications forbidden for admin users
      import_new_user = false
      rp_users.each do |rp_key, rp_user|
        new_user = rp_user[:rmuser]
        if new_user != nil
          puts "User already exist: " + new_user[:mail]  + " -> " + rp_user[:email] if @debug
          next if !update_allowed
        else
          new_user = User.find_by_mail(rp_user[:email])
          if new_user != nil
            puts "User found via mail: " + new_user[:mail]  + " -> " + rp_user[:email] if @debug
            rp_user[:rmuser] = new_user # update mapping
            next if !update_allowed
          else
            new_user = User.find_by_login(rp_user[:login])
            if new_user != nil
              puts "User found via login: " + new_user[:login]  + " -> " + rp_user[:login] if @debug
              rp_user[:rmuser] = new_user # update mapping
              next if !update_allowed
            else
              new_user = User.new
              import_new_user = true
            end
          end
        end
        # new user or update allowed for known user
        # prevent overwrite or update an admin user
        if new_user[:admin] == false and rp_user[:login] != admin_user[:login] and rp_user[:email] != admin_user[:mail]
          new_user[:mail] = rp_user[:email]
          new_user[:login] = rp_user[:login]          
        else
          puts "Unable to manipulate importand datas of an admin user: " + new_user[:mail] + ", login: " + new_user[:login]
        end
        new_user[:lastname] = rp_user[:lastname] || rp_user[:login] || rp_user[:firstname]
        new_user[:firstname] = rp_user[:firstname] || rp_user[:lastname] || rp_user[:login]
        # add rpid as "RPUID"
        if rp_key.to_s != "" and rp_key.to_s != nil
          user_custom_field_for_rpuid = create_user_custom_field_for_rpuid(@debug)
          # set value
          # "new_user.custom_values" could never be nil, always an empty array "[]"
          new_user.custom_field_values={user_custom_field_for_rpuid.id => rp_key.to_s}
        else
          puts "User RPUID is empty!"
          debugger
        end 
        if new_user.save
          if import_new_user
            @@import_results[:users][:imported] += 1
          else
            @@import_results[:users][:updated] += 1
          end
          rp_user[:rmuser] = new_user # update mapping
        else
          @@import_results[:users][:failed] += 1
          debugger
          puts "Unable to import user: " + new_user[:mail]
        end
      end
    end
    return rp_users
  end
  
  def create_all_trackers_and_update_mapping(tracker_mapping)
    # create new trackers from requirement types
    # update tracker_mapping with "tracker id"
    # make a list for issue custom fields later on (:reqtype_id=>:tracker_id)
    tracker_mapping.each do |rt_prefix,tr_value|
      # check for using 
      # check for tracker is existend
      #tracker = Tracker.find(:all, :conditions => ["name=?", tr_value[:tr_name]])[0]
      tracker = Tracker.find_by_name(tr_value[:tr_name])
      if tracker == nil
        tracker = Tracker.create(:name=>tr_value[:tr_name], :is_in_roadmap=>"1")
        if tracker != nil
          @@import_results[:trackers][:imported] += 1
        else
          @@import_results[:trackers][:failed] += 1
          debugger
          puts "Unable to import tracker: " + tr_value[:tr_name]
        end
        #"project_ids"=>["u", "k"] will be filled later on
        #"custom_field_ids"=>["n","m"] will be filled later on
        #copy workflow is not mapped at the moment, therefore we copy first trackers workflow
        Role.find(:all).each do |role|
          #copy workflow from first tracker:
          Workflow.copy(Tracker.find(:first), role, tracker, role)
        end
      else
        puts "Tracker already exist: " + tr_value[:tr_name]  + "->" + rt_prefix if @debug
      end
      tracker_mapping[rt_prefix][:trid] = tracker[:id]
    end
    return tracker_mapping
  end
  
  def create_all_customfields(known_attributes, attributes, attributes_mapping, versions_mapping, tracker_mapping)
    if attributes != nil and !attributes_mapping.empty?
      fieldformat_mapping = {"Text" => "string", "MultiSelect" => "list", "List"=>"list", "Integer"=>"int", "Real"=>"float", "Date"=>"date"}
      attributes.each do |attr_key,attr_val|
        next if (attr_key == versions_mapping[attr_val[:projectid]])
        # check for "custom field" or "redmine attribute" is already existend
        newkey = attr_val[:mapping]
        if !known_attributes.include?(newkey) and !known_attributes.include?(newkey.gsub(/[^\w\s\'\-]/,"_"))
          # not known --> create a custom field for this attribute
          new_issue_custom_field = IssueCustomField.new 
          # --> .gsub(/[^\w\s\'\-]/,"_") # replace all non ok characters with "_"
          new_issue_custom_field.name = newkey.gsub(/[^\w\s\'\-]/,"_")
          new_issue_custom_field.field_format = fieldformat_mapping[attr_val[:datatype]]
          new_issue_custom_field.default_value = attr_val[:default]
          new_issue_custom_field.min_length = "0"
          new_issue_custom_field.max_length = "0"
          new_issue_custom_field.possible_values = ""
          new_issue_custom_field.trackers = Array.new
          new_issue_custom_field.searchable = "0"
          new_issue_custom_field.is_required = "0"
          new_issue_custom_field.regexp = "" 
          new_issue_custom_field.is_for_all = "0"
          new_issue_custom_field.is_filter = "1"
          #collect some trackers which need this custom field
          if attr_val[:rtprefixes] != nil
            attr_val[:rtprefixes].each do |prefix|
              next if tracker_mapping[prefix] == nil # used tracker is not mapped
              tracker = Tracker.find_by_id(tracker_mapping[prefix][:trid])
              new_issue_custom_field.trackers.push(tracker)
            end
          end
          # create now the right custom field for issue
          case new_issue_custom_field.field_format            
          when "int"
            new_issue_custom_field.min_length = "1"
            new_issue_custom_field.max_length = "999"
            if new_issue_custom_field.default_value == "" or new_issue_custom_field.default_value.to_i < new_issue_custom_field.min_length.to_i
              new_issue_custom_field.default_value = new_issue_custom_field.min_length
            end
            if new_issue_custom_field.default_value.to_i > new_issue_custom_field.max_length.to_i
              new_issue_custom_field.default_value = new_issue_custom_field.max_length
            end
            new_issue_custom_field.default_value = new_issue_custom_field.default_value.to_s
          when "float" 
            new_issue_custom_field.max_length = "999.9"
            if new_issue_custom_field.default_value == "" or new_issue_custom_field.default_value.to_f < new_issue_custom_field.min_length.to_f
              new_issue_custom_field.default_value = new_issue_custom_field.min_length
            end
            if new_issue_custom_field.default_value.to_f > new_issue_custom_field.max_length.to_f
              new_issue_custom_field.default_value = new_issue_custom_field.max_length
            end
            new_issue_custom_field.default_value = new_issue_custom_field.default_value.to_s
          when "date"
            new_issue_custom_field.default_value = new_issue_custom_field.default_value.to_s 
          when "list"
            new_issue_custom_field.possible_values = attr_val[:itemlist]
            new_issue_custom_field.searchable = "1"
          else
            # handle the rest as "string"
            new_issue_custom_field.field_format = "string"
            new_issue_custom_field.possible_values = attr_val[:itemlist].to_s + attr_val[:itemtext]
            new_issue_custom_field.searchable = "1"            
          end
          if (new_issue_custom_field.save)
            known_attributes[newkey] = Hash.new
            known_attributes[newkey][:custom_field_id] = new_issue_custom_field[:id] 
            @@import_results[:attributes][:imported] += 1
          else
            @@import_results[:attributes][:failed] += 1
            debugger
            puts "Unable to import attribute as custom field" + newkey
            debugger
          end
        else
          # already known attribute or custom field
          # check for custom field to update itemlist and trackers
          if known_attributes[newkey][:custom_field_id] != "" and known_attributes[newkey][:custom_field_id] != nil
            issue_custom_field = IssueCustomField.find(known_attributes[newkey][:custom_field_id])
            puts "Check for update attribute as custom field: " + issue_custom_field.name if @debug
            isc_changed = false
            if issue_custom_field[:field_format] == "list"
              list_elements = issue_custom_field[:possible_values] # make the string to an array
              list_elements.push(attr_val[:itemlist]) #add new element
              list_elements.flatten!
              list_elements.uniq!
              isc_changed = true
            end
            #collect some further trackers which need this custom field
            if attr_val[:rtprefixes] != nil
              isc_changed = true
              attr_val[:rtprefixes].each do |prefix|
                next if tracker_mapping[prefix] == nil # required tracker not mapped
                tracker = Tracker.find_by_id(tracker_mapping[prefix][:trid])
                issue_custom_field.trackers.push(tracker)
                issue_custom_field.trackers.uniq!
              end
            end
            #write it back
            if (isc_changed)
              if (issue_custom_field.save)
                @@import_results[:attributes][:updated] += 1
              else
                @@import_results[:attributes][:failed] += 1
                debugger
                puts "Unable to update attribute as custom field: " + newkey
                debugger
              end
            end
          else
            #TODO: If not a custom field: IssueStatuses and IssuePriorities also updatable
          end
        end
      end
    end
    return known_attributes
  end
  
  def create_all_projects(some_projects, tracker_mapping, rpusers)
    rpid_project_rmid = Hash.new # reqpro project ids --> redmine project ids
    # prepare some content of all new projects:
    # 1. trackers
    trackers = Array.new
    tracker_mapping.each_value do |a_tracker|
      tracker = Tracker.find_by_id(a_tracker[:trid])
      trackers.push(tracker)
    end
    # 2. all existend modules enabled
    enabled_module_names = Array.new
    EnabledModule.find(:all).each {|m| enabled_module_names.push(m[:name])}
    enabled_module_names.uniq!
    #enabled_module_names = ["issue_tracking", "time_tracking", "wiki"]
    some_projects.each do |key, a_project|
      new_project = Project.find_by_name(a_project[:name])
      if new_project == nil
        new_project = Project.new
        #generate new project
        new_project.description="Description: " + a_project[:description] + "\n\nRequisitePro project created: " + a_project[:date] + "\nImported: " + Time.now.to_s + "\nPID: " + key
        new_project.identifier = a_project[:prefix].downcase # only lower cases allowed
        new_project.name = a_project[:name]
        new_project.trackers = trackers
        new_project.enabled_module_names = enabled_module_names
        new_project.issue_custom_field_ids= [""]
        #, :homepage=>"", :parent_id=>"", 
        new_project.is_public = "0"
        # add rpid as "RPUID"
        if key.to_s != "" and key.to_s != nil
          project_custom_field_for_rpuid = create_project_custom_field_for_rpuid(@debug)
          # set value 
          # "new_project.custom_values" could never be nil, always an empty array "[]"
          new_project.custom_field_values={project_custom_field_for_rpuid.id => key.to_s}            
        else
          puts "Project RPUID is empty!"
          debugger
        end
        if (new_project.save) 
          @@import_results[:projects][:imported] += 1
        else
          @@import_results[:projects][:failed] += 1
          debugger
          puts "Unable to import project" + a_project[:name]
          debugger
        end
      else
        # project already exist
        puts "Existing project found: " + a_project[:name] if @debug
        # new trackers are possible --> update actual list
        trackers.concat(new_project.trackers)
        trackers.uniq!
        new_project.trackers = trackers
        if (new_project.save) 
          @@import_results[:projects][:updated] += 1
        else
          @@import_results[:projects][:failed] += 1
          debugger
          puts "Unable to update project" + a_project[:name]
          debugger
        end
      end
      a_project[:rmid] = new_project[:id]
      update_project_members_with_roles(new_project, rpusers, a_project[:author_rpid])
    end
    return some_projects    
  end
  
  
  # create version and
  # generate a hash {project_id1 => {attr1_id => {item1 => p1version1, item2 => p1version2}}},
  #                  project_id2 => {attr1_id => {item1 => p2version1, item2 => p2version2}}}
  #                  project_id3 => {:attrlabel => attr_name2, :itemlist => {item1 => p3version1, item2 => p3version2, item3 => p3version3}}
  def create_all_versions(versions_mapping, attributes, version_update_allowed, debug)
    if versions_mapping != nil
      vmap_new = Hash.new
      versions_mapping.each do |rp_project_id, attr_for_version_id|
        rm_project =  project_find_by_rpuid(rp_project_id)
        if rm_project == nil
          rm_project = Project.find_by_identifier(attributes[attr_for_version_id][:project].downcase)
        end
        if rm_project == nil
          puts "Project at version creation not found, take next! project ID: " + rp_project_id if debug
          next
        end
        vmap_new[rp_project_id] = Hash.new
        # TODO: hier gibt es manchmal ein Problem
        if attributes[attr_for_version_id] == nil
          debugger
        end
        if attributes[attr_for_version_id][:itemlist] == nil
          debugger
        end
        attributes[attr_for_version_id][:itemlist].each do |version_suffix|
          version_name = attributes[attr_for_version_id][:attrlabel] + "_" + version_suffix
          new_version = Version.find_by_name(version_name)
          if new_version == nil
            new_version = Version.new
            update_version = false
          else
            next if !version_update_allowed
            update_version = true
          end
          new_version.name = version_name
          new_version.description = version_suffix
          new_version.status = "open"
          new_version.sharing = "none"
          new_version.wiki_page_title = ""
          new_version.project = rm_project
          if (new_version.save)
            vmap_new[rp_project_id][version_name] = new_version
            if update_version
              @@import_results[:versions][:updated] += 1
            else
              @@import_results[:versions][:imported] += 1
            end
          else
            @@import_results[:versions][:failed] += 1
            debugger
            puts "Unable to import version" + attr_version[:attrlabel]
            debugger
          end
        end
      end
    end
    return vmap_new
  end
  
  # create all issues by importing requirements from each project
  # generate "rp_req_unique_names" list for further using (parent-child-import)
  # generate "rp_relation_list" list for further using (internal+external relations to import)
  def create_all_issues(some_projects, requirement_types, attributes, new_versions_mapping, known_attributes, rpusers, update_allowed, debug)
    rp_req_unique_names = Hash.new
    rp_relation_list = Hash.new
    some_projects.each do |rp_project_id, a_project|
      #find project
      project = Project.find_by_identifier(a_project[:prefix])
      if(!project) 
        puts "Unable to find project:" + a_project[:prefix] + "-->"+ a_project[:name]
        next #take next project
      end
      # import only reqirements if the requiremnet type is available (mapped to a tracker)
      not_imported_issues = 0
      # to convert text
      ic = Iconv.new('UTF-8', 'UTF-8')
      filepath = a_project[:path] # this is the main path of project
      a_project[:imported_issues] = 0
      # iterate issues
      all_files = collect_all_data_files(filepath)
      all_files.each do |filename|
        xmldoc = open_xml_file(filepath,filename)
        xmldoc.elements.each("PROJECT/Pkg/Requirements/Req") do |req|
          test_issue = Issue.new
          test_issue.project = project
          test_issue.subject = ic.iconv(req.elements["RName"].text)[0 .. 255] # limit to 200 char, not 255 because utf8
          # looking for ReqTyp ==> Tracker
          req_type = req.elements["RTID"].text
          if !(requirement_types.include?(req_type))
            puts "Issue will not be imported - needed Requirement Type was not imported: " + req_type + ":" + test_issue.subject if @debug
            next #take next requirement
          end
          test_issue.tracker = Tracker.find_by_name(requirement_types[req_type][:mapping])
          # import requirement as issue if needed
          if test_issue.tracker == nil
            puts "No Tracker found - Issue will not be imported: "+ req_type
            not_imported_issues += 1
            next #take next requirement
          end
          # looking for existend issue
          import_new_issue = false
          new_issue = Issue.find(:all, :conditions => { :project_id => test_issue.project[:id], :tracker_id => test_issue.tracker[:id], :subject => test_issue.subject })[0]
          if (new_issue != nil) and !(update_allowed)
            puts "Issue already exist but not updated: " + new_issue.project[:identifier] + ":" + new_issue.project[:name] + ":" + new_issue.subject if @debug
            next #take next requirement
          end
          # update issue or new issue
          if new_issue == nil
            new_issue = test_issue
            import_new_issue = true
          end
          rpid = req.elements["GUID"].text # this id
          #further issue parameters
          # don't use a "." to join "prefix" and "RPre"! --> actualy a "|" is used
          unique_name = a_project[:prefix] + "|" + req.elements["RPre"].text
          new_issue.description = "ReqPro-Prefix: " + unique_name + "\n\n" + ic.iconv(req.elements["RText"].text)
          new_issue.status = IssueStatus.default
          new_issue.priority = IssuePriority.default
          new_issue.category = IssueCategory.find(:all)[0]
          new_issue.author = User.current # default, can be overriden by "update_attribute_or_custom_field_with_value"
          new_issue.done_ratio = 0          
          if attributes != nil
            # import attributes:
            if req.elements["FVs"] != nil
              # the issue can have normal some attributes with value
              req.elements["FVs"].each do |fv|
                if fv != nil #not empty
                  hash_key = fv.elements["FGUID"].text
                  value = fv.elements["FTxt"].text
                  if attributes[hash_key] != nil
                    # import this attribute value
                    new_issue = update_attribute_or_custom_field_with_value(new_issue, attributes[hash_key][:mapping], 
                                  known_attributes[attributes[hash_key][:mapping]][:custom_field_id], value, rpusers, debug)
                  end
                end
              end
            end
            if req.elements["LVs"] != nil
              # the issue can have list-field-attributes 
              req.elements["LVs"].each do |lv|
                if lv != nil #not empty
                  hash_key = lv.elements["UDF"].text
                  value = lv.elements["LITxt"].text
                  if attributes[hash_key] != nil
                    # import this attribute value
                    puts "attribute with list element to update:" if @debug
                    #check for a version
                    if new_versions_mapping[rp_project_id] != nil
                      version_name = attributes[hash_key][:attrlabel] + "_" + value
                      a_version = new_versions_mapping[rp_project_id][version_name]
                      if a_version != nil
                        puts "attribute with list element is a version" if @debug
                        new_issue.fixed_version = a_version
                      end
                    else
                      new_issue = update_attribute_or_custom_field_with_value(new_issue, attributes[hash_key][:mapping], 
                                  known_attributes[attributes[hash_key][:mapping]][:custom_field_id], value, rpusers, debug)
                    end
                  end
                end
              end
            end
          end
          # attention! "due date" must be the same or greater than "start date"!
          # "start date" is allowed to be "nil"
          if new_issue.start_date != nil and new_issue.due_date != nil
            if (new_issue.start_date.to_time > new_issue.due_date.to_time)
              new_issue.start_date = new_issue.due_date
            end
          end
          # generate a relations-list for internal and external traces
          # "rpid" comes from "req.elements["GUID"].text" some lines above
          #{SPRJ1_ID => {TPRJ1_ID => {SREQ1_ID => [TREQ1_ID, TREQ2_ID]},
          #              TPRJ2_ID => {SREQ2_ID => [TREQ1_ID, TREQ4_ID]}}}
          # we use only TTo because:
          # TFrom is the same information like TTo f.e.:
          # (STRQ1 "TTo" NEED1) is the same like (NEED1 "TFrom" STRQ1)  
          if (req.elements["TTo"] != nil)
            rp_source_pid = rp_project_id
            rp_source_iid = rpid # issue id
            req.elements["TTo"].each do |treq|
              if treq != nil #not empty
                rp_target_iid = treq.elements["TRID"].text
                if (treq.elements["EPGUID"] != nil)
                  #this is an external relation
                  rp_target_pid = treq.elements["EPGUID"].text
                else
                  #this is an internal relation
                  rp_target_pid = rp_source_pid
                end
                # make new structure (if not exist)
                rp_relation_list[rp_source_pid] = Hash.new if rp_relation_list[rp_source_pid] == nil
                rp_relation_list[rp_source_pid][rp_target_pid] = Hash.new if rp_relation_list[rp_source_pid][rp_target_pid] == nil                
                rp_relation_list[rp_source_pid][rp_target_pid][rp_source_iid] = Array.new if rp_relation_list[rp_source_pid][rp_target_pid][rp_source_iid] == nil
                # fill content
                rp_relation_list[rp_source_pid][rp_target_pid][rp_source_iid].push(rp_target_iid) # to id
                rp_relation_list[rp_source_pid][rp_target_pid][rp_source_iid].uniq!
              end
            end
          end
          # TFrom elements
          if (req.elements["TFrom"] != nil)
            rp_target_pid = rp_project_id
            rp_target_iid = rpid # issue id
            req.elements["TFrom"].each do |treq|
              if treq != nil #not empty
                rp_source_iid = treq.elements["TRID"].text
                if (treq.elements["EPGUID"] != nil)
                  #this is an external relation
                  rp_source_pid = treq.elements["EPGUID"].text
                else
                  #this is an internal relation
                  rp_source_pid = rp_target_pid
                end
                # make new structure (if not exist)
                rp_relation_list[rp_source_pid] = Hash.new if rp_relation_list[rp_source_pid] == nil
                rp_relation_list[rp_source_pid][rp_target_pid] = Hash.new if rp_relation_list[rp_source_pid][rp_target_pid] == nil                
                rp_relation_list[rp_source_pid][rp_target_pid][rp_source_iid] = Array.new if rp_relation_list[rp_source_pid][rp_target_pid][rp_source_iid] == nil
                # fill content
                rp_relation_list[rp_source_pid][rp_target_pid][rp_source_iid].push(rp_target_iid) # to id
                rp_relation_list[rp_source_pid][rp_target_pid][rp_source_iid].uniq!
              end
            end
          end
          # add rpid as "RPUID"
          if rpid.to_s != "" and rpid.to_s != nil
            issue_custom_field_for_rpuid = create_issue_custom_field_for_rpuid(debug)
            issue_custom_field_for_rpuid = update_issue_custom_field(issue_custom_field_for_rpuid, new_issue.tracker, new_issue.project, debug)
            if issue_custom_field_for_rpuid.projects.length != issue_custom_field_for_rpuid.projects.uniq.length
              debugger
              puts "issue_custom_field has now multiple entries of at least one project"
            end
            if project.issue_custom_fields.length != project.issue_custom_fields.uniq.length
              debugger
              puts "project has now multiple entries of at least one issue_custom_field"
            end
            # set value
            new_issue = update_custom_value_in_issue(new_issue, issue_custom_field_for_rpuid, rpid, @debug)
          else
            puts "RPUID for issue is empty!"
            debugger
          end
          # try to save
          new_issue=issue_save_with_assignee_restore(new_issue)
          if new_issue==nil
            @@import_results[:issues][:failed] += 1
            debugger
            puts "Failed to save new issue"
            debugger
            next #take next requirement
          end
          if (import_new_issue)
            a_project[:imported_issues] += 1
            @@import_results[:issues][:imported] += 1
            rp_req_unique_names[unique_name.downcase] = new_issue[:id]
          else
            @@import_results[:issues][:updated] += 1
          end
        end
      end
    end
    return_hash_from_issues = Hash.new
    return_hash_from_issues[:rp_req_unique_names] = rp_req_unique_names
    return_hash_from_issues[:rp_relation_list] = rp_relation_list
    return return_hash_from_issues
  end
  
  
  # add internal traces as issue relations
  # use rp_relation_list as list from source project to target project
  # inside that list there is a list from source requirement to target requirements (array)
  # information about source and target project only used for result and some messages
  def create_all_issuerelations(rp_relation_list, import_intern_relation_allowed, import_extern_relation_allowed, debug)
    #{SPRJ1_ID => {TPRJ1_ID => {SREQ1_ID => [TREQ1_ID, TREQ2_ID]},
    #              TPRJ2_ID => {SREQ2_ID => [TREQ1_ID, TREQ4_ID]}}}
    rp_relation_list.each do |source_pid, target_pid_list|
      target_pid_list.each do |target_pid, source_iid_list|
        intern_relation = (source_pid == target_pid and import_intern_relation_allowed)
        extern_relation = (source_pid != target_pid and import_extern_relation_allowed)
        source_iid_list.each do |source_iid, target_iid_array|
          source_issue = issue_find_by_rpuid(source_iid, debug)
          if source_issue == nil
            @@import_results[:issue_internal_relations][:failed] += 1 if intern_relation
            @@import_results[:issue_external_relations][:failed] += 1 if extern_relation
            puts "No source issue found from RPUID " + source_iid + ", take next relation." if debug
            next
          end
          target_iid_array.each do |target_iid|
            target_issue = issue_find_by_rpuid(target_iid, debug)
            if target_issue == nil
              @@import_results[:issue_internal_relations][:failed] += 1 if intern_relation
              @@import_results[:issue_external_relations][:failed] += 1 if extern_relation
              puts "Related target issue (according to this internal trace) was not found, take next relation." if debug
              next
            end
            # check if relation exist
            if !IssueRelation.find(:all, :conditions => ["issue_from_id=? AND issue_to_id=? AND relation_type=?", source_issue, target_issue, "relates"])[0]
              issue_relation_new = IssueRelation.new
              issue_relation_new.issue_from = source_issue
              issue_relation_new.issue_to = target_issue
              issue_relation_new.relation_type = "relates"
              debugger
              if !(issue_relation_new.save)
                # failed relation is normal for installed KUP-Plugin
                @@import_results[:issue_internal_relations][:failed] += 1 if intern_relation
                @@import_results[:issue_external_relations][:failed] += 1 if extern_relation
                puts "Failed to save new internal issue relation." if (debug and intern_relation)
                puts "Failed to save new external issue relation." if (debug and extern_relation)
              else
                @@import_results[:issue_internal_relations][:imported] += 1 if intern_relation
                @@import_results[:issue_external_relations][:imported] += 1 if extern_relation
              end
            end
          end
        end
      end
    end
  end
  
  
end
