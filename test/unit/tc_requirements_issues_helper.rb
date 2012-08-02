require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/../../app/helpers/requirements_issues_helper'

include RequirementsIssuesHelper

#gutes Beispiel: vendor/plugins/awesome_nested_set
#
# starten mit:  vendor/plugins/redmine_import_reqpro/test/unit/tc_requirements_issues_helper.rb

class TcRequirementsIssuesHelper < ActiveSupport::TestCase 
  self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
  fixtures :issues, :projects, :trackers, :projects_trackers, :issue_statuses, :enumerations, :custom_fields, :custom_values
  
  def test_issue_prerequisites
    puts "test_issue_prerequisites"
    assert_equal(8,Issue.find(:all).count, "Issue nicht korrekt")
    assert_equal(2,Project.find(:all).count, "Project nicht korrekt")
    assert_equal(3,Tracker.find(:all).count, "Tracker nicht korrekt")
    assert_equal(1,IssueStatus.find(:all).count, "IssueStatus nicht korrekt")
    assert_equal(4,Enumeration.find(:all).count, "Enumeration nicht korrekt")
    assert_equal(1,CustomField.find(:all).count, "CustomField nicht korrekt")
    assert_equal(12,CustomValue.find(:all).count, "CustomValue nicht korrekt")
  end
    
  def test_issue_normal_save
    puts "test_issue_normal_save"
    #prepare new issue
    a_issue = Issue.new    
    a_issue.tracker_id = issues(:issue_11).tracker_id
    a_issue.project_id = issues(:issue_11).project_id
    a_issue.subject = issues(:issue_11).subject
    a_issue.description  = issues(:issue_11).description
    a_issue.status_id  = issues(:issue_11).status_id
    a_issue.priority_id  = issues(:issue_11).priority_id
    a_issue.author_id  = issues(:issue_11).author_id
    #save old value
    the_assignee_id =  a_issue.assigned_to_id 
    #save the issue in normal way
    assert(a_issue.save, "Saving failed!")
    assert_equal(the_assignee_id, a_issue.assigned_to_id)
    assert_equal(a_issue, Issue.find_by_id(a_issue.id), "The issue content is not available!")
  end
  
  def test_issue_save_with_assignee_restore
    puts "test_issue_save_with_assignee_restore"
    #prepare new issue
    a_issue = Issue.new    
    a_issue.tracker_id = issues(:issue_12).tracker_id
    a_issue.project_id = issues(:issue_12).project_id
    a_issue.subject = issues(:issue_12).subject
    a_issue.description  = issues(:issue_12).description
    a_issue.status_id  = issues(:issue_12).status_id
    a_issue.priority_id  = issues(:issue_12).priority_id
    a_issue.author_id  = issues(:issue_12).author_id
    #save old value
    the_assignee_id =  a_issue.assigned_to_id 
    #save with myown routine and test
    a_issue = issue_save_with_assignee_restore(a_issue)
    assert(a_issue != nil, "Saving failed!")
    if a_issue != nil
      assert_equal(the_assignee_id, a_issue.assigned_to_id, "The assignee has changed!")
      assert_equal(a_issue, Issue.find_by_id(a_issue.id), "The issue content is not available!")
    end    
  end
  
  def test_set_parent_from_child
    puts "test_set_parent_from_child"
    #prepare
    Project.find(:all).each do |a_project|
      #all_trackers = Tracker.find_by_id(projects_trackers(a_project[:id]))
      a_project.trackers = Tracker.find(:all)
      a_project.issue_custom_field_ids = [""]
      a_project.save
    end
    Issue.find(:all).each do |a_issue|
      a_issue.status = IssueStatus.default if a_issue.status == nil
      a_issue.priority = IssuePriority.default if a_issue.priority == nil
      a_issue.save
    end
    rp_req_unique_names = Hash.new
    rp_req_unique_names["NEED1.1.1"] = 11
    rp_req_unique_names["NEED1.1"] = 12
    rp_req_unique_names["NEED1"] = 13
    rp_req_unique_names["NEED1.2"] = 14 #tracker not the same
    rp_req_unique_names["STRQ1.1"] = 15 #rq-type not the same
    rp_req_unique_names["STRQ1.1.1"] = 150 #issue not present in system
    #function
    set_parent_from_child(rp_req_unique_names, "NEED1.1.1", true)
    set_parent_from_child(rp_req_unique_names, "NEED1.2", true)
    set_parent_from_child(rp_req_unique_names, "STRQ1.1", true)
    set_parent_from_child(rp_req_unique_names, "STRQ1.1.1", true)
    set_parent_from_child(rp_req_unique_names, "STRQ1.2", true) #unknown id
    #test
    assert_equal(Issue.find_by_id(11).parent, Issue.find_by_id(12), "Parent for NEED1.1.1 not correct!")
    assert_equal(Issue.find_by_id(12).parent, Issue.find_by_id(13), "Parent for NEED1.1 not correct!")
    assert_equal(Issue.find_by_id(14).parent, Issue.find_by_id(13), "Parent for NEED1.2 not correct!")
    assert_nil(Issue.find_by_id(13).parent, "Parent for NEED1 not empty!")
    assert_nil(Issue.find_by_id(15).parent, "Parent for STRQ1.1 not empty!")
  end

  def test_issue_find_by_rpuid
    puts "test_issue_find_by_rpuid"
    #prepare custom fields done by fixture
    #prepare issues done by fixture
    #function call
    issue_11 = issue_find_by_rpuid("{01}", true)
    issue_nil = issue_find_by_rpuid("{01234}", true) #unknown rpuid
    no_issue = issue_find_by_rpuid("{20}", true) #wrong customized_type
    #test
    assert_equal(issue_11, Issue.find_by_id(11), "Issue 11 not found by ID!")
    assert_nil(issue_nil, "issue_nil not nil!")
    assert_nil(no_issue, "no_issue not nil!")    
  end
  
  def test_update_issue_parents
    puts "test_update_issue_parents"
    #prepare
    Project.find(:all).each do |a_project|
      #all_trackers = Tracker.find_by_id(projects_trackers(a_project[:id]))
      a_project.trackers = Tracker.find(:all)
      a_project.issue_custom_field_ids = [""]
      a_project.save
    end
    Issue.find(:all).each do |a_issue|
      a_issue.status = IssueStatus.default if a_issue.status == nil
      a_issue.priority = IssuePriority.default if a_issue.priority == nil
      a_issue.save
    end
    rp_req_unique_names = Hash.new
    rp_req_unique_names["NEED1.1.1"] = 11
    rp_req_unique_names["NEED1.1"] = 12
    rp_req_unique_names["NEED1"] = 13
    rp_req_unique_names["NEED1.2"] = 14 #tracker not the same
    rp_req_unique_names["STRQ1.1"] = 15 #rq-type not the same
    rp_req_unique_names["STRQ1.1.1"] = 150 #issue not present in system
    update_issue_parents(rp_req_unique_names, true)
    #test
    assert_equal(Issue.find_by_id(11).parent, Issue.find_by_id(12), "Parent for NEED1.1.1 not correct!")
    assert_equal(Issue.find_by_id(12).parent, Issue.find_by_id(13), "Parent for NEED1.1 not correct!")
    assert_nil(Issue.find_by_id(13).parent, "Parent for NEED1 not empty!")
    assert_equal(Issue.find_by_id(14).parent, Issue.find_by_id(13), "Parent for NEED1.2 not correct!")
    assert_nil(Issue.find_by_id(15).parent, "Parent for STRQ1.1 not empty!") 
  end
    
end