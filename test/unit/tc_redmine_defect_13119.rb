require File.dirname(__FILE__) + '/../test_helper_for_redmine_defects.rb'

class TcRedmineDefect13119 < ActiveSupport::TestCase
  #http://www.redmine.org/issues/13119
  
  def test_for_defect_13119_badcase1
    th=TestHelperForRedmineDefects.new()
    new_tracker = th.create_tracker("Tracker13119")
    #create the custom field for the project (optional)
    new_project_custom_field = th.create_project_custom_field("RPUID_for_bugfixtest")
    assert_not_nil(new_project_custom_field, "new_project_custom_field not saved correctly!")
    new_project = th.create_project("pft", "Project for test defect 13119", Tracker.find(:all), new_project_custom_field)
    assert_not_nil(new_project, "new_project not saved correctly!")
    new_user = th.create_user("Login13119")
    assert_not_nil(new_user, "new_user not saved correctly!")
    new_issue = th.create_issue("Issue for test the defect 13119", new_tracker, new_project, new_user)
    assert_not_nil(new_issue, "new_issue not saved correctly!")
    #create the custom field for the issue
    new_issue_custom_field = th.create_issue_custom_field("RPUID_for_bugfixtest", "string", new_issue)
    assert_not_nil(new_issue_custom_field, "new_issue_custom_field not saved correctly!")
    #set the value
    the_value = "RPUID"
    new_issue.custom_field_values={new_issue_custom_field.id => the_value}
    new_issue.custom_values
    new_issue.save_custom_field_values
    #make the test
    assert_equal(true, !new_issue.custom_values.empty?, "bug found: http://www.redmine.org/issues/13119")
    cu_fi_val = new_issue.custom_field_values.detect {|cfv| cfv.custom_field == new_issue_custom_field}
    assert_equal(the_value, cu_fi_val.value, "Something went wrong for the value!")
  end
  
  def test_for_defect_13119_badcase2
    th=TestHelperForRedmineDefects.new()
    new_tracker = th.create_tracker("Tracker13119")
    #create the custom field for the project (optional)
    new_project_custom_field = th.create_project_custom_field("RPUID_for_bugfixtest")
    assert_not_nil(new_project_custom_field, "new_project_custom_field not saved correctly!")
    new_project = th.create_project("pft", "Project for test defect 13119", Tracker.find(:all), new_project_custom_field)
    assert_not_nil(new_project, "new_project not saved correctly!")
    new_user = th.create_user("Login13119")
    assert_not_nil(new_user, "new_user not saved correctly!")
    new_issue = th.create_issue("Issue for test the defect 13119", new_tracker, new_project, new_user)
    assert_not_nil(new_issue, "new_issue not saved correctly!")
    #create the custom field for the issue
    new_issue_custom_field = th.create_issue_custom_field("RPUID_for_bugfixtest", "string", new_issue)
    assert_not_nil(new_issue_custom_field, "new_issue_custom_field not saved correctly!")
    #set the value
    the_value = "RPUID"
    new_issue.custom_field_values={new_issue_custom_field.id => the_value}
    new_issue.save_custom_field_values
    new_issue.custom_values
    #make the test
    assert_equal(true, !new_issue.custom_values.empty?, "bug found: http://www.redmine.org/issues/13119")
    cu_fi_val = new_issue.custom_field_values.detect {|cfv| cfv.custom_field == new_issue_custom_field}
    assert_equal(the_value, cu_fi_val.value, "Something went wrong for the value!")
  end
  
  def test_for_defect_13119_goodcase1
    th=TestHelperForRedmineDefects.new()
    new_tracker = th.create_tracker("Tracker13119")
    #create the custom field for the project (optional)
    new_project_custom_field = th.create_project_custom_field("RPUID_for_bugfixtest")
    assert_not_nil(new_project_custom_field, "new_project_custom_field not saved correctly!")
    new_project = th.create_project("pft", "Project for test defect 13119", Tracker.find(:all), new_project_custom_field)
    assert_not_nil(new_project, "new_project not saved correctly!")
    new_user = th.create_user("Login13119")
    assert_not_nil(new_user, "new_user not saved correctly!")
    new_issue = th.create_issue("Issue for test the defect 13119", new_tracker, new_project, new_user)
    assert_not_nil(new_issue, "new_issue not saved correctly!")
    #create the custom field for the issue
    new_issue_custom_field = th.create_issue_custom_field("RPUID_for_bugfixtest", "string", new_issue)
    assert_not_nil(new_issue_custom_field, "new_issue_custom_field not saved correctly!")
    #set the value
    new_issue.reset_custom_values!
    the_value = "RPUID"
    new_issue.custom_field_values={new_issue_custom_field.id => the_value}
    new_issue.custom_values
    new_issue.save_custom_field_values
    #make the test
    assert_equal(true, !new_issue.custom_values.empty?, "bug found: http://www.redmine.org/issues/13119")
    cu_fi_val = new_issue.custom_field_values.detect {|cfv| cfv.custom_field == new_issue_custom_field}
    assert_equal(the_value, cu_fi_val.value, "Something went wrong for the value!")
  end
  
  def test_for_defect_13119_goodcase2
    th=TestHelperForRedmineDefects.new()
    new_tracker = th.create_tracker("Tracker13119")
    #create the custom field for the project (optional)
    new_project_custom_field = th.create_project_custom_field("RPUID_for_bugfixtest")
    assert_not_nil(new_project_custom_field, "new_project_custom_field not saved correctly!")
    new_project = th.create_project("pft", "Project for test defect 13119", Tracker.find(:all), new_project_custom_field)
    assert_not_nil(new_project, "new_project not saved correctly!")
    new_user = th.create_user("Login13119")
    assert_not_nil(new_user, "new_user not saved correctly!")
    new_issue = th.create_issue("Issue for test the defect 13119", new_tracker, new_project, new_user)
    assert_not_nil(new_issue, "new_issue not saved correctly!")
    #create the custom field for the issue
    new_issue_custom_field = th.create_issue_custom_field("RPUID_for_bugfixtest", "string", new_issue)
    assert_not_nil(new_issue_custom_field, "new_issue_custom_field not saved correctly!")
    #set the value
    new_issue.reset_custom_values!
    the_value = "RPUID"
    new_issue.custom_field_values={new_issue_custom_field.id => the_value}
    new_issue.save_custom_field_values
    new_issue.custom_values
    #make the test
    assert_equal(true, !new_issue.custom_values.empty?, "bug found: http://www.redmine.org/issues/13119")
    cu_fi_val = new_issue.custom_field_values.detect {|cfv| cfv.custom_field == new_issue_custom_field}
    assert_equal(the_value, cu_fi_val.value, "Something went wrong for the value!")
  end
  
end