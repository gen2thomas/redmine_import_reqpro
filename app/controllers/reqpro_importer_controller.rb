require 'fastercsv'
require 'tempfile'
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

class MultipleIssuesForUniqueValue < Exception
end

class NoIssueForUniqueValue < Exception
end

class ReqproimporterController < ApplicationController
  unloadable
    
  ISSUE_ATTRS = [:assigned_to, :author, :category, :priority, :status,
      :start_date, :due_date, :done_ratio, :estimated_hours, :watchers]

  def initialize
    @debug = true
  end
  
  def index
    debugger
    @progress_percent = [0,0]
  end

  def listprojects
    #list all projects with some informations and external project prefixes
    #--------------------
    # read a textfile witch include all the project directories with path
    # at the local machine
    if params[:file] == nil
      flash.now[:error] = l_or_humanize("label_no_file")
      return false
    end
    @original_filename = params[:file].original_filename # need for view
    actual_data = params[:file].read
    deep_check_ext_projects = params[:deep_check_ext_projects]
    #collect data pathes in an array
    collected_data_pathes = string_data_pathes_to_array(actual_data)
    #--------------------
    # generate the header for view
    @headers = Array.new
    @headers = ["label_import", "label_number", "label_projectname", "label_description", "label_prefix", "label_date", "label_extproj_prefixes"]
    #--------------------
    # generate the projects content
    @@some_projects = collect_projects(collected_data_pathes, deep_check_ext_projects)
    if @@some_projects == nil
      flash.now[:error] = l_or_humanize("label_no_project")
      return false
    end
    @contents_of_projects = collected_projects_to_content_array(@@some_projects) # need for view
    @progress_percent = [0, 20]
  end
  
  def matchusers
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
    @@rpusers = collect_rpusers(@@some_projects, params[:conflate_users])
    # remap used users to :conf_key (conflation key)
    @rpusers_for_view = remap_users_to_conflationkey(@@rpusers)
    # entries in list fields for already existend redmine users 
    @@redmine_users = Hash.new
    @@redmine_users[:rmusers] = Array.new
    @@redmine_users[:key_for_view] = Array.new
    User.find(:all).each do |usr|
      case params[:conflate_users]
      when "email"
        if usr[:mail].casecmp("@") == 1
          @@redmine_users[:key_for_view].push(usr[:mail])
          @@redmine_users[:rmusers].push(usr)
        end
      when "login"
        if usr[:login].length > 2
          @@redmine_users[:key_for_view].push(usr[:login])
          @@redmine_users[:rmusers].push(usr)
        end
      when "name"
        if usr[:lastname].length > 2
          @@redmine_users[:key_for_view].push(usr[:firstname] + " " + usr[:lastname]) 
          @@redmine_users[:rmusers].push(usr)
        end
      end
    end
    @rmusers_for_view = @@redmine_users[:key_for_view]
    @progress_percent = [0, 40]
    #mapping now in variable "params[:fields_map_user]"
  end
  
  def matchtrackers
    deep_check_req_types = params[:deep_check_req_types]
    conflate_req_types = params[:conflate_req_types]
    # delete unused rpusers, add equivalent rmuser  
    @@rpusers = update_rpusers_for_map_needing(@@rpusers, @@redmine_users, params[:fields_map_user], @debug)
    # collect req types of all available projects
    @@requirement_types = collect_requirement_types(@@some_projects, deep_check_req_types)
    # remap used req types to "Project.Prefix" and take same prefixes of several projects together if conflating
    # :rt_prefix => {:name => "name", :project=>["p_prefix1","p_prefix2"]}
    @req_types_for_view = remap_req_types_to_project_prefix(@@requirement_types, conflate_req_types)
    # copy to instance variable because view can't handle class variable
    #@req_types_for_view = @@remapped_requirement_types
    # entries in list fields 
    @trackers = Array.new
    Tracker.find(:all).each do |tr|
      @trackers.push(tr[:name])
    end
    #mapping now in variable "params[:fields_map_tracker]"
    @progress_percent = [0, 60]
  end
  
  def matchattributes
    @@tracker_mapping = set_tracker_mapping(params[:fields_map_tracker])
    if @@tracker_mapping.empty?
      flash.now[:error] = l_or_humanize("label_no_trackermapping")
      return false
    end
    deep_check_attributes = params[:deep_check_attributes]
    conflate_attributes = params[:conflate_attributes]
    @@requirement_types = update_requ_types_for_map_needing(@@requirement_types, @@tracker_mapping)
    # make a list of used attributes in requiremet types
    used_attributes_in_rts = make_attr_list_from_requirement_types(@@requirement_types)
    # collect attributes of all available projects
    @@attributes = collect_attributes(@@some_projects, @@requirement_types, used_attributes_in_rts, deep_check_attributes)
    # remap to "Project.AttrLabel" and take same prefixes of several projects together if conflating
    # needing: ":attrlabel", ":project"=>[], ":rtprefix"=>[], ":datatype", ":itemtext"=>[]
    @attributes_for_view = remap_attributes_to_label(@@attributes, conflate_attributes)
    if @attributes_for_view != nil
      #for displaying in alphabethical order
      @attributes_keys_sorted = @attributes_for_view.keys.sort
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
    issue_custom_field = IssueCustomField.find(:all) 
    issue_custom_field.each do |cu_fi|
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
    attributes_mapping = set_attributes_mapping(params[:fields_map_attribute])
    update_allowed = params[:issue_update_allowed]
    #delete unused attributes
    @@attributes = update_attributes_for_map_needing(@@attributes, attributes_mapping)
    @@import_results = {:imported => {:users => 0, :projects => 0, :issues => 0, :trackers => 0, :attributes => 0},
                        :updated =>  {:users => 0, :projects => 0, :issues => 0, :trackers => 0, :attributes => 0},
                        :failed =>   {:users => 0, :projects => 0, :issues => 0, :trackers => 0, :attributes => 0}}
    # users
    @@rpusers = create_all_users_and_update(@@rpusers)
    # new requirement types (key is the ID):
    #@@requirement_types, @@tracker_mapping (:rt_prefix=> {:tr_name, :trid})
    @@tracker_mapping = create_all_trackers_and_update_mapping(@@tracker_mapping)
    # add all needed attributes as custom fields
    # new attributes for requirements (Key is the ID): #@@attributes
    #new attributes for requirements - remapped to key = :project+:attrlabel+:status (or without :project):
    @@known_attributes = create_all_customfields(attributes_mapping, @@attributes, @@known_attributes, @@tracker_mapping)
    # new projects:
    create_all_projects(@@some_projects, @@tracker_mapping, @@rpusers)
    # now import all issues from each ReqPro project 
    @rp_req_unique_names = create_all_issues(@@some_projects, @@requirement_types, @@attributes, @@known_attributes, @@rpusers, update_allowed)
    # update parents
    puts "Wait for update parents" if @debug
    update_issue_parents(@rp_req_unique_names)
    #TODO update internal traces 
    #TODO update external traces
    @import_results = @@import_results #for view
    @progress_percent = [100, 100]
  end
  
  def match_org
    # Delete existing iip to ensure there can't be two iips for a user
    ReqproimportInProgress.delete_all(["user_id = ?",User.current.id])
    # save import-in-progress data
    iip = ReqproimportInProgress.find_or_create_by_user_id(User.current.id)
    iip.quote_char = params[:wrapper]
    iip.col_sep = params[:splitter]
    iip.encoding = params[:encoding]
    iip.created = Time.new
    iip.csv_data = params[:file].read
    iip.save
    
    # Put the timestamp in the params to detect
    # users with two imports in progress
    @reqproimport_timestamp = iip.created.strftime("%Y-%m-%d %H:%M:%S")
    @original_filename = params[:file].original_filename
    
    # display sample
    sample_count = 5
    i = 0
    @samples = []
    
    FasterCSV.new(iip.csv_data, {:headers=>true,
    :encoding=>iip.encoding, :quote_char=>iip.quote_char, :col_sep=>iip.col_sep}).each do |row|
      @samples[i] = row
     
      i += 1
      if i >= sample_count
        break
      end
    end # do
    
    if @samples.size > 0
      @headers = @samples[0].headers
    end
    
    # fields
    @attrs = Array.new
    ISSUE_ATTRS.each do |attr|
      #@attrs.push([l_has_string?("field_#{attr}".to_sym) ? l("field_#{attr}".to_sym) : attr.to_s.humanize, attr])
      @attrs.push([l_or_humanize(attr, :prefix=>"field_"), attr])
    end
    @project.all_issue_custom_fields.each do |cfield|
      @attrs.push([cfield.name, cfield.name])
    end
    IssueRelation::TYPES.each_pair do |rtype, rinfo|
      @attrs.push([l_or_humanize(rinfo[:name]),rtype])
    end
    @attrs.sort!
  end
  
  # Returns the issue object associated with the given value of the given attribute.
  # Raises NoIssueForUniqueValue if not found or MultipleIssuesForUniqueValue
  def issue_for_unique_attr(unique_attr, attr_value)
    if @issue_by_unique_attr.has_key?(attr_value)
      return @issue_by_unique_attr[attr_value]
    end
    if unique_attr == "id"
      issues = [Issue.find_by_id(attr_value)]
    else
      query = Query.new(:name => "_reqproimporter", :project => @project)
      query.add_filter("status_id", "*", [1])
      query.add_filter(unique_attr, "=", [attr_value])

      issues = Issue.find :all, :conditions => query.statement, :limit => 2, :include => [ :assigned_to, :status, :tracker, :project, :priority, :category, :fixed_version ]
    end
    
    if issues.size > 1
      flash[:warning] = "Unique field #{unique_attr}  with value '#{attr_value}' has duplicate record"
      @failed_count += 1
      @failed_issues[@handle_count + 1] = row
      raise MultipleIssuesForUniqueValue, "Unique field #{unique_attr}  with value '#{attr_value}' has duplicate record"
    else
      if issues.size == 0
        raise NoIssueForUniqueValue, "No issue with #{unique_attr} of '#{attr_value}' found"
      end
      issues.first
    end
  end

  def result_org
    @handle_count = 0
    @update_count = 0
    @skip_count = 0
    @failed_count = 0
    @failed_issues = Hash.new
    @affect_projects_issues = Hash.new
    # This is a cache of previously inserted issues indexed by the value
    # the user provided in the unique column
    @issue_by_unique_attr = Hash.new
    
    # Retrieve saved import data
    iip = ReqproimportInProgress.find_by_user_id(User.current.id)
    if iip == nil
      flash[:error] = "No reqproimport is currently in progress"
      return
    end
    if iip.created.strftime("%Y-%m-%d %H:%M:%S") != params[:reqproimport_timestamp]
      flash[:error] = "You seem to have started another reqproimport " \
          "since starting this one. " \
          "This reqproimport cannot be completed"
      return
    end
    
    default_tracker = params[:default_tracker]
    update_issue = params[:update_issue]
    unique_field = params[:unique_field].empty? ? nil : params[:unique_field]
    journal_field = params[:journal_field]
    update_other_project = params[:update_other_project]
    ignore_non_exist = params[:ignore_non_exist]
    fields_map = params[:fields_map]
    send_emails = params[:send_emails]
    add_categories = params[:add_categories]
    add_versions = params[:add_versions]
    unique_attr = fields_map[unique_field]
    unique_attr_checked = false  # Used to optimize some work that has to happen inside the loop   

    # attrs_map is fields_map's invert
    attrs_map = fields_map.invert

    # check params
    unique_error = nil
    if update_issue
      unique_error = l(:text_rmi_specify_unique_field_for_update)
    elsif attrs_map["parent_issue"] != nil
      unique_error = l(:text_rmi_specify_unique_field_for_column,:column => l(:field_parent_issue))
    else
      IssueRelation::TYPES.each_key do |rtype|
        if attrs_map[rtype]
          unique_error = l(:text_rmi_specify_unique_field_for_column,:column => l("label_#{rtype}".to_sym))
          break
        end
      end
    end
    if unique_error && unique_attr == nil
      flash[:error] = unique_error
      return
    end

    FasterCSV.new(iip.csv_data, {:headers=>true, :encoding=>iip.encoding, 
        :quote_char=>iip.quote_char, :col_sep=>iip.col_sep}).each do |row|

      project = Project.find_by_name(row[attrs_map["project"]])
      if !project
        project = @project
      end
      tracker = Tracker.find_by_name(row[attrs_map["tracker"]])
      status = IssueStatus.find_by_name(row[attrs_map["status"]])
      author = attrs_map["author"] ? User.find_by_login(row[attrs_map["author"]]) : User.current
      priority = Enumeration.find_by_name(row[attrs_map["priority"]])
      category_name = row[attrs_map["category"]]
      category = IssueCategory.find_by_name(category_name)
      if (!category) && category_name && category_name.length > 0 && add_categories
        category = project.issue_categories.build(:name => category_name)
        category.save
      end
      assigned_to = row[attrs_map["assigned_to"]] != nil ? User.find_by_login(row[attrs_map["assigned_to"]]) : nil
      fixed_version_name = row[attrs_map["fixed_version"]]
      fixed_version = Version.find_by_name(fixed_version_name)
      if (!fixed_version) && fixed_version_name && fixed_version_name.length > 0 && add_versions
        fixed_version = project.versions.build(:name=>fixed_version_name)
        fixed_version.save
      end
      watchers = row[attrs_map["watchers"]]
      # new issue or find exists one
      issue = Issue.new
      journal = nil
      issue.project_id = project != nil ? project.id : @project.id
      issue.tracker_id = tracker != nil ? tracker.id : default_tracker
      issue.author_id = author != nil ? author.id : User.current.id

      # trnaslate unique_attr if it's a custom field -- only on the first issue
      if !unique_attr_checked
        if unique_field && !ISSUE_ATTRS.include?(unique_attr.to_sym)
          issue.available_custom_fields.each do |cf|
            if cf.name == unique_attr
              unique_attr = "cf_#{cf.id}"
              break
            end
          end
        end
        unique_attr_checked = true
      end

      if update_issue
        begin
          issue = issue_for_unique_attr(unique_attr,row[unique_field])
          
          # ignore other project's issue or not
          if issue.project_id != @project.id && !update_other_project
            @skip_count += 1
            next
          end
          
          # ignore closed issue except reopen
          if issue.status.is_closed?
            if status == nil || status.is_closed?
              @skip_count += 1
              next
            end
          end
          
          # init journal
          note = row[journal_field] || ''
          journal = issue.init_journal(author || User.current, 
            note || '')
            
          @update_count += 1
          
        rescue NoIssueForUniqueValue
          if ignore_non_exist
            @skip_count += 1
            next
          end
          
        rescue MultipleIssuesForUniqueValue
          break
        end
      end
    
      # project affect
      if project == nil
        project = Project.find_by_id(issue.project_id)
      end
      @affect_projects_issues.has_key?(project.name) ?
        @affect_projects_issues[project.name] += 1 : @affect_projects_issues[project.name] = 1

      # required attributes
      issue.status_id = status != nil ? status.id : issue.status_id
      issue.priority_id = priority != nil ? priority.id : issue.priority_id
      issue.subject = row[attrs_map["subject"]] || issue.subject
      
      # optional attributes
      issue.description = row[attrs_map["description"]] || issue.description
      issue.category_id = category != nil ? category.id : issue.category_id
      issue.start_date = row[attrs_map["start_date"]] || issue.start_date
      issue.due_date = row[attrs_map["due_date"]] || issue.due_date
      issue.assigned_to_id = assigned_to != nil ? assigned_to.id : issue.assigned_to_id
      issue.fixed_version_id = fixed_version != nil ? fixed_version.id : issue.fixed_version_id
      issue.done_ratio = row[attrs_map["done_ratio"]] || issue.done_ratio
      issue.estimated_hours = row[attrs_map["estimated_hours"]] || issue.estimated_hours

      # parent issues
      begin
        if row[attrs_map["parent_issue"]] != nil
          issue.parent_issue_id = issue_for_unique_attr(unique_attr,row[attrs_map["parent_issue"]]).id
        end
      rescue NoIssueForUniqueValue
        if ignore_non_exist
          @skip_count += 1
          next
        end
      rescue MultipleIssuesForUniqueValue
        break
      end

      # custom fields
      issue.custom_field_values = issue.available_custom_fields.inject({}) do |h, c|
        if value = row[attrs_map[c.name]]
          h[c.id] = value
        end
        h
      end
      
      # watchers
      if watchers
        addable_watcher_users = issue.addable_watcher_users
        watchers.split(',').each do |watcher|
          watcher_user = User.find_by_login(watcher)
          if (!watcher_user) || (issue.watcher_users.include?(watcher_user))
            next
          end
          if addable_watcher_users.include?(watcher_user)
            issue.add_watcher(watcher_user)
          end
        end
      end

      if (!issue.save)
        # 
        @failed_count += 1
        @failed_issues[@handle_count + 1] = row
      else
        if unique_field
          @issue_by_unique_attr[row[unique_field]] = issue
        end
        
        if send_emails
          if update_issue
            if Setting.notified_events.include?('issue_updated')
              Mailer.deliver_issue_edit(issue.current_journal)
            end
          else
            if Setting.notified_events.include?('issue_added')
              Mailer.deliver_issue_add(issue)
            end
          end
        end

        # Issue relations
        begin
          IssueRelation::TYPES.each_pair do |rtype, rinfo|
            if !row[attrs_map[rtype]]
              next
            end
            other_issue = issue_for_unique_attr(unique_attr,row[attrs_map[rtype]])
            relations = issue.relations.select { |r| (r.other_issue(issue).id == other_issue.id) && (r.relation_type_for(issue) == rtype) }
            if relations.length == 0
              relation = IssueRelation.new( :issue_from => issue, :issue_to => other_issue, :relation_type => rtype )
              relation.save
            end
          end
        rescue NoIssueForUniqueValue
          if ignore_non_exist
            @skip_count += 1
            next
          end
        rescue MultipleIssuesForUniqueValue
          break
        end
      end
  
      if journal
        journal
      end
      
      @handle_count += 1
    end # do
    
    if @failed_issues.size > 0
      @failed_issues = @failed_issues.sort
      @headers = @failed_issues[0][1].headers
    end
    
    # Clean up after ourselves
    iip.delete
    
    # Garbage prevention: clean up iips older than 3 days
    ReqproimportInProgress.delete_all(["created < ?",Time.new - 3*24*60*60])
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
  
  def set_attributes_mapping(attributes_map)
    attributes_mapping = Hash.new
    if attributes_map != nil
      attributes_map.each do |reqproattr_prefix,attr_name|
        if attr_name != ""
          attributes_mapping[reqproattr_prefix]=Hash.new
          #attributes_mapping[reqproattr_prefix][:attr_name]=attr_name.gsub(/[^\w\s\'\-]/,"_") # replace all non ok characters with "_"
          attributes_mapping[reqproattr_prefix][:attr_name]=attr_name
        end 
      end
    end
    return attributes_mapping
  end
  
  # create new redmine users from rp-users
  def create_all_users_and_update(rp_users)
    # looking for existend users because while importing multiple projects
    # can cause double users which will cause an error while save the user
    if rp_users != nil
      rp_users.each do |rp_key, rp_user|
        new_user = rp_user[:rmuser]
        if new_user != nil
          puts "User already exist: " + new_user[:mail]  + " -> " + rp_user[:email] if @debug
          next
        end
        new_user = User.find_by_mail(rp_user[:email])
        if new_user != nil
          puts "User found via mail: " + new_user[:mail]  + " -> " + rp_user[:email] if @debug
          rp_user[:rmuser] = new_user # update mapping
          next
        end
        new_user = User.find_by_login(rp_user[:login])
        if new_user != nil
          puts "User found via login: " + new_user[:mail]  + " -> " + rp_user[:email] if @debug
          rp_user[:rmuser] = new_user # update mapping
          next
        end
        new_user = User.new
        new_user[:mail] = rp_user[:email]
        new_user[:login] = rp_user[:login]
        new_user[:lastname] = rp_user[:lastname] || rp_user[:login] || rp_user[:firstname]
        new_user[:firstname] = rp_user[:firstname] || rp_user[:lastname] || rp_user[:login] 
        if new_user.save    
          @@import_results[:imported][:users] += 1
          rp_user[:rmuser] = new_user # update mapping
        else
          @@import_results[:failed][:users] += 1
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
      tracker = Tracker.find(:all, :conditions => ["name=?", tr_value[:tr_name]])[0]
      if tracker == nil
        tracker = Tracker.create(:name=>tr_value[:tr_name], :is_in_roadmap=>"1")
        if tracker != nil    
          @@import_results[:imported][:trackers] += 1
        else
          @@import_results[:failed][:trackers] += 1
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
        tracker_mapping[rt_prefix][:trid] = tracker[:id]
      else
        puts "Tracker already exist: " + tr_value[:tr_name]  + "->" + rt_prefix if @debug
      end
      tracker_mapping[rt_prefix][:trid] = tracker[:id]
    end
    return tracker_mapping
  end
  
  def create_all_customfields(attributes_mapping, attributes, known_attributes, tracker_mapping)
    if attributes != nil and !attributes_mapping.empty?
      fieldformat_mapping = {"Text" => "string", "MultiSelect" => "list", "List"=>"list", "Integer"=>"int", "Real"=>"float", "Date"=>"date"}
      attributes.each do |key,attri|
        # check for "custom field" or "redmine attribute" is already existend
        newkey = attri[:mapping]
        if !known_attributes.include?(newkey) and !known_attributes.include?(newkey.gsub(/[^\w\s\'\-]/,"_"))
          # not known --> create a custom field for this attribute
          new_issue_custom_field = IssueCustomField.new 
          # --> .gsub(/[^\w\s\'\-]/,"_") # replace all non ok characters with "_"
          new_issue_custom_field.name = newkey.gsub(/[^\w\s\'\-]/,"_")
          new_issue_custom_field.field_format = fieldformat_mapping[attri[:datatype]]
          new_issue_custom_field.default_value = attri[:default]
          new_issue_custom_field.min_length = "0"
          new_issue_custom_field.max_length = "0"
          new_issue_custom_field.possible_values = ""
          new_issue_custom_field.trackers = Array.new
          new_issue_custom_field.searchable = "0"
          new_issue_custom_field.is_required = "0"
          new_issue_custom_field.regexp = "" 
          new_issue_custom_field.is_for_all = "1"
          new_issue_custom_field.is_filter = "1"
          #collect some trackers which need this custom field
          if attri[:rtprefixes] != nil
            attri[:rtprefixes].each do |prefix|
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
            new_issue_custom_field.possible_values = attri[:itemlist]
            new_issue_custom_field.searchable = "1"
          else
            # handle the rest as "string"
            new_issue_custom_field.field_format = "string"
            new_issue_custom_field.possible_values = attri[:itemlist].to_s + attri[:itemtext]
            new_issue_custom_field.searchable = "1"            
          end
          if (new_issue_custom_field.save)
            known_attributes[newkey] = Hash.new
            known_attributes[newkey][:custom_field_id] = new_issue_custom_field[:id] 
            @@import_results[:imported][:attributes] += 1
          else
            @@import_results[:failed][:attributes] += 1
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
              list_elements.push(attri[:itemlist]) #add new element
              list_elements.flatten!
              list_elements.uniq!
              isc_changed = true
            end
            #collect some further trackers which need this custom field
            if attri[:rtprefixes] != nil
              isc_changed = true
              attri[:rtprefixes].each do |prefix|
                tracker = Tracker.find_by_id(tracker_mapping[prefix][:trid])
                issue_custom_field.trackers.push(tracker)
                issue_custom_field.trackers.uniq!
              end
            end
            #write it back
            if (isc_changed)
              if (issue_custom_field.save)
                @@import_results[:updated][:attributes] += 1
              else
                @@import_results[:failed][:attributes] += 1
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
        if (new_project.save) 
          @@import_results[:imported][:projects] += 1
          # 3. users
          update_project_members_with_roles(new_project, rpusers, a_project[:author_rpid])         
        else
          @@import_results[:failed][:projects] += 1
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
          @@import_results[:updated][:projects] += 1
          update_project_members_with_roles(new_project, rpusers, a_project[:author_rpid])  
        else
          @@import_results[:failed][:projects] += 1
          debugger
          puts "Unable to update project" + a_project[:name]
          debugger
        end
      end
    end
  end
  
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
                  puts "Unable to save project member: " + rmproject[:identifier] + ", login:  " + rmuser[:login]
                  debugger
                  return false
                end
              else
                puts "Member already exist: " + rmuser[:login] if @debug
              end
            else
              debugger
              puts "Requested user not found: " + a_rpuser[:user_id]
              debugger
              return false
            end
          end
        else
          debugger
          #TODO: bug#11155: Mapping to a user which is not inside rp project but exist already within redmine niO
          # this bug was not reproducable
          puts "User without project found: " + a_rpuser[:login]
          debugger
        end
      end
    end
    return true
  end
  
  #find member in actual project using name string in an attribute
  #1.) looking for name string inside rpusers
  #2.) looking for rpuser inside redmine users
  #3.) looking for membership inside the actual project
  def find_project_rpmember(value, rpusers, project)
    found_user = find_user_by_string(value, rpusers) 
    #check for members of project
    if found_user != nil
      if Member.find(:all, :conditions => { :user_id => found_user[:id], :project_id => project.id })[0] == nil
        puts "This user is not member of the project: " + found_user[:login] + "<-->" + project[:identifier] if @debug
        found_user = nil # force user to nil because he is not allowed at this project
      end
    end
    return found_user
  end
  
  def update_attribute_or_custom_field_with_value(new_issue, mapping, customfield_id, value, rpusers, project)
    # check for customfield id to update
    # if not a custom field, update the existend attribute
    # if the existend attribute deal with a user --> check the project members for this user
    if customfield_id != ""
      #"custom_field_values"=>{"1"=>"ein text", "2"=>"15"}
      if new_issue.custom_field_values == nil
        new_issue.custom_field_values = Hash.new
      end
      if value.to_s != ""
        new_issue.custom_field_values = {customfield_id.to_s => value.to_s}
      end
    else
      case mapping
      when l_or_humanize(:assigned_to, :prefix=>"field_")
        new_issue.assigned_to = find_project_rpmember(value, rpusers, project)
      when l_or_humanize(:author, :prefix=>"field_")
        new_issue.author = find_project_rpmember(value, rpusers, project)
      when l_or_humanize(:watchers, :prefix=>"field_")
        new_issue.watchers = find_project_rpmember(value, rpusers, project)
      when l_or_humanize(:category, :prefix=>"field_")
        new_issue.category = IssueCategory.find_by_name(value) || new_issue.category
      when l_or_humanize(:priority, :prefix=>"field_")
        new_issue.priority = IssuePriority.find_by_name(value)||IssuePriority.default
      when l_or_humanize(:status, :prefix=>"field_")
        new_issue.status = IssueStatus.find_by_name(value)||IssueStatus.default
      when l_or_humanize(:start_date, :prefix=>"field_")
        new_issue.start_date = Time.at(value.to_i).strftime("%F")
      when l_or_humanize(:due_date, :prefix=>"field_")
        new_issue.due_date = Time.at(value.to_i).strftime("%F")
      when l_or_humanize(:done_ratio, :prefix=>"field_")
        value = 0 if value.to_i < 0
        new_issue.done_ratio = [value.to_i, 100].min
      when l_or_humanize(:estimated_hours, :prefix=>"field_")
        new_issue.estimated_hours = value
      else
        #
      end
    end
    return new_issue
  end
  
  # create all issues by importing requirements from each project
  # generate "rp_req_unique_names" list for further using (parent-child-import)
  def create_all_issues(some_projects, requirement_types, attributes, known_attributes, rpusers, update_allowed)
    rp_req_unique_names = Hash.new
    some_projects.each_value do |a_project|
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
          test_issue.subject = ic.iconv(req.elements["RName"].text)
          # looking for ReqTyp ==> Tracker
          req_type = req.elements["RTID"].text
          if !(requirement_types.include?(req_type))
            puts "Issue will not be imported - needed Requirement Type was not imported: " + test_issue.project[:identifier] + ":" + req_type + ":" + test_issue.subject if @debug
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
          #further issue parameters
          # don't use a "." to join "prefix" and "RPre"!
          unique_name = a_project[:prefix] + "|" + req.elements["RPre"].text
          new_issue.description = "ReqPro-Prefix: " + unique_name + "\n\n" + ic.iconv(req.elements["RText"].text)
          new_issue.status = IssueStatus.default
          new_issue.priority = IssuePriority.default
          new_issue.category = IssueCategory.find(:all)[0]
          new_issue.author = User.current
          new_issue.done_ratio = 0
          if attributes != nil
            # import attributes:
            if req.elements["FVs"] != nil
              req.elements["FVs"].each do |fv|
                if fv != nil #not empty
                  hash_key = fv.elements["FGUID"].text
                  value = fv.elements["FTxt"].text
                  if attributes[hash_key] != nil
                    # import this attribute value
                    new_issue = update_attribute_or_custom_field_with_value(new_issue, attributes[hash_key][:mapping], 
                                  known_attributes[attributes[hash_key][:mapping]][:custom_field_id], value, rpusers, project)
                  end
                end
              end
            end
            if req.elements["LVs"] != nil
              req.elements["LVs"].each do |lv|
                if lv != nil #not empty
                  hash_key = lv.elements["UDF"].text
                  value = lv.elements["LITxt"].text
                  if attributes[hash_key] != nil
                    # import this attribute value
                    puts "attribute with list element to update" if @debug
                    new_issue = update_attribute_or_custom_field_with_value(new_issue, attributes[hash_key][:mapping], 
                                  known_attributes[attributes[hash_key][:mapping]][:custom_field_id], value, rpusers, project)
                  end
                end
              end
            end
          end
          # attention! "due date" must be the same or greater than "start date"!
          # "start date" its allowed to be "nil"
          if new_issue.start_date != nil and new_issue.due_date != nil
            if (new_issue.start_date.to_time > new_issue.due_date.to_time)
              new_issue.start_date = new_issue.due_date
            end
          end
          # try to save
          #TODO: new_issue.save force "assigned_to" to a user (only while first save), how and why?
          user_before = new_issue.assigned_to # workarround step 1 for "assigned_to" bug
          if !(new_issue.save)
            @@import_results[:failed][:issues] += 1
            debugger
            puts "Failed to save new issue"
            debugger
            next #take next requirement
          end
          # workarround step 2 for "assigned_to"
          if user_before != new_issue.assigned_to
            puts "Assignee changed while saving! --> Force reset" if @debug
            new_issue.assigned_to = user_before
            if !new_issue.save
              debugger
              puts "Failed to save new issue at second save"
              debugger
              next #take next requirement
            end
          end
          # workarround check for "assigned_to"
          if user_before != new_issue.assigned_to
            debugger
            puts "Assignee changed while saving again!"
            debugger
          end
          if (import_new_issue)
            a_project[:imported_issues] += 1
            @@import_results[:imported][:issues] += 1
            rp_req_unique_names[unique_name.downcase] = new_issue[:id]
          else
            @@import_results[:updated][:issues] += 1
          end
        end
      end
    end
    return rp_req_unique_names    
  end

  def find_project
    @project = Project.find(params[:project_id])
  end
  
end
