require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/../../app/controllers/reqproimporter_controller'
require 'mocha'

#starten: ruby vendor/plugins/redmine_import_reqpro/test/unit/tc_reqproimporter_controller.rb

class HelperClassForModules
  #include ReqproimporterController
  #include UsersHelper
  #include FilesHelper
  #include ExtProjectsHelper
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

class TcReqproimporterControllerUnits < ActiveSupport::TestCase
  self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
  fixtures :projects, :issues, :issue_statuses, :issue_relations, :trackers , :enumerations, :custom_fields, :custom_values, :users, :roles, :versions
  
  def test_reqproimporter_controller_prerequisites
    puts "test_reqproimporter_controller_prerequisites"
    assert_equal(3,Project.find(:all).count, "Project nicht korrekt")
    assert_equal(14,Issue.find(:all).count, "Issue nicht korrekt")
    assert_equal(2,IssueStatus.find(:all).count, "IssueStatus nicht korrekt")
    assert_equal(1,IssueRelation.find(:all).count, "IssueRelation nicht korrekt")
    assert_equal(4,Tracker.find(:all).count, "Tracker nicht korrekt")
    assert_equal(4,Enumeration.find(:all).count, "Enumeration nicht korrekt")
    assert_equal(10,IssueCustomField.find(:all).count, "IssueCustomField nicht korrekt")
    assert_equal(11,CustomField.find(:all).count, "CustomField nicht korrekt")
    assert_equal(23,CustomValue.find(:all).count, "CustomValue nicht korrekt")
    assert_equal(6,User.find(:all).count, "User nicht korrekt")
    assert_equal(5,Role.find(:all).count, "Role nicht korrekt")
    assert_equal(7,Version.find(:all).count, "Version nicht korrekt")
  end
  
  #ruby vendor/plugins/redmine_import_reqpro/test/unit/tc_reqproimporter_controller_units.rb --name test_create_all_issues
  def test_create_all_issues
    #Faelle:
    #+project nicht gefunden (bei 2 Projekten)
    #+reqtype (Tracker) wird nicht importiert ({"WRONG-022D080E-A80B-48F4-B573-8C57DE8F3860"})
    #+Tracker nicht gefunden ({"NOTRACKER-022D080E-A80B-48F4-B573-8C57DE8F3860"})
    #+vorh. Issue update nicht erlaubt (<RName>MyTestIssue46</RName>, Issue.ID=46)
    #/neuer Issue
    #+..mit Issue-Attributen FV (estimated_hours bzw. "Estimated time")
    #+..Attribut ist Version immer von LV ("OODev")
    #+..mit Issue-Attributen von LV ("Priority")
    #+..mit Attributen als CustomField von LV ("Difficulty")
    #+..mit Attributen als CustomField von FV ("Effort remaining (days)"?)
    #+..Zieldatum kleiner als Startdatum
    #+rpid ist leer oder nil
    #TODO: vorh. Issue update erlaubt
    puts "test_create_all_issues"
    th=MyTestHelper.new
    #prepare call of private function
    #return_hash_from_issues = create_all_issues(some_projects, requirement_types, attributes, new_versions_mapping, known_attributes, rpusers, issue_update_allowed, debug)
    ReqproimporterController.class_eval{def cai(a,b,c,d,e,f,g,h) return create_all_issues(a,b,c,d,e,f,g,h) end}
    #prepare datas
    sop=th.some_projects()
    sop["{065CCCD0-4129-497C-8474-27EBCD96065D}"][:prefix]="MPR2"  #was "STP"
    rts=th.requirement_types()
    #add mapping for requested reqtype
    rts["{022D080E-A80B-48F4-B573-8C57DE8F3860}"][:mapping]="Need"
    #add an requirement type with an unknown Tracker 
    rts["{NOTRACKER-022D080E-A80B-48F4-B573-8C57DE8F3860}"] = Hash.new
    #add an custom field for "Effort remaining (days)"    
    new_issue_custom_field = IssueCustomField.new 
    new_issue_custom_field.name = "EffortRemaining"
    new_issue_custom_field.field_format = "int"
    new_issue_custom_field.min_length = "0"
    new_issue_custom_field.max_length = "0"
    new_issue_custom_field.default_value = "999"
    new_issue_custom_field.possible_values = ""
    #new_issue_custom_field.trackers = Array.new
    new_issue_custom_field.searchable = "true"
    new_issue_custom_field.is_required = "false"
    new_issue_custom_field.regexp = "" 
    new_issue_custom_field.is_for_all = "0"
    new_issue_custom_field.is_filter = "1"
    if new_issue_custom_field.save == false
      puts "new_issue_custom_field wurde nicht gespeichert!"
      debugger
    end
    #get known rm-attributes:  
    knattrs=th.known_attributes()
    # add Issue attribute2
    knattrs["Estimated time"] = Hash.new
    knattrs["Estimated time"][:custom_field_id] = ""
    knattrs["Start date"] = Hash.new
    knattrs["Start date"][:custom_field_id] = ""
    knattrs["Due date"] = Hash.new
    knattrs["Due date"][:custom_field_id] = ""
    knattrs["Priority"] = Hash.new
    knattrs["Priority"][:custom_field_id] = ""
    knattrs["rp_Developer"] = Hash.new
    knattrs["rp_Developer"][:custom_field_id] = ""
    knattrs["EffortRemaining"] = Hash.new
    knattrs["EffortRemaining"][:custom_field_id] = new_issue_custom_field.id
    #get rp-attributes
    attrs=th.attributes()
    #add some attributes ("Effort (days)" for Issue FV already known)
    attrs["{77949EC0-91FF-4096-9B22-A5227D850474}"] = Hash.new
    attrs["{77949EC0-91FF-4096-9B22-A5227D850474}"][:attrlabel] = "Priority" #Issue LV
    attrs["{1FBDB5F4-538A-48D9-8ACD-22C284A4713C}"] = Hash.new
    attrs["{1FBDB5F4-538A-48D9-8ACD-22C284A4713C}"][:attrlabel] = "OODev" #LV for Version
    attrs["{40088819-36D5-4841-9B9D-707362EE37D4}"] = Hash.new
    attrs["{40088819-36D5-4841-9B9D-707362EE37D4}"][:attrlabel] = "Difficulty" #icf LV 
    attrs["{63765958-43FF-4FA2-BA21-257D03DFA2F0}"] = Hash.new
    attrs["{63765958-43FF-4FA2-BA21-257D03DFA2F0}"][:attrlabel] = "Effort remaining (days)" #icf FV
    attrs["{15765958-43FF-4FA2-BA21-257D03DFA2F0}"] = Hash.new
    attrs["{15765958-43FF-4FA2-BA21-257D03DFA2F0}"][:attrlabel] = "Start Datum" #synthetic Issue FV
    attrs["{16765958-43F0-4FA3-BA22-257D03DFA2F1}"] = Hash.new
    attrs["{16765958-43F0-4FA3-BA22-257D03DFA2F1}"][:attrlabel] = "Ziel Datum" #synthetic Issue FV
    # make special mapping
    attrs.each do |attr_key, attr_val|
      attr_val[:mapping]="rp_Developer" if  attr_val[:attrlabel] == "Developer"
      attr_val[:mapping]="Estimated time" if  attr_val[:attrlabel] == "Effort (days)" #Issue FV
      attr_val[:mapping]="Priority" if  attr_val[:attrlabel] == "Priority" #Issue LV
      attr_val[:mapping]="Difficulty" if  attr_val[:attrlabel] == "Difficulty" #icf LV
      attr_val[:mapping]="EffortRemaining" if  attr_val[:attrlabel] == "Effort remaining (days)" #icf FV
      attr_val[:mapping]="Start date" if  attr_val[:attrlabel] == "Start Datum" #synthetic Issue FV
      attr_val[:mapping]="Due date" if  attr_val[:attrlabel] == "Ziel Datum" #synthetic Issue FV
    end
    #get versions mapping    
    newVerMapping=th.new_versions_mapping()
    #get users        
    rpusrs=th.rpusers()
    #add the requested tracker to the requested project
    Project.find_by_id(2).trackers.push(Tracker.find_by_id(3))
    #delete custom field for rpuid for test of auto creation
    CustomField.find(:first, :conditions=> {:type=>"IssueCustomField",:name => "RPUID"}).delete
    if CustomField.find(:first, :conditions=> {:type=>"IssueCustomField",:name => "RPUID"}) != nil
      debugger
      puts "Loeschen fehlgeschlagen!"
    end
    ##### prepare test against old values ########
    i_old = Issue.find(:all)
    i_old_hours = i_old - Issue.find(:all, :conditions => { :estimated_hours => nil })
    issues4version_old = Array.new(7)
    for id in 1..7
      issues4version_old[id-1] = Version.find_by_id(id).fixed_issues.count 
    end
    #function call
    rc=ReqproimporterController.new()
    hc=HelperClassForModules.new()
    return_hash_from_issues =rc.cai(sop,rts,attrs,newVerMapping,knattrs,rpusrs,false,hc.loglevel_high())
    ##### prepare test against new values ########
    i_new = Issue.find(:all)
    i_new_hours = i_new - Issue.find(:all, :conditions => { :estimated_hours => nil })
    #prepare version test
    issues4version_new = Array.new(7)
    for id in 1..7
      issues4version_new[id-1] = Version.find_by_id(id).fixed_issues.count 
    end
    i_add = i_new-i_old
    #prepare priority test
    issues4priority = Hash.new
    i_add.each do |val|
      if issues4priority[val.priority_id] == nil
        issues4priority[val.priority_id] = 1
      else
        issues4priority[val.priority_id] = issues4priority[val.priority_id] + 1 
      end
    end
    #prepare custom field tests
    cf_counter1=0
    cf_counter2=0
    i_add.each do |a_issue|
      a_issue.custom_values.each do |a_custom_val|
        if a_custom_val.custom_field_id == 1 and a_custom_val.value != CustomField.find_by_id(1).default_value
          cf_counter1 += 1
        else
          if a_custom_val.custom_field_id == CustomField.find_by_name("EffortRemaining").id and a_custom_val.value != CustomField.find_by_name("EffortRemaining").default_value
            cf_counter2 += 1
          end
        end
      end
    end
    assert_not_nil(CustomField.find(:first, :conditions=> {:type=>"IssueCustomField",:name => "RPUID"}), "RPUID muss angelegt sein!")
    assert_equal(true, CustomField.find(:first, :conditions=> {:type=>"IssueCustomField",:name => "RPUID"}).id > 11, "ID muss neu angelegt sein!")
    assert_equal("2010-01-01",Issue.find_by_subject("einfache Struktur").start_date.to_s, "Start Datum falsch!")
    assert_equal("2011-02-03",Issue.find_by_subject("einfache Struktur").due_date.to_s, "Ziel Datum falsch!")
    assert_equal("2013-01-02",Issue.find_by_subject("bessere Doku").start_date.to_s, "Start Datum falsch (nicht auf Ziel Datum gesetzt)!")
    assert_equal("2013-01-02",Issue.find_by_subject("bessere Doku").due_date.to_s, "Ziel Datum falsch!")
    assert_equal(31,cf_counter2, "Es müssen genau 31 Issues mit gesetztem CustomField -EffortRemaining- sein!")
    assert_equal(29,cf_counter1, "Es müssen genau 29 Issues mit gesetztem CustomField 1 sein!")
    assert_equal(12,issues4priority[1], "Es müssen genau 12 Issues mit Priority 1 sein!")
    assert_equal(2, issues4priority[2], "Es müssen genau 2 Issues mit Priority 2 sein!")
    assert_equal(15,issues4priority[3], "Es müssen genau 15 Issues mit Priority 3 sein!")
    assert_equal(14,issues4priority[4], "Es müssen genau 14 Issues mit Priority 4 sein!")
    assert_equal(15,issues4version_new[0]-issues4version_old[0], "Es müssen genau 15 neue Issues an Version 1 hängen!")
    assert_equal(1, issues4version_new[1]-issues4version_old[1], "Es müssen genau 1 neues Issues an Version 2 hängen!")
    assert_equal(4, issues4version_new[2]-issues4version_old[2], "Es müssen genau 4 neue Issues an Version 3 hängen!")
    assert_equal(4, issues4version_new[3]-issues4version_old[3], "Es müssen genau 4 neue Issues an Version 4 hängen!")
    assert_equal(2, issues4version_new[4]-issues4version_old[4], "Es müssen genau 2 neue Issues an Version 5 hängen!")
    assert_equal(2, issues4version_new[5]-issues4version_old[5], "Es müssen genau 2 neue Issues an Version 6 hängen!")
    assert_equal(3, issues4version_new[6]-issues4version_old[6], "Es müssen genau 3 neue Issues an Version 7 hängen!")
    assert_equal(43, i_add.count, "Es müssen genau 43 neue Issues (46 abzueglich 3 verworfene) da sein!")
    assert_equal(42, (i_new_hours-i_old_hours).count, "Es müssen genau 42 (bei einem wurde FV-Element geloescht) Issues mit estimated_hours da sein!")
    assert_not_nil(return_hash_from_issues[:rp_req_unique_names], "Kein neues Issue importiert!")
    assert_not_nil(return_hash_from_issues[:rp_relation_list], "Kein Relationen gefunden!")
  end
  
  def test_create_all_projects
    puts "test_create_all_projects"
    th=MyTestHelper.new
    #prepare call of private function
    #some_projects = create_all_projects(some_projects, tracker_mapping, rpusers, debug)
    ReqproimporterController.class_eval{def cap(a,b,c,d) return create_all_projects(a,b,c,d) end}
    #prepare datas
    pr_count_old=Project.find(:all).count
    mb_count_old=Member.find(:all).count
    #don't use the th.rpusers because there is to much trouble with membership
    rmuser01=User.find_by_id(1)
    rpusers=Hash.new
    rpusers["{xx}"]=Hash.new
    rpusers["{xx}"][:project]="PR1"
    rpusers["{xx}"][:rmuser]=rmuser01
    rpusers["{xx}"][:login]="LoginForStatusMessage"
    rpu_count_old=rpusers.count
    tm=th.tracker_mapping()
    tm_count_old=tm.count
    sop=th.some_projects()
    sop_count_old=sop.count
    #function call
    rc=ReqproimporterController.new()
    hc=HelperClassForModules.new()
    some_projects=rc.cap(sop, tm, rpusers, hc.loglevel_high())
    #test
    assert_equal(mb_count_old+1, Member.find(:all).count, "Anzahl Members muss erhoeht sein!")
    assert_equal(rpu_count_old, rpusers.count, "Anzahl rpusers darf sich nicht ändern!")
    assert_equal(tm_count_old, tm.count, "Anzahl tracker_mapping darf sich nicht ändern!")
    assert_equal(sop_count_old, some_projects.count, "Anzahl some_projects darf sich nicht ändern!")
    assert_equal(pr_count_old+3, Project.find(:all).count, "Kein oder falsche Anzahl Project hinzugefuegt!")
    assert_not_nil(some_projects["{065CCCD0-4129-497C-8474-27EBCD96065D}"][:rmid], "neue Redmine ID nicht zurueck gegeben!")
    assert_equal(3, some_projects["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:rmid], "bekannte Redmine ID nicht zurueck gegeben!")
  end
  
  def test_create_all_users_and_update
    puts "test_create_all_users_and_update"
    th=MyTestHelper.new
    #prepare call of private function
    #rp_users = create_all_users_and_update(rp_users, update_allowed, debug)
    ReqproimporterController.class_eval{def cauau(a,b,c) return create_all_users_and_update(a,b,c) end}
    #prepare datas
    usr_count_old=User.find(:all).count
    rpu_count_old=th.rpusers().count
    #function call
    rc=ReqproimporterController.new()
    hc=HelperClassForModules.new()
    rp_users=rc.cauau(th.rpusers(), true, hc.loglevel_high())
    #test
    assert_equal(rpu_count_old, rp_users.count, "Anzahl rp_users darf sich nicht ändern!")
    assert_equal(usr_count_old+2, User.find(:all).count, "Kein oder falsche Anzahl User hinzugefuegt!")
    assert_equal("user01@admin.de", User.find_by_login("User01")[:mail], "Admin User darf nicht updatet sein!")
    assert_equal("usr6@mail.de", User.find_by_login("User02")[:mail], "User02 muss updatet sein!")
  end
  
  def test_create_all_users_and_update_without_update
    puts "test_create_all_users_and_update but without update"
    th=MyTestHelper.new
    #prepare call of private function
    #rp_users = create_all_users_and_update(rp_users, update_allowed, debug)
    ReqproimporterController.class_eval{def cauau(a,b,c) return create_all_users_and_update(a,b,c) end}
    #function call
    rc=ReqproimporterController.new()
    hc=HelperClassForModules.new()
    usr_count_old=User.find(:all).count
    rpu_count_old=th.rpusers().count
    rp_users=rc.cauau(th.rpusers(), false, hc.loglevel_high())
    #test
    assert_equal(rpu_count_old, rp_users.count, "Anzahl rp_users darf sich nicht ändern!")
    assert_equal(usr_count_old+2, User.find(:all).count, "Kein oder falsche Anzahl User hinzugefuegt!")
    assert_equal("user01@admin.de", User.find_by_login("User01")[:mail], "Admin User darf nicht updatet sein!")
    assert_equal("user02@users.de", User.find_by_login("User02")[:mail], "User02 darf nicht updatet sein!")
  end
    
  def test_create_all_trackers_and_update_mapping
    puts "test_create_all_trackers_and_update_mapping"
    th=MyTestHelper.new
    #prepare call of private function
    #tracker_mapping = create_all_trackers_and_update_mapping(tracker_mapping, debug)
    ReqproimporterController.class_eval{def cataum(a,b) return create_all_trackers_and_update_mapping(a,b) end}
    #function call
    rc=ReqproimporterController.new()
    hc=HelperClassForModules.new()
    tm_old=th.tracker_mapping()
    tm_old_count=tm_old.count
    tr_count_old=Tracker.find(:all).count
    tm_new=rc.cataum(tm_old,hc.loglevel_high())
    #test
    assert_equal(tm_old_count, tm_new.count, "Anzahl TrackerMaps darf sich nicht ändern!")
    assert_equal(tr_count_old+1, Tracker.find(:all).count, "Kein oder falsche Anzahl Tracker hinzugefuegt!")
    assert_equal("Defect", Tracker.find_by_id(tm_new["NEED"][:trid])[:name], "Funktion nicht sinnvoll beendet!")
    assert_equal("rm_TODO", Tracker.find_by_id(tm_new["TODO"][:trid])[:name], "Funktion nicht sinnvoll beendet!")
  end

  def test_create_all_customfields
    puts "test_create_all_customfields"
    th=MyTestHelper.new
    #prepare call of private function
    #def create_all_customfields(known_attributes, attributes, versions_mapping, tracker_mapping, debug)
    ReqproimporterController.class_eval{def cac(a,b,c,d,e) return create_all_customfields(a,b,c,d,e) end}
    #function call
    rc=ReqproimporterController.new()
    hc=HelperClassForModules.new()
    ka=th.known_attributes()
    ka_count=ka.count
    icf_count=IssueCustomField.find(:all).count
    known_attributes=rc.cac(ka,th.attributes_with_mapping(), th.versions_mapping(), th.tracker_mapping(), hc.loglevel_high())
    #test
    assert_equal(ka_count+1, known_attributes.count, "Kein oder falsche Anzahl Attribute hinzugefuegt!")
    assert_equal(icf_count+1, IssueCustomField.find(:all).count, "Kein oder falsche Anzahl IssueCustomField hinzugefuegt!")
    assert_not_nil(IssueCustomField.find_by_id(known_attributes["Effort"][:custom_field_id]), "Funktion nicht sinnvoll beendet!" )
    #TODO: test for case "not a custom field: IssueStatuses and IssuePriorities also updatable"
  end
  
  def test_create_all_versions
    puts "test_create_all_versions"
    th=MyTestHelper.new
    #prepare call of private function
    #def create_all_versions(versions_mapping, attributes, version_update_allowed, debug)
    ReqproimporterController.class_eval{def cav(a,b,c,d) return create_all_versions(a,b,c,d) end}
    #function call
    rc=ReqproimporterController.new()
    hc=HelperClassForModules.new()
    #stub the not to test methodes
    #rm_project =  project_find_by_rpuid(rp_project_id)
    rm_project=Project.find(:all).first
    rc.stubs(:project_find_by_rpuid).returns(rm_project)
    vmap_new=rc.cav(th.versions_mapping(),th.attributes(),false,hc.loglevel_high())
    #test
    assert_equal(2, vmap_new[th.versions_mapping().first[0]].count, "Inhalt der map wurde nicht hinzugefuegt!")
  end
    
  def test_set_versions_mapping
    puts "test_set_versions_mapping"
    th=MyTestHelper.new
    #prepare call of private function
    #vmap_new = set_versions_mapping(versions_map, attributes)
    ReqproimporterController.class_eval{def svm(a,b) return set_versions_mapping(a,b) end}
    #function call
    hc=ReqproimporterController.new()
    #stub the not to test methodes
    #vval_new = attribute_find_by_projectid_and_attrlabel(attributes, projid, attrlabel)
    vval_new=th.attributes().first
    hc.stubs(:attribute_find_by_projectid_and_attrlabel).returns(vval_new)
    vmap_new=hc.svm(th.version_map(),th.attributes())
    #test
    assert_equal(2, vmap_new.count, "Inhalt der map wurde nicht hinzugefuegt!")
    assert_equal(vval_new[0], vmap_new["{0815}"], "Inhalt zeigt auf falsches attribute!")
  end
    
  def test_set_attributes_mapping
    puts "test_set_attributes_mapping"
    th=MyTestHelper.new
    #prepare call of private function
    #attributes_mapping = set_attributes_mapping(attributes_map)
    ReqproimporterController.class_eval{def sam(a) return set_attributes_mapping(a) end}
    #function call
    hc=ReqproimporterController.new()
    attr_mapping = hc.sam(th.attributes_map)
    #test
    assert_equal(2, attr_mapping.count, "Inhalt der map wurde nicht hinzugefuegt!")
    assert_equal("rm_Developer",attr_mapping["rp_Developer"][:attr_name], "Atrributes mapping wurde falsch zusammengesetzt!")
  end
  
  
  def test_set_tracker_mapping
    puts "test_set_tracker_mapping"
    th=MyTestHelper.new
    #prepare call of private function
    #tracker_mapping = set_tracker_mapping(tracker_map)
    ReqproimporterController.class_eval{def stm(a) return set_tracker_mapping(a) end}
    #function call
    hc=ReqproimporterController.new()
    tr_mapping = hc.stm(th.tracker_map)
    #test
    assert_equal(3, tr_mapping.count, "Inhalt der map wurde nicht hinzugefuegt!")
    assert_equal("Mei_ne_Func_mit_un_er_laub_ten_Zei_chen_", tr_mapping["FUNC"][:tr_name], "Unerlaubte Zeichen wurden nicht sauber geloescht!")
  end
       
  def test_create_all_issuerelations
    puts "test_create_all_issuerelations"
    # internal relations p1 --> p1, i_pid1 --> [i_pid2, i_pid3]
    rp_relation_list = Hash.new
    rp_relation_list["{01}"] = Hash.new # project 1
    rp_relation_list["{01}"]["{01}"] = Hash.new # p1 --> p1
    rp_relation_list["{01}"]["{01}"]["{RPUID01}"] = Array.new
    rp_relation_list["{01}"]["{01}"]["{RPUID01}"].push("{RPUID02}")
    rp_relation_list["{01}"]["{01}"]["{RPUID01}"].push("{RPUID03}")
    # external relations p1 --> p2, i1 --> [i6, i7]
    rp_relation_list_ext = Hash.new
    rp_relation_list_ext["{01}"] = Hash.new
    rp_relation_list_ext["{01}"]["{02}"] = Hash.new # p1 --> p2 
    rp_relation_list_ext["{01}"]["{02}"]["{RPUID02}"] = Array.new
    rp_relation_list_ext["{01}"]["{02}"]["{RPUID02}"].push("{RPUID11}")
    rp_relation_list_ext["{01}"]["{02}"]["{RPUID02}"].push("{RPUID12}")
    irc=IssueRelation.find(:all).count
    #prepare call of private function
    #create_all_issuerelations(rp_relation_list, import_intern_relation_allowed, import_extern_relation_allowed, debug)
    ReqproimporterController.class_eval{def cai(a,b,c,d) return create_all_issuerelations(a,b,c,d) end}
    rc=ReqproimporterController.new()
    hc=HelperClassForModules.new()
    #function call for internal relation
    rc.cai(rp_relation_list, true, true, hc.loglevel_high())
    assert_equal(irc+2, IssueRelation.find(:all).count, "Interne Beziehungen wurden nicht richtig importiert!")
    #function call for external relation
    Setting.cross_project_issue_relations = '1' #allow relations between projects
    rc.cai(rp_relation_list_ext, true, true, hc.loglevel_high())
    assert_equal(irc+2+2, IssueRelation.find(:all).count, "Externe Beziehungen wurden nicht richtig importiert!")
  end
      
end
