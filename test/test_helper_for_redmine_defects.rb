# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

class TestHelperForRedmineDefects
  def create_tracker(the_name)
    new_tracker = Tracker.find_by_name(the_name)
    if new_tracker!=nil
      Tracker.find_by_id(new_tracker.id).delete
    end
    new_tracker = Tracker.create(:name=>the_name, :is_in_roadmap=>"1")
    Role.find(:all).each do |role|
      #copy workflow from first tracker:
      Workflow.copy(Tracker.find(:first), role, new_tracker, role)
    end
    return new_tracker
  end
  
  def create_project_custom_field(the_name)
    new_project_custom_field = ProjectCustomField.find_by_name(the_name)
    if new_project_custom_field != nil
      ProjectCustomField.find_by_id(new_project_custom_field.id).delete
    end
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
    if new_project_custom_field.save
      return new_project_custom_field
    else
      return nil
    end
    
  end
  
  def create_project(the_description, new_project_custom_field)
    #prepare the project
    enabled_module_names = Array.new
    EnabledModule.find(:all).each {|m| enabled_module_names.push(m[:name])}
    enabled_module_names.uniq!
    trackers = Tracker.find(:all)
    #the project itself
    new_project = Project.find_by_description(the_description)
    if new_project != nil
      Project.find_by_id(new_project.id).delete
    end      
    new_project = Project.new
    new_project.description=the_description
    new_project.identifier = "pft"
    new_project.name = "Pft name"
    new_project.trackers = trackers
    new_project.enabled_module_names = enabled_module_names
    new_project.issue_custom_field_ids= [""]
    new_project.is_public = "0"
    new_project.custom_field_values={new_project_custom_field.id => "{0815-13119}"} if new_project_custom_field != nil       
    if new_project.save
      return new_project
    else
      return nil
    end
  end
  
  def create_user(the_login)
    new_user = User.find_by_login(the_login)
    if new_user!=nil
      User.find_by_id(new_user.id).delete
    end
    new_user = User.new()
    new_user[:login] = the_login
    new_user[:mail] = "usr4test@test.de"
    new_user[:admin] = false
    new_user[:firstname] = "Firstname4Test"
    new_user[:lastname] = "Lastname4Test"
    if new_user.save
      return new_user
    else
      return nil
    end
  end
  
  def create_issue(the_subject, new_tracker, new_project, new_user)
    new_issue = Issue.find_by_subject(the_subject)
    if new_issue != nil
      Issue.find_by_id(new_issue.id).delete
    end
    new_issue = Issue.new
    new_issue.subject = the_subject
    new_issue.description = "Issue for test of an defect."
    new_issue.status = IssueStatus.default
    new_issue.priority = IssuePriority.default
    new_issue.category = IssueCategory.find(:all)[0]
    new_issue.author = new_user #User.current --> problems with anonymous user
    new_issue.done_ratio = 0
    new_issue.project = new_project
    new_issue.tracker = new_tracker
    if new_issue.save
      return new_issue
    else
      return nil
    end
  end
  
  def create_issue_custom_field(the_name, new_issue)
    new_issue_custom_field = IssueCustomField.find_by_name(the_name)
    if new_issue_custom_field != nil
      IssueCustomField.find_by_id(new_issue_custom_field.id).delete
    end
    new_issue_custom_field = IssueCustomField.new 
    new_issue_custom_field.name = the_name
    new_issue_custom_field.field_format = "string"
    new_issue_custom_field.default_value = ""
    new_issue_custom_field.min_length = "0"
    new_issue_custom_field.max_length = "0"
    new_issue_custom_field.possible_values = ""
    new_issue_custom_field.trackers = Array.new
    new_issue_custom_field.searchable = "1"
    new_issue_custom_field.is_required = "0"
    new_issue_custom_field.regexp = ""
    new_issue_custom_field.is_for_all = "0"
    new_issue_custom_field.is_filter = "1"
    return nil if !new_issue_custom_field.save
    if !new_issue_custom_field.trackers.include?(new_issue.tracker)
      new_issue_custom_field.trackers.push(new_issue.tracker)
      return nil if !new_issue_custom_field.save
    end
    if !new_issue_custom_field.projects.include?(new_issue.project)
      new_issue_custom_field.projects.push(new_issue.project)
      return nil if !new_issue_custom_field.save
    end
    return new_issue_custom_field
  end
end