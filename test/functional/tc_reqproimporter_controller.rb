require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/../test_helper_for_redmine_defects.rb'
require File.dirname(__FILE__) + '/../../app/controllers/reqproimporter_controller'
  
# Re-raise errors caught by the controller.
class ReqproimporterController; def rescue_action(e) raise e end; end
  
class TestsReqproimporterController < ActionController::TestCase
  #class CustomFieldsControllerTest < ActionController::TestCase
  #fixtures :custom_fields, :trackers, :users
  
  def setup
    @controller = ReqproimporterController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_initialize_set_some_variables
    puts "test_initialize_set_some_variables"
    assert_equal(5, ReqproimporterController::LOGLEVEL)
    assert_equal(10, ReqproimporterController::ISSUE_ATTRS.count)
  end
  
  def test_index
    puts "test_index"
    get :index
    assert_response :success
    assert_equal([0,0],assigns(:progress_percent))
  end
  
  def test_listprojects_error_no_file
    puts "test_listprojects_error_no_file"
    get :listprojects
    assert_response :success
    assert_equal("No description file was selected.", flash[:error])
  end
  
  def test_listprojects_no_deep_check
    puts "test_listprojects_no_deep_check"
    #good case without deep check of external projects
    the_file = 'UploadTestFile.txt'
    th = MyTestHelper.new()
    get(:listprojects, {'file' => th.uploaded_test_file(the_file, 'text/plain')})
    assert_response :success
    assert_nil(flash[:error])
    assert_not_nil(assigns(:headers))
    assert_equal(2, assigns(:projects_keys_sorted).count)
    assert_not_nil(assigns(:projects_for_view))
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([0,20],assigns(:progress_percent))
  end
  
  def test_listprojects_deep_check
    puts "test_listprojects_deep_check"
    #good case with deep check of external projects
    the_file = 'UploadTestFile.txt'
    th = MyTestHelper.new()
    get(:listprojects, {'file' => th.uploaded_test_file(the_file, 'text/plain'), 'deep_check_ext_projects' => true})
    assert_response :success
    assert_nil(flash[:error])
    assert_not_nil(assigns(:headers))
    assert_equal(2, assigns(:projects_keys_sorted).count)
    assert_not_nil(assigns(:projects_for_view))
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([0,20],assigns(:progress_percent))
  end 
  
  def test_listprojects_error_no_project
    puts "test_listprojects_error_no_project"
    theFile = 'UploadTestFile_wrong.txt'
    th = MyTestHelper.new()
    get(:listprojects, {'file' => th.uploaded_test_file(theFile, 'text/plain'), 'deep_check_ext_projects' => true})
    assert_response :success
    assert_equal(theFile, assigns(:original_filename))
    assert_not_nil(assigns(:headers))
    assert_equal("No project found in specified pathes.", flash[:error])
    assert_nil(assigns(:projects_keys_sorted))
    assert_nil(assigns(:projects_for_view))
    assert_nil(assigns(:progress_percent))
  end

  def test_matchusers_error_no_project_go_back
    puts "test_matchusers_error_no_project_go_back"
    ReqproimporterController.some_projects = nil
    get :matchusers
    assert_response :success
    assert_equal("No project available to import. Please go back to file dialog page.", flash[:error])
  end
  
  def test_matchusers_error_no_project
    puts "test_matchusers_error_no_project"
    ReqproimporterController.some_projects = some_projects()
    get(:matchusers, {'import_this_projects' => nil})
    assert_response :success
    assert_equal("No project available to import.", flash[:error])
  end
   
  def test_matchusers_no_conflate_users
    puts "test_matchusers_no_conflate_users"
    theFile = "TestName"
    ReqproimporterController.some_projects = some_projects()
    ReqproimporterController.original_filename = theFile
    get(:matchusers, {'import_this_projects' => ["STP", "MSP"]})
    assert_response :success
    assert_nil(flash[:error])
    assert_nil(assigns(:conflate_users))
    assert_not_nil(assigns(:headers))
    assert_not_nil(assigns(:rpusers_for_view))
    assert_not_nil(assigns(:rpusers_keys_sorted))
    assert_not_nil(assigns(:rmusers_for_view))
    assert_equal(theFile, assigns(:original_filename))
    assert_equal([0,40],assigns(:progress_percent))
  end
  
  def test_matchusers_conflate_users
    puts "test_matchusers_conflate_users"
    the_file = "TestName"
    the_conflate = "email"
    thf = TestHelperForRedmineDefects.new()
    new_user = thf.create_user("new_user4test", "usr4test@test.de")
    ReqproimporterController.some_projects = some_projects()
    ReqproimporterController.original_filename = the_file
    get(:matchusers, {'import_this_projects' => ["STP", "MSP"], 'conflate_users' => the_conflate})
    assert_response :success
    assert_nil(flash[:error])
    assert_not_nil(assigns(:headers))
    assert_not_nil(assigns(:rpusers_for_view))
    assert_not_nil(assigns(:rpusers_keys_sorted))
    assert(assigns(:rmusers_for_view).include?(new_user[:mail]))
    assert_equal(the_conflate, assigns(:conflate_users))
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([0,40],assigns(:progress_percent))
  end
    
  def test_matchtrackers_noupdate_nodeepcheck_noconflate
    puts "test_matchtrackers_noupdate_nodeepcheck_noconflate"
    thf = TestHelperForRedmineDefects.new()
    new_user1 = thf.create_user("new_user4test1", "usr.test1@test.de")
    new_user2 = thf.create_user("new_user4test2", "usr.test2@test.de")
    the_file = "TestName"
    the_rpusers = rpusers()
    the_redmineusers = redmine_users("mail")
    ReqproimporterController.some_projects = some_projects()
    ReqproimporterController.original_filename = the_file
    ReqproimporterController.rpusers = the_rpusers
    ReqproimporterController.redmine_users = the_redmineusers
    get(:matchtrackers, {'fields_map_user' => fields_map_user()})
    assert_response :success
    assert_nil(flash[:error])
    assert_not_nil(assigns(:headers))
    assert_not_nil(assigns(:req_types_for_view))
    assert_not_nil(assigns(:req_types_keys_sorted))
    assert_not_nil(assigns(:trackers))
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([0,60],assigns(:progress_percent))
  end
  
  def test_matchtrackers_update_deepcheck_conflate
    puts "test_matchtrackers_update_deepcheck_conflate"
    thf = TestHelperForRedmineDefects.new()
    new_user1 = thf.create_user("new_user4test1", "usr.test1@test.de")
    new_user2 = thf.create_user("new_user4test2", "usr.test2@test.de")
    the_file = "TestName"
    the_rpusers = rpusers()
    the_redmineusers = redmine_users("mail")
    ReqproimporterController.some_projects = some_projects()
    ReqproimporterController.original_filename = the_file
    ReqproimporterController.rpusers = the_rpusers
    ReqproimporterController.redmine_users = the_redmineusers
    get(:matchtrackers, {'fields_map_user' => fields_map_user(),
                         'user_update_allowed'=>"true",
                         'deep_check_req_types'=> "true",
                         'conflate_req_types'=> "true"})
    assert_response :success
    assert_nil(flash[:error])
    assert_not_nil(assigns(:headers))
    assert_not_nil(assigns(:req_types_for_view))
    assert_not_nil(assigns(:req_types_keys_sorted))
    assert_not_nil(assigns(:trackers))
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([0,60],assigns(:progress_percent))
  end
  
  def test_matchversions_error_no_mapping
    puts "test_matchversions_error_no_mapping"
    get(:matchversions, {'fields_map_tracker'=> {"an_tr"=>""}})
    assert_response :success
    assert_equal("Empty tracker mapping! Least one requirement type have to be mapped to a tracker.", flash[:error])
  end
  
  def test_matchversions_no_deep_check
    puts "test_matchversions_no_deep_check"
    the_file = "TestName"
    ReqproimporterController.original_filename = the_file
    ReqproimporterController.some_projects = some_projects()
    ReqproimporterController.requirement_types=requirement_types()
    get(:matchversions, {'fields_map_tracker'=> {"stp_NEED"=>"rmTracker"}})
    assert_response :success
    assert_nil(flash[:error])
    assert_not_nil(assigns(:headers))
    assert_not_nil(assigns(:projects_with_versionattributes_for_view))
    assert_not_nil(assigns(:projects_for_view))
    assert_not_nil(assigns(:attrs_for_view))    
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([0,70],assigns(:progress_percent))
  end
  
  def test_matchversions_deep_check
    puts "test_matchversions_deep_check"
    the_file = "TestName"
    ReqproimporterController.original_filename = the_file
    ReqproimporterController.some_projects = some_projects()
    ReqproimporterController.requirement_types=requirement_types()
    get(:matchversions, {'fields_map_tracker'=> {"stp_NEED"=>"rmTracker"}}, 'deep_check_attributes'=>"true")
    assert_response :success
    assert_nil(flash[:error])
    assert_not_nil(assigns(:headers))
    assert_not_nil(assigns(:projects_with_versionattributes_for_view))
    assert_not_nil(assigns(:projects_for_view))
    assert_not_nil(assigns(:attrs_for_view))    
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([0,70],assigns(:progress_percent))
  end
  
  def test_matchattributes_noconflate_noupdate
    puts "test_matchattributes_noconflate_noupdate"
    the_file = "TestName"
    ReqproimporterController.original_filename = the_file
    ReqproimporterController.attributes=attributes()
    get(:matchattributes, {'fields_map_version'=> {"{065CCCD0-4129-497C-8474-27EBCD96065D}"=>"Priority"}})
    assert_response :success
    assert_nil(flash[:error])
    assert_nil(ReqproimporterController.version_update_allowed())
    assert_not_nil(ReqproimporterController.known_attributes())
    assert_not_nil(assigns(:headers))
    assert_not_nil(assigns(:novattributes_for_view))
    assert_not_nil(assigns(:novattributes_keys_sorted))
    assert_not_nil(assigns(:attrs))
    assert_equal(versions_mapping(), ReqproimporterController.versions_mapping())
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([0,80],assigns(:progress_percent))
  end
  
  def test_matchattributes_conflate_update
    puts "test_matchattributes_conflate_update"
    the_file = "TestName"
    ReqproimporterController.original_filename = the_file
    ReqproimporterController.attributes=attributes()
    get(:matchattributes, {'fields_map_version'=> {"{065CCCD0-4129-497C-8474-27EBCD96065D}"=>"Priority"}, 'version_update_allowed'=>"true", 'conflate_attributes'=>"true"})
    assert_response :success
    assert_nil(flash[:error])
    assert_not_nil(ReqproimporterController.known_attributes())
    assert_not_nil(assigns(:headers))
    assert_not_nil(assigns(:novattributes_for_view))
    assert_not_nil(assigns(:novattributes_keys_sorted))
    assert_not_nil(assigns(:attrs))    
    assert_equal("true", ReqproimporterController.version_update_allowed())
    assert_equal(versions_mapping(), ReqproimporterController.versions_mapping())
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([0,80],assigns(:progress_percent))
  end
  
  def test_do_import_and_result_notraceimport_noupdate
    puts "test_do_import_and_result_noimport_noupdate"
    the_file = "TestName"
    ReqproimporterController.original_filename = the_file
    ReqproimporterController.attributes=attributes()
    ReqproimporterController.versions_mapping=versions_mapping()
    ReqproimporterController.rpusers=rpusers()
    ReqproimporterController.tracker_mapping=tracker_mapping()
    ReqproimporterController.known_attributes=known_attributes()
    ReqproimporterController.some_projects=some_projects()
    ReqproimporterController.requirement_types=requirement_types()
    ReqproimporterController.user_update_allowed=nil
    ReqproimporterController.version_update_allowed=nil
    get(:do_import_and_result, {'fields_map_attribute'=> {"stp_Developer"=>"Zugewiesen an"}})
    assert_response :success
    assert_nil(flash[:error])
    assert_not_nil(assigns(:imp_res_header))
    assert_not_nil(assigns(:imp_res_first_column))
    assert_not_nil(assigns(:import_results))
    assert_not_nil(assigns(:imp_res))    
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([100,100],assigns(:progress_percent))
  end

  def test_do_import_and_result_alltraceimport_allupdate
    puts "test_do_import_and_result_noimport_noupdate"
    the_file = "TestName"
    ReqproimporterController.original_filename = the_file
    ReqproimporterController.attributes=attributes()
    ReqproimporterController.versions_mapping=versions_mapping()
    ReqproimporterController.rpusers=rpusers()
    ReqproimporterController.tracker_mapping=tracker_mapping()
    ReqproimporterController.known_attributes=known_attributes()
    ReqproimporterController.some_projects=some_projects()
    ReqproimporterController.requirement_types=requirement_types()
    ReqproimporterController.user_update_allowed="true"
    ReqproimporterController.version_update_allowed="true"
    get(:do_import_and_result, 
      {'fields_map_attribute'=> {"stp_Developer"=>"Zugewiesen an"}, 
       'issue_update_allowed'=>"true", 
       'import_parent_relation_allowed'=>"true",
       'import_internal_relation_allowed'=>"true",
       'import_external_relation_allowed'=>"true"})
    assert_response :success
    assert_nil(flash[:error])
    assert_not_nil(assigns(:imp_res_header))
    assert_not_nil(assigns(:imp_res_first_column))
    assert_not_nil(assigns(:import_results))
    assert_not_nil(assigns(:imp_res))    
    assert_equal(the_file, assigns(:original_filename))
    assert_equal([100,100],assigns(:progress_percent))
  end
private
  
  def some_projects
    return {"{065CCCD0-4129-497C-8474-27EBCD96065D}"=>{:prefix=>"STP", :description=>"Styleguide (Team) -> Richtlinie für alle Pakete", :date=>"2009-05-08 14:10:43", :extprefixes=>"NFL?, MSP?", :name=>"Styleguide - Project", :path=>"vendor/plugins/redmine_import_reqpro/test/samples/Baseline01_App", :author_rpid=>"{19104C19-B894-458B-B026-B3EEC6E6B7D1}"}, "{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"=>{:prefix=>"MSP", :description=>"Multisprayer-Painting-Entwicklung", :date=>"2009-05-08 14:05:42", :extprefixes=>"", :name=>"MultisprayerPainting - Product", :path=>"vendor/plugins/redmine_import_reqpro/test/samples/Baseline02_Mlc", :author_rpid=>"{1BCB3BC3-3620-459F-89DE-6DB5402031EE}"}}
  end
  
  def fields_map_user
    return {"Vorname1Nachname1@supa-usr.de"=>"usr.test1@test.de", "Vorname2Nachname2@supa-usr.de"=>"usr.test2@test.de", "Vorname6Nachname4@upa-usr.de"=>""}
  end
  
  def rpusers
    return {"{6BAEDDBC-71CE-4403-8F18-6E70A72CF270}"=>{:email=>"Vorname4Nachname4@supa-usr.de", :login=>"Nachname4", :group=>"{EAF69D26-8C45-4DF1-8922-2EBD36488833}", :firstname=>"Nachname", :lastname=>"4", :conf_key=>"Vorname4Nachname4@supa-usr.de", :project=>"STP"}, 
            "{1BCB3BC3-3620-459F-89DE-6DB5402031EE}"=>{:email=>"Vorname1Nachname1@supa-usr.de", :login=>"Nachname1", :group=>"{160244B7-8A46-4818-BF57-9A76A748BDB4}", :firstname=>"Nachname", :lastname=>"1", :conf_key=>"Vorname1Nachname1@supa-usr.de", :project=>"MSP"},
            "{DB0B60C4-70BE-4BD0-A55F-289CD21FAB3C}"=>{:email=>"Vorname5Nachname5@supa-usr.de", :login=>"Nachname5", :group=>"{EE5B426C-0276-44E4-A52C-824D2A8D039A}", :firstname=>"Nachname", :lastname=>"5", :conf_key=>"Vorname5Nachname5@supa-usr.de", :project=>"STP"},
            "{F1B84999-EA1F-4344-B53F-C649218E7139}"=>{:email=>"Vorname2Nachname2@supa-usr.de", :login=>"Nachname2", :group=>"{F38CB504-96C2-4596-BEC2-1F9BA52B6238}", :firstname=>"Nachname", :lastname=>"2", :conf_key=>"Vorname2Nachname2@supa-usr.de", :project=>"MSP"},
            "{9FA86666-A3FF-453A-A066-EFA5CCA65AC4}"=>{:email=>"Vorname6Nachname6@supa-usr.de", :login=>"Nachname6", :group=>"{EAF69D26-8C45-4DF1-8922-2EBD36488833}", :firstname=>"Nachname", :lastname=>"6", :conf_key=>"Vorname6Nachname6@supa-usr.de", :project=>"STP"},
            "{16AA815A-4174-412A-947C-037F69A327B9}"=>{:email=>"Vorname2Nachname2@sup-usr.de", :login=>"Nachname2", :group=>"{5A468F80-E869-4A75-A90B-779D2B90ABF2}", :firstname=>"Nachname", :lastname=>"2", :conf_key=>"Vorname2Nachname2@sup-usr.de", :project=>"STP"}, 
            "{5481430E-6FF7-404F-AFF4-617D230937E3}"=>{:email=>"Vorname3Nachname3@upusr.de", :login=>"Nachname3", :group=>"{EAF69D26-8C45-4DF1-8922-2EBD36488833}", :firstname=>"Vorname3", :lastname=>"Nachname3", :conf_key=>"Vorname3Nachname3@upusr.de", :project=>"STP"},
            "{19104C19-B894-458B-B026-B3EEC6E6B7D1}"=>{:email=>"Vorname1Nachname1@supa-usr.de", :login=>"Nachname1", :group=>"{EE5B426C-0276-44E4-A52C-824D2A8D039A}", :firstname=>"Nachname", :lastname=>"1", :conf_key=>"Vorname1Nachname1@supa-usr.de", :project=>"STP"},
            "{3F7D2B87-D519-4BD9-AC5F-B931C5DE7801}"=>{:email=>"Vorname6Nachname4@upa-usr.de", :login=>"Nachname4", :group=>"{00934516-9440-48BD-A6E8-1FDF94B88D27}", :firstname=>"Nachname", :lastname=>"4", :conf_key=>"Vorname6Nachname4@upa-usr.de", :project=>"MSP"}, 
            "{0768C722-64AD-4AE3-884A-B39B97B19F29}"=>{:email=>"Vorname7Nachname7@supa-usr.de", :login=>"Nachname7", :group=>"{00934516-9440-48BD-A6E8-1FDF94B88D27}", :firstname=>"Nachname", :lastname=>"7", :conf_key=>"Vorname7Nachname7@supa-usr.de", :project=>"MSP"},
            "{0BEBBAEB-D9AC-4AD7-8291-A4E6291B83BC}"=>{:email=>"Vorname5Nachname5@supa-usr.de", :login=>"Nachname5", :group=>"{160244B7-8A46-4818-BF57-9A76A748BDB4}", :firstname=>"Nachname", :lastname=>"5", :conf_key=>"Vorname5Nachname5@supa-usr.de", :project=>"MSP"}}
  end
  
  def redmine_users(conflate_users)
    redmine_users = Hash.new
    redmine_users[:rmusers] = Array.new
    redmine_users[:key_for_view] = Array.new
    User.find(:all).each do |usr|
      case conflate_users
      when "login"
        if usr[:login].length > 2
          redmine_users[:key_for_view].push(usr[:login])
          redmine_users[:rmusers].push(usr)
        end
        #@headers = ["label_prefixed_email", "label_user_login", "label_mapped_user_login", "label_more_info"]
      when "name"
        if usr[:lastname].length > 2
          redmine_users[:key_for_view].push(usr[:firstname] + " " + usr[:lastname]) 
          redmine_users[:rmusers].push(usr)
        end
        #@headers = ["label_prefixed_email", "label_user_name", "label_mapped_user_name", "label_more_info"]
      else
        #default for "email" and "none" 
        if usr[:mail].casecmp("@") == 1
          redmine_users[:key_for_view].push(usr[:mail])
          redmine_users[:rmusers].push(usr)
        end
      end
    end
    return redmine_users 
  end

  def requirement_types  
    return {"{022D080E-A80B-48F4-B573-8C57DE8F3860}"=>{:prefix=>"NEED", :project=>"STP", :attrids=>["{2A379FB1-B401-4116-BF73-E39092CB42C4}", "{40088819-36D5-4841-9B9D-707362EE37D4}", "{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}", "{51E59074-F681-44CA-9888-561861D2EBC0}", "{63765958-43FF-4FA2-BA21-257D03DFA2F0}", "{77949EC0-91FF-4096-9B22-A5227D850474}", "{7E229F6C-A2A8-4223-AF77-5C57BE3BBD1A}", "{B77C4030-CC70-4377-A19D-46819635E29E}"], :name=>"User Need"}}
  end
  def tracker_mapping
    return {"stp_NEED"=>{:tr_name=>"rmTracker"}}
  end
  def attributes
    return {"{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"=>{:itemlist=>["Vorname2 Nachname2", "Vorname1 Nachname1", "Vorname6 Nachname6", "Vorname7 Nachname7", "Vorname3 Nachname3", "Vorname8 Nachname8", "Vorname5 Nachname5"], :itemlist_used=>[], :datatype=>"MultiSelect", :projectid=>"{065CCCD0-4129-497C-8474-27EBCD96065D}", :project=>"STP", :attrlabel=>"Developer", :rtid=>"{022D080E-A80B-48F4-B573-8C57DE8F3860}", :itemtext=>"", :default=>"", :rtprefixes=>"NEED"}, 
            "{51E59074-F681-44CA-9888-561861D2EBC0}"=>{:itemlist=>[], :itemlist_used=>[], :datatype=>"Integer", :projectid=>"{065CCCD0-4129-497C-8474-27EBCD96065D}", :project=>"STP", :attrlabel=>"Effort (days)", :rtid=>"{022D080E-A80B-48F4-B573-8C57DE8F3860}", :itemtext=>"1", :default=>"1", :rtprefixes=>"NEED"}, 
            "{7E229F6C-A2A8-4223-AF77-5C57BE3BBD1A}"=>{:itemlist=>["Proposed", "Traced", "Spec", "C++-Code", "FirstReview", "NotRelevant"], :itemlist_used=>[], :datatype=>"MultiSelect", :projectid=>"{065CCCD0-4129-497C-8474-27EBCD96065D}", :project=>"STP", :attrlabel=>"State", :rtid=>"{022D080E-A80B-48F4-B573-8C57DE8F3860}", :itemtext=>"", :default=>"", :rtprefixes=>"NEED"},
            "{40088819-36D5-4841-9B9D-707362EE37D4}"=>{:itemlist=>["High", "Medium", "Low"], :itemlist_used=>[], :datatype=>"List", :projectid=>"{065CCCD0-4129-497C-8474-27EBCD96065D}", :project=>"STP", :attrlabel=>"Difficulty", :rtid=>"{022D080E-A80B-48F4-B573-8C57DE8F3860}", :itemtext=>"", :default=>"", :rtprefixes=>"NEED"}, 
            "{77949EC0-91FF-4096-9B22-A5227D850474}"=>{:itemlist=>["High", "preHigh", "Medium", "preMedium", "Low"], :itemlist_used=>[], :datatype=>"List", :projectid=>"{065CCCD0-4129-497C-8474-27EBCD96065D}", :project=>"STP", :attrlabel=>"Priority", :rtid=>"{022D080E-A80B-48F4-B573-8C57DE8F3860}", :itemtext=>"", :default=>"", :rtprefixes=>"NEED"},
            "{2A379FB1-B401-4116-BF73-E39092CB42C4}"=>{:itemlist=>["High", "Medium", "Low"], :itemlist_used=>[], :datatype=>"List", :projectid=>"{065CCCD0-4129-497C-8474-27EBCD96065D}", :project=>"STP", :attrlabel=>"Stability", :rtid=>"{022D080E-A80B-48F4-B573-8C57DE8F3860}", :itemtext=>"", :default=>"", :rtprefixes=>"NEED"},
            "{63765958-43FF-4FA2-BA21-257D03DFA2F0}"=>{:itemlist=>[], :itemlist_used=>[], :datatype=>"Real", :projectid=>"{065CCCD0-4129-497C-8474-27EBCD96065D}", :project=>"STP", :attrlabel=>"Effort remaining (days)", :rtid=>"{022D080E-A80B-48F4-B573-8C57DE8F3860}", :itemtext=>"999.0", :default=>"999.0", :rtprefixes=>"NEED"}}
  end

  def known_attributes
    return {"BoolCuFi"=>{:custom_field_id=>6},
            "RPUID"=>{:custom_field_id=>3},
            "Priority"=>{:custom_field_id=>""},
            "FloatCuFi"=>{:custom_field_id=>8},
            "Estimated time"=>{:custom_field_id=>""},
            "DateCuFi"=>{:custom_field_id=>7},
            "Watchers"=>{:custom_field_id=>""},
            "% Done"=>{:custom_field_id=>""},
            "Category"=>{:custom_field_id=>""},
            "ListCuFi"=>{:custom_field_id=>9},
            "Difficulty"=>{:custom_field_id=>1},
            "Status"=>{:custom_field_id=>2},
            "IntegerCuFi"=>{:custom_field_id=>5},
            "Author"=>{:custom_field_id=>""},
            "IntegerCuFi_Without_Value"=>{:custom_field_id=>10},
            "CuFi_With_Unknown_Format"=>{:custom_field_id=>11},
            "Start date"=>{:custom_field_id=>""},
            "Due date"=>{:custom_field_id=>""},
            "Assignee"=>{:custom_field_id=>""}}
  end
  
  def versions_mapping
    return {"{065CCCD0-4129-497C-8474-27EBCD96065D}"=>"{77949EC0-91FF-4096-9B22-A5227D850474}"}
  end
end