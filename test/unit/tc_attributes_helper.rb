require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/../../app/helpers/attributes_helper'
require 'mocha'


class HelperClassForModules
  include AttributesHelper
  include FilesHelper
end

class TcAttributesHelper < ActiveSupport::TestCase
  self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
  fixtures :issues, :users, :custom_values, :issue_statuses, :issue_categories
  
  def test_attributes_prerequisites
    puts "test_attributes_prerequisites"
    assert_equal(8,Issue.find(:all).count, "Issue nicht korrekt")
    assert_equal(6,User.find(:all).count, "User nicht korrekt")
    assert_equal(12,CustomValue.find(:all).count, "CustomValue nicht korrekt")
    assert_equal(2,IssueStatus.find(:all).count, "IssueStatus nicht korrekt")
    assert_equal(3,IssueCategory.find(:all).count, "IssueCategory nicht korrekt")
  end

  def test_attribute_find_by_projectid_and_attrlabel
    #attribute_find_by_projectid_and_attrlabel(attributes, projectid, label)
  end
  
  def test_create_issue_custom_field_for_rpuid
    puts "test_create_issue_custom_field_for_rpuid"
    #create_issue_custom_field_for_rpuid(the_name, debug)
  end
  
  def test_remap_listattrlabels_to_projectid
    puts "test_remap_listattrlabels_to_projectid"
    #remap_listattrlabels_to_projectid(attributes)
  end 
  
  def test_remap_noversionattributes_to_attrlabel
    puts "test_remap_noversionattributes_to_attrlabel"
    #remap_noversionattributes_to_attrlabel(attributes, versions_mapping, conflate_attributes)
  end
  
  def test_update_custom_value_in_issue
    puts "test_update_custom_value_in_issue"
    #update_custom_value_in_issue(a_issue, a_custom_field, the_value, debug)
  end
  
  def test_update_issue_custom_field
    puts "test_update_issue_custom_field"
    #update_issue_custom_field(issue_custom_field, new_tracker, new_project, debug)
  end 
  
  def test_update_attribute_or_custom_field_with_value1
    puts "test_update_attribute_or_custom_field_with_value **case1** update attribute"
    #prepare issues done by fixture
    #prepare users done by fixture
    #prepare custom fields done by fixture
    #prepare issue status done by fixture
    #prepare issue category done by fixture
    HelperClassForModules.class_eval{def l_or_humanize(a,b) return ApplicationController.l_or_humanize(a,b) end}
    #prepare call
    hc=HelperClassForModules.new
    #stub the not to test methodes
    #a_issue.assigned_to = find_project_rpmember(value, rpusers, a_issue.project, debug)
    hc.stubs(:find_project_rpmember).returns(User.find_by_id(1))
    #call methode for case custom_field_id = "" --> update attribute
    #case1 :assigned_to
    nis=hc.update_attribute_or_custom_field_with_value(Issue.find_by_id(11), "Assignee", "", "AUser", Hash.new, true)
    assert_equal(1, nis[:assigned_to_id], "Assignee nicht richtig!")
    #case2 :author
    nis=hc.update_attribute_or_custom_field_with_value(Issue.find_by_id(11), "Author", "", "AUser", Hash.new, true)
    assert_equal(1, nis[:author_id], "Autor nicht richtig!")
    #case3 :watchers
    nis=hc.update_attribute_or_custom_field_with_value(Issue.find_by_id(11), "Watchers", "", "AUser", Hash.new, true)
    assert_equal(1, nis.watchers[0].user_id, "Watchers nicht richtig!")
    #case4 :category
    nis=hc.update_attribute_or_custom_field_with_value(Issue.find_by_id(11), "Category", "", "Proj01Cat02", Hash.new, true)
    assert_equal(2, nis[:category_id], "Category nicht richtig!")
    #case5 :priority
    nis=hc.update_attribute_or_custom_field_with_value(Issue.find_by_id(11), "Priority", "", "Medium", Hash.new, true)
    assert_equal(3, nis[:priority_id], "Priority nicht richtig!")
    #case6 :status
    nis=hc.update_attribute_or_custom_field_with_value(Issue.find_by_id(11), "Status", "", "Open", Hash.new, true)
    assert_equal(2, nis[:status_id], "Status nicht richtig!")
    #case7 :start_date
    nis=hc.update_attribute_or_custom_field_with_value(Issue.find_by_id(11), "Start date", "", "01.04.2012", Hash.new, true)
    assert_equal("2012-04-01", nis[:start_date].to_s, "start_date nicht richtig!")
    #case8 :due_date
    nis=hc.update_attribute_or_custom_field_with_value(Issue.find_by_id(11), "Due date", "", "2012-04-02", Hash.new, true)
    assert_equal("2012-04-02", nis[:due_date].to_s, "due_date nicht richtig!")
    #case9 :done_ratio (must be limited to 100%)
    nis=hc.update_attribute_or_custom_field_with_value(Issue.find_by_id(11), "% Done", "", "150", Hash.new, true)
    assert_equal(100, nis[:done_ratio], "done_ratio nicht richtig!")
    #case10 :estimated_hours
    nis=hc.update_attribute_or_custom_field_with_value(Issue.find_by_id(11), "Estimated time", "", "25", Hash.new, true)
    assert_equal(25, nis[:estimated_hours], "estimated_hours nicht richtig!")
  end
  
  def test_update_attribute_or_custom_field_with_value2
    puts "test_update_attribute_or_custom_field_with_value **case2** update custom field"
    #prepare issues done by fixture
    #prepare users done by fixture
    #prepare custom fields done by fixture
    #prepare data
    #prepare data
    mth=MyTestHelper.new()
    rpus=mth.rpusers()
    #prepare call
    hc=HelperClassForModules.new
    #stub the not to test methodes
    #a_issue_custom_field = update_issue_custom_field(a_issue_custom_field, a_issue.tracker, a_issue.project, debug)
    #a_issue = update_custom_value_in_issue(a_issue, a_issue_custom_field, value, debug)
    #a_issue.assigned_to = find_project_rpmember(value, rpusers, a_issue.project, debug)
    hc.stubs(:update_issue_custom_field).returns(IssueCustomField.find_by_id(1))
    hc.stubs(:update_custom_value_in_issue).returns(Issue.find_by_id(1))
    hc.stubs(:find_project_rpmember).returns(User.find_by_id(1))
    #call methode for case custom_field_id != "" --> update custom field (simple test using mocks)
    #hc.update_attribute_or_custom_field_with_value(a_issue, mapping, "1", value, rpus, true)
    
    
  end
  
  def test_update_attributes_for_map_needing1
    #conflated case
    puts "test_update_attributes_for_map_needing **case1** conflated"
    #prepare data
    mth=MyTestHelper.new()
    ats=mth.attributes()
    vm=mth.versions_mapping()
    atmap=Hash.new
    atmap["Actual Iteration"]=Hash.new
    atmap["Actual Iteration"][:attr_name]="AnAttribute"
    #prepare call
    hc=HelperClassForModules.new()
    attrs_new=hc.update_attributes_for_map_needing(ats, vm, atmap)
    assert_equal(2, attrs_new.count, "Genau zwei Attribute sind noch übrig!")
    assert_equal("AnAttribute", attrs_new["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:mapping], "Gemapptes Attribute hat keinen :mapping-Eintrag!")
    assert_equal(nil, attrs_new["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:mapping], "Nicht gemapptes Attribute hat einen :mapping-Eintrag!")
  end
  
  def test_update_attributes_for_map_needing2
    #case not conflated
    puts "test_update_attributes_for_map_needing **case2** not conflated"
    #prepare data
    mth=MyTestHelper.new()
    ats=mth.attributes()
    vm=mth.versions_mapping()
    atmap=Hash.new
    atmap["msp_Actual Iteration"]=Hash.new
    atmap["msp_Actual Iteration"][:attr_name]="AnAttribute"
    #prepare call
    hc=HelperClassForModules.new()
    attrs_new=hc.update_attributes_for_map_needing(ats, vm, atmap)
    assert_equal(2, attrs_new.count, "Genau zwei Attribute sind noch übrig!")
    assert_equal("AnAttribute", attrs_new["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:mapping], "Gemapptes Attribute hat keinen :mapping-Eintrag!")
    assert_equal(nil, attrs_new["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:mapping], "Nicht gemapptes Attribute hat einen :mapping-Eintrag!")
  end
  
  def test_update_attributes_for_reqpro_needing
    puts "test_update_attributes_for_reqpro_needing"
    #prepare data
    mth=MyTestHelper.new()
    sop=mth.some_projects()
    ats=mth.attributes()
    #prepare call of private function
    HelperClassForModules.class_eval{def uafrn(a,b) return update_attributes_for_reqpro_needing(a,b) end}
    hc=HelperClassForModules.new()
    attrs=hc.uafrn(sop,ats)
    assert_equal(1, attrs.count, "Genau ein Attribute muss genutzt sein")
    assert_equal(nil, attrs["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:status], "Status muss geloescht sein!")
    assert_equal(nil, attrs["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:itemlist_used], ":itemlist_used muss geloescht sein!")
    assert_equal(10, attrs["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:itemlist].count, "Einträge müssen 10 sein!")    
  end
  
  def test_collect_attributes_fast
    puts "test_collect_attributes_fast"
    #prepare data
    mth=MyTestHelper.new()
    sop=mth.some_projects()
    rts=mth.requirement_types()
    #List of Attr_ID -> RT_ID,  #attrid->reqtype-key
    used_attr_list = Hash.new
    used_attr_list["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"]="{022D080E-A80B-48F4-B573-8C57DE8F3860}" #Developer
    used_attr_list["{0E8304EF-59BF-440D-9315-5E56E523A58C}"]="{5E748E74-15E9-454E-8ACD-6D263D08E00F}" #Actual Iteration
    #prepare call of private function
    HelperClassForModules.class_eval{def caf(a,b,c) return collect_attributes_fast(a,b,c) end}
    hc=HelperClassForModules.new()
    attrs=hc.caf(sop, rts, used_attr_list)
    assert_equal(2,attrs.count, "Es sollte genau 1 Attribute in der Liste stehen!")
    #attr1
    attr1=attrs["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"]
    assert_equal("",attr1[:default], ":default falsch")
    assert_equal("",attr1[:itemtext], ":itemtext falsch")
    assert_equal(7,attr1[:itemlist].count, ":itemlist count falsch") #7 Developers
    assert_equal(0,attr1[:itemlist_used].count, ":itemlist_used count falsch")
    assert_equal("Developer",attr1[:attrlabel], ":attrlabel falsch")
    assert_equal("MultiSelect",attr1[:datatype], ":datatype falsch")
    assert_equal("STP",attr1[:project], ":project falsch")
    assert_equal("{065CCCD0-4129-497C-8474-27EBCD96065D}",attr1[:projectid], ":projectid falsch")
    assert_equal("{022D080E-A80B-48F4-B573-8C57DE8F3860}",attr1[:rtid], ":rtid falsch")
    assert_equal("NEED",attr1[:rtprefixes], ":rtprefixes falsch")
    #attr2
    attr2=attrs["{0E8304EF-59BF-440D-9315-5E56E523A58C}"]
    assert_equal("",attr2[:default], ":default falsch")
    assert_equal("",attr2[:itemtext], ":itemtext falsch")
    assert_equal(0,attr2[:itemlist].count, ":itemlist count falsch") #Actual Iteration
    assert_equal(0,attr2[:itemlist_used].count, ":itemlist_used count falsch")
    assert_equal("Actual Iteration",attr2[:attrlabel], ":attrlabel falsch")
    assert_equal("Integer",attr2[:datatype], ":datatype falsch")
    assert_equal("MSP",attr2[:project], ":project falsch")
    assert_equal("{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}",attr2[:projectid], ":projectid falsch")
    assert_equal("{5E748E74-15E9-454E-8ACD-6D263D08E00F}",attr2[:rtid], ":rtid falsch")
    assert_equal("FUNC",attr2[:rtprefixes], ":rtprefixes falsch")
  end
  
  
  def test_collect_attributes
    atts = Hash.new
    atts["{01}"] = Hash.new
    atts["{01}"][:default]
    #prepare call
    hc=HelperClassForModules.new
    #stub the not to test methodes
    #attributes = collect_attributes_fast(some_projects, requirement_types, used_attributes_in_rts)
    #attributes = update_attributes_for_reqpro_needing(some_projects, attributes)
    hc.stubs(:collect_attributes_fast).returns(atts)
    hc.stubs(:update_attributes_for_reqpro_needing).returns(atts)
    #call
    atts2=hc.collect_attributes(nil,nil,nil,true)
    #test
    assert_equal(atts,atts2,"Uebergabe unsauber!")
  end
  
end