require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/../../app/helpers/requirements_issues_helper'

#gutes Beispiel: vendor/plugins/awesome_nested_set
#
# starten mit:  vendor/plugins/redmine_import_reqpro/test/unit/tc_requirements_issues_helper.rb

class HelperClassForModules
  include RequirementsIssuesHelper
  def loglevel_none
    return 0
  end
  def loglevel_medium
    return 5
  end
  def loglevel_high
    return 10
  end
end

class TcRequirementsIssuesHelper < ActiveSupport::TestCase 
  self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
  fixtures :issues, :projects, :trackers, :projects_trackers, :issue_statuses, :enumerations, :custom_fields, :custom_values
  
  def test_requirements_issues_prerequisites
    puts "test_requirements_issues_prerequisites"
    assert_equal(14,Issue.find(:all).count, "Issue nicht korrekt")
    assert_equal(3,Project.find(:all).count, "Project nicht korrekt")
    assert_equal(4,Tracker.find(:all).count, "Tracker nicht korrekt")
    assert_equal(2,IssueStatus.find(:all).count, "IssueStatus nicht korrekt")
    assert_equal(4,IssuePriority.find(:all).count, "IssuePriority nicht korrekt")
    assert_equal(4,Enumeration.find(:all).count, "Enumeration nicht korrekt")
    assert_equal(11,CustomField.find(:all).count, "CustomField nicht korrekt")
    assert_equal(23,CustomValue.find(:all).count, "CustomValue nicht korrekt")
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
    existend_issue12 = Issue.find_by_id(12)
    a_issue = Issue.new
    a_issue.tracker = existend_issue12.tracker
    a_issue.project_id = existend_issue12.project_id
    a_issue.subject = existend_issue12.subject
    a_issue.description  = existend_issue12.description
    a_issue.status_id  = existend_issue12.status_id
    a_issue.priority = existend_issue12.priority
    a_issue.author_id  = existend_issue12.author_id
    #save old value
    the_assignee_id =  a_issue.assigned_to_id
    #prepare call of private function
    HelperClassForModules.class_eval{def iswar(a,b) return issue_save_with_assignee_restore(a,b) end}
    hc=HelperClassForModules.new
    #save with myown routine and test
    a_issue = hc.iswar(a_issue,true)
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
    #prepare call of private function
    HelperClassForModules.class_eval{def spfc(a,b,c) return set_parent_from_child(a,b,c) end}
    hc=HelperClassForModules.new
    #function
    hc.spfc(rp_req_unique_names, "NEED1.1.1", hc.loglevel_high())
    hc.spfc(rp_req_unique_names, "NEED1.2", hc.loglevel_high())
    hc.spfc(rp_req_unique_names, "STRQ1.1", hc.loglevel_high())
    hc.spfc(rp_req_unique_names, "STRQ1.1.1", hc.loglevel_high())
    hc.spfc(rp_req_unique_names, "STRQ1.2", hc.loglevel_high()) #unknown id
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
    #prepare call of private function
    HelperClassForModules.class_eval{def ifbr(a) return issue_find_by_rpuid(a) end}
    hc=HelperClassForModules.new()
    #function call
    issue_11 = hc.ifbr("{01}")
    issue_nil = hc.ifbr("{01234}") #unknown rpuid
    no_issue = hc.ifbr("{20}") #wrong customized_type
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
    #prepare call
    hc=HelperClassForModules.new
    hc.update_issue_parents(rp_req_unique_names, hc.loglevel_high())
    #test
    assert_equal(Issue.find_by_id(11).parent, Issue.find_by_id(12), "Parent for NEED1.1.1 not correct!")
    assert_equal(Issue.find_by_id(12).parent, Issue.find_by_id(13), "Parent for NEED1.1 not correct!")
    assert_nil(Issue.find_by_id(13).parent, "Parent for NEED1 not empty!")
    assert_equal(Issue.find_by_id(14).parent, Issue.find_by_id(13), "Parent for NEED1.2 not correct!")
    assert_nil(Issue.find_by_id(15).parent, "Parent for STRQ1.1 not empty!") 
  end
    
end