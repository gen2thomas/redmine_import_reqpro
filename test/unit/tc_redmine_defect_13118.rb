require File.dirname(__FILE__) + '/../test_helper_for_redmine_defects.rb'

class TcRedmineDefect13118 < ActiveSupport::TestCase
  #http://www.redmine.org/issues/13118
  
  def test_for_defect_13118_badcase1
    th=TestHelperForRedmineDefects.new()
    new_project = th.create_project("pft1", "Project for test defect 13118", nil, nil)
    new_tracker=th.create_tracker("Tracker4Test13118")
    #add the requested tracker to the requested project
    if !new_project.trackers.include?(new_tracker)
      new_project.trackers.push(new_tracker)
    end
    new_user=th.create_user("usr4defect13118", "usr4test@test.de")
    new_issue=th.create_issue("issue4defect13118",new_tracker,new_project,new_user)
    a_issue_custom_field1=th.create_issue_custom_field("EffortRemaining2","int",new_issue)
    new_issue = update_custom_value_in_issue_intern1(new_issue, a_issue_custom_field1, "1.0")
    new_issue.save    
    # import attribute 2
    a_issue_custom_field=th.create_issue_custom_field("Difficulty2","string",new_issue)
    new_issue = update_custom_value_in_issue_intern1(new_issue, a_issue_custom_field, "Medium")
    new_issue.save
  end
  
  def test_for_defect_13118_badcase2
      th=TestHelperForRedmineDefects.new()
      new_project = th.create_project("pft1", "Project for test defect 13118", nil, nil)
      new_tracker=th.create_tracker("Tracker4Test13118")
      #add the requested tracker to the requested project
      if !new_project.trackers.include?(new_tracker)
        new_project.trackers.push(new_tracker)
      end
      new_user=th.create_user("usr4defect13118", "usr4test@test.de")
      new_issue=th.create_issue("issue4defect13118",new_tracker,new_project,new_user)
      a_issue_custom_field1=th.create_issue_custom_field("EffortRemaining2","int",new_issue)
      new_issue = update_custom_value_in_issue_intern2(new_issue, a_issue_custom_field1, "1.0")
      new_issue.save    
      # import attribute 2
      a_issue_custom_field=th.create_issue_custom_field("Difficulty2","string",new_issue)
      new_issue = update_custom_value_in_issue_intern2(new_issue, a_issue_custom_field, "Medium")
      new_issue.save
    end
  
  def test_for_defect_13118_goodcase
      th=TestHelperForRedmineDefects.new()
      new_project = th.create_project("pft1", "Project for test defect 13118", nil, nil)
      new_tracker=th.create_tracker("Tracker4Test13118")
      #add the requested tracker to the requested project
      if !new_project.trackers.include?(new_tracker)
        new_project.trackers.push(new_tracker)
      end
      new_user=th.create_user("usr4defect13118", "usr4test@test.de")
      new_issue=th.create_issue("issue4defect13118",new_tracker,new_project,new_user)
      a_issue_custom_field1=th.create_issue_custom_field("EffortRemaining2","int",new_issue)
      new_issue = update_custom_value_in_issue_intern1(new_issue, a_issue_custom_field1, "1.0")
      new_issue.save
      new_issue.reload #this save the day
      # import attribute 2
      a_issue_custom_field=th.create_issue_custom_field("Difficulty2","string",new_issue)
      new_issue = update_custom_value_in_issue_intern1(new_issue, a_issue_custom_field, "Medium")
      new_issue.save
    end
  
private

  def update_custom_value_in_issue_intern1(a_issue, a_custom_field, the_value)
    #against bug in redmine that sometimes the array a_issue.custom_field_values is empty (or old) but not nil
    #see http://www.redmine.org/issues/13119
    a_issue.reset_custom_values!
    a_issue.save_custom_field_values
    cu_fi_val = a_issue.custom_field_values.detect {|cfv| cfv.custom_field == a_custom_field}
    assert_not_nil(cu_fi_val,"Found the defect 13118!")  
    cu_fi_val.value = the_value
    a_issue.save
    return a_issue
  end
  
  def update_custom_value_in_issue_intern2(a_issue, a_custom_field, the_value)
    #against bug in redmine that sometimes the array a_issue.custom_field_values is empty (or old) but not nil
    #see http://www.redmine.org/issues/13119
    a_issue.reset_custom_values!
    a_issue.save_custom_field_values
    a_issue.custom_field_values={a_custom_field.id => the_value}
    a_issue.save_custom_field_values
    cu_fi_val = a_issue.custom_field_values.detect {|cfv| cfv.custom_field == a_custom_field}
    assert_not_nil(cu_fi_val,"Found the defect 13118!")  
    return a_issue
  end
   
end