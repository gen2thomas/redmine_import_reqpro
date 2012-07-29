require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/../../app/helpers/projects_helper'
require 'mocha'

class HelperClassForModules
  include ProjectsHelper
  include UsersHelper
  include FilesHelper
  include ExtProjectsHelper
end

class TcProjectsHelper < ActiveSupport::TestCase
  self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
  fixtures :projects, :custom_values, :issues, :users, :roles
  
  def test_project_prerequisites
    puts "test_project_prerequisites"
    assert(Project.find(:all).count==2, "Project nicht korrekt")
    assert(CustomValue.find(:all).count==10, "CustomValue nicht korrekt")
    assert(Issue.find(:all).count==8, "Issue nicht korrekt")
    assert(User.find(:all).count==3, "User nicht korrekt")
    assert(Role.find(:all).count==5, "Role nicht korrekt")
  end
    
  def test_project_find_by_rpuid
    puts "test_project_find_by_rpuid"
    #prepare custom fields done by fixture
    #prepare issues done by fixture
    #prepare call
    hc=HelperClassForModules.new()
    #function call
    proj_1=hc.project_find_by_rpuid("{10}", true) #known project
    proj_2=hc.project_find_by_rpuid("{02}", true) #same ID also for an Issue
    proj_nil = hc.project_find_by_rpuid("{01234}", true) #unknown rpuid
    no_proj = hc.project_find_by_rpuid("{07}", true) #wrong customized_type
    #test
    assert_equal(Project.find_by_id(1), proj_1, "Project 1 not found by ID!")
    assert_equal(Project.find_by_id(2), proj_2, "Project 2 not found by ID!")
    assert_nil(proj_nil, "proj_nil not nil!")
    assert_nil(no_proj, "no_proj not nil!")
  end
  
  def test_create_project_custom_field_for_rpuid
    puts "test_create_project_custom_field_for_rpuid"
    #prepare data
    pcf_count=ProjectCustomField.find(:all).count
    #prepare call
    hc=HelperClassForModules.new()
    #call
    pcf1 = hc.create_project_custom_field_for_rpuid()
    #test 1
    assert(pcf1!=nil, "pcf1 is nil!")
    if pcf1!=nil
      assert(pcf1[:name]=="RPUID", "pcf1 name must be RPUID!")
    end
    assert(pcf_count+1 == ProjectCustomField.find(:all).count, "pcf1 has to be added!")
    #prepare
    pcf1_id=pcf1.id
    #call
    pcf2 = hc.create_project_custom_field_for_rpuid()
    #test 2
    assert(pcf_count+1 == ProjectCustomField.find(:all).count, "pcf2 has not to be added!")
    assert(pcf2[:id]==pcf1_id, "pcf1 id must be the same like pfc2!")
  end
  
  def test_find_project_rpmember
    puts "test_find_project_rpmember"
    #prepare users done by fixture
    #prepare roles done by fixtures
    #member
    nu=User.find_by_id(1)
    nm = Member.new
    nm.user = nu
    nm.project = Project.find_by_id(1) 
    nm.mail_notification = false
    nm.roles.push(Role.find_by_name("Reporter")) # use reporter as default
    nm.roles.uniq!
    nm.save!
    #prepare call
    hc=HelperClassForModules.new()
    #stub the not to test methode (UsersHelper)
    hc.stubs(:find_user_by_string).returns(nu)
    fu= hc.find_project_rpmember("Egal", Hash.new, Project.find_by_id(1), true)
    assert_equal(nu, fu, "Mitglied nicht gefunden!")
  end
  
  def test_update_project_members_with_roles
    puts "test_update_project_members_with_roles"
    #prepare data
    rmproject=Project.find_by_id(1)
    rmuser01=User.find_by_id(1)
    rmuser02=User.find_by_id(2)
    rmuser03=User.find_by_id(3)
    rpusers=Hash.new
    #user should be member and "Manager"
    rpusers["{xx}"]=Hash.new
    rpusers["{xx}"][:project]=rmproject[:identifier]
    rpusers["{xx}"][:rmuser]=rmuser01
    #user should be member and "Reporter"
    rpusers["{yy}"]=Hash.new
    rpusers["{yy}"][:project]=rmproject[:identifier]
    rpusers["{yy}"][:rmuser]=rmuser02
    #user should not be member
    rpusers["{00}"]=Hash.new
    rpusers["{00}"][:project]=Project.find_by_id(2)[:identifier]
    rpusers["{00}"][:rmuser]=rmuser03
    #prepare test
    mems0=Member.find(:all, :conditions => {:project_id => 1})
    ### tests for a new member ###
    #call
    hc=HelperClassForModules.new()
    hc.update_project_members_with_roles(rmproject, rpusers, "{xx}")
    #test1
    mems1=Member.find(:all, :conditions => {:project_id => 1})
    assert_equal(mems0.count+2, mems1.count, "Es sind dem Projekt nicht genau 2 Mitglieder hinzugefügt wurden!")
    #test2
    mem=Member.find(:all, :conditions => { :user_id => rmuser01[:id], :project_id => 1 })
    assert(mem.count==1, "Memberliste defekt! User01 mehrfach gefunden!")
    assert(mem[0].roles.include?(Role.find_by_name("Manager")),"User1 ist kein Manager!")
    assert(!mem[0].roles.include?(Role.find_by_name("Reporter")),"User1 soll kein Reporter sein!")
    #test3
    mem=Member.find(:all, :conditions => { :user_id => rmuser02[:id], :project_id => 1 })
    assert(mem.count==1, "Memberliste defekt! User02 mehrfach gefunden!")
    assert(mem[0].roles.include?(Role.find_by_name("Reporter")),"User2 ist kein Reporter!")
    assert(!mem[0].roles.include?(Role.find_by_name("Manager")),"User2 soll kein Manager sein!")
    #test4
    mem=Member.find(:all, :conditions => { :user_id => rmuser03[:id], :project_id => 1 })
    assert(mem.count==0, "User3 darf kein Mitglied vom Projekt sein!")
    ### tests for an existend member ###
    hc.update_project_members_with_roles(rmproject, rpusers, "{xx}")
    #test1b
    mems2=Member.find(:all, :conditions => {:project_id => 1})
    assert_equal(mems1.count, mems2.count, "Es sind dem Projekt unerlaubt neue Mitglieder hinzugefügt wurden!")
    #test2b
    mem=Member.find(:all, :conditions => { :user_id => rmuser01[:id], :project_id => 1 })
    assert(mem.count==1, "Memberliste defekt! User01 mehrfach gefunden!")
    assert(mem[0].roles.include?(Role.find_by_name("Manager")),"User1 ist kein Manager!")
    assert(!mem[0].roles.include?(Role.find_by_name("Reporter")),"User1 soll kein Reporter sein!")
    #test3b
    mem=Member.find(:all, :conditions => { :user_id => rmuser02[:id], :project_id => 1 })
    assert(mem.count==1, "Memberliste defekt! User02 mehrfach gefunden!")
    assert(mem[0].roles.include?(Role.find_by_name("Reporter")),"User2 ist kein Reporter!")
    assert(!mem[0].roles.include?(Role.find_by_name("Manager")),"User2 soll kein Manager sein!")
    #test4b
    mem=Member.find(:all, :conditions => { :user_id => rmuser03[:id], :project_id => 1 })
    assert(mem.count==0, "User3 darf kein Mitglied vom Projekt sein!")
  end

  def test_collect_available_projects
    puts "test_collect_available_projects"
    #prepare data
    data_pathes = Array.new()
    path_to_samples=Dir.pwd + '/' + File.dirname(__FILE__) + '/../samples'
    data_pathes.push(path_to_samples + '/Baseline01_App')
    data_pathes.push(path_to_samples + '/Baseline02_Mlc')
    #prepare call of private function
    HelperClassForModules.class_eval{def cap(a) return collect_available_projects(a) end}
    hc=HelperClassForModules.new()
    #call
    ap=hc.cap(data_pathes)
    assert(ap.count==2, "Es sollten genau 2 Projekte sein!")
    p1=ap["{065CCCD0-4129-497C-8474-27EBCD96065D}"]
    assert(p1!=nil, "Falsches Projekt 1!")
    if p1!= nil
      assert(p1[:prefix]=="STP", "Falscher Prefix 1!")
      assert(p1[:path]==data_pathes[0], "Falscher Pfad 1!")
      assert(p1[:author_rpid]=="{19104C19-B894-458B-B026-B3EEC6E6B7D1}", "Falscher Autor 1!")
      assert(p1[:name]=="Styleguide - Project", "Falscher name 1!")
      assert(p1[:description]=="Styleguide (Team) -> Richtlinie für alle Pakete", "Falsche Beschreibung 1!")
      assert(p1[:date]=="2009-05-08 14:10:43", "Falsches Datum 1!")        
    end
    
    p2=ap["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"]
    assert(p2!=nil, "Falsches Projekt 2!")
    if p2!= nil
      assert(p2[:prefix]=="MSP", "Falscher Prefix 2!")
      assert(p2[:path]==data_pathes[1], "Falscher Pfad 2!")
      assert(p2[:author_rpid]=="{1BCB3BC3-3620-459F-89DE-6DB5402031EE}", "Falscher Autor 2!")
      assert(p2[:name]=="MultisprayerPainting - Product", "Falscher name 2!")
      assert(p2[:description]=="Multisprayer-Painting-Entwicklung", "Falsche Beschreibung 2!")
      assert(p2[:date]=="2009-05-08 14:05:42", "Falsches Datum 2!")
    end
  end
  
  def test_collect_projects
    puts "test_collect_projects"
    #prepare datas
    ap=Hash.new()
    #project1
    ap["{01}"]=Hash.new()
    ap["{01}"][:path]="/abc"
    #project2
    ap["{BF}"]=Hash.new()
    ap["{BF}"][:path]="/defgh"
    #prepare stubs and call
    hc=HelperClassForModules.new()  
    #stub the not to test methode
    hc.stubs(:collect_available_projects).returns(ap)
    #stub the not to test methode (ExtProjectsHelper)
    hc.stubs(:collect_external_projects).returns(Hash.new)
    #external_projects = ExtProjectsHelper::collect_external_projects(data_path, deep_check_ext_projects, available_projects)
    #stub the not to test methode (ExtProjectsHelper)
    hc.stubs(:external_prefixes_to_string).returns("EP1STR*,EP2STR?")
    #external_prefixes = ExtProjectsHelper::external_prefixes_to_string(external_projects)
    #call the function
    ap=hc.collect_projects(Array.new, false)
    #test
    p1=ap["{01}"]
    assert(p1[:extprefixes]=="EP1STR*,EP2STR?", "Falsche Prefixe bei p1!")
    p2=ap["{BF}"]
    assert(p2[:extprefixes]=="EP1STR*,EP2STR?", "Falsche Prefixe bei p2!")    
  end
  
  def test_update_projects_for_needing
    #prepare datas
    ap=Hash.new()
    #project1
    ap["{01}"]=Hash.new()
    ap["{01}"][:prefix]="STP"
    #project2
    ap["{BF}"]=Hash.new()
    ap["{BF}"][:prefix]="MSP"
    #project3
    ap["{03}"]=Hash.new()
    ap["{03}"][:prefix]="AGF"
    #needed projects
    np=Array.new()
    np.push("STP")
    np.push("AGF")
    np.push("UNKNOWN")
    #prepare call
    hc=HelperClassForModules.new()
    ap=hc.update_projects_for_needing(ap, np)
    assert(ap["{01}"]!=nil, "Projekt 01 darf nicht geloescht sein!")
    assert(ap["{BF}"]==nil, "Projekt BF muss geloescht sein!")
    assert(ap["{03}"]!=nil, "Projekt 03 darf nicht geloescht sein!")
  end
  
  def test_projects_sorted_array_of_key
    #prepare datas
    ap=Hash.new()
    #project1
    ap["{01}"]=Hash.new()
    ap["{01}"][:prefix]="STP"
    ap["{01}"][:name]="SeTuPe"
    #project2
    ap["{BF}"]=Hash.new()
    ap["{BF}"][:prefix]="MSP"
    ap["{BF}"][:name]="MuSePa"
    #project3
    ap["{03}"]=Hash.new()
    ap["{03}"][:prefix]="AGF"
    ap["{03}"][:name]="ArGoFi1"
    #project4
    ap["{04}"]=Hash.new()
    ap["{04}"][:prefix]="AGF"
    ap["{04}"][:name]="ArGoFi0"
    #prepare call
    hc=HelperClassForModules.new()
    #call the function
    sps=hc.projects_sorted_array_of_key(ap)
    #test
    assert(sps.count==4, "Projekt Anzahl stimmt nicht!")
    assert_equal("{04}",sps[0],"Falsch sortiert!")
    assert_equal("{03}",sps[1],"Falsch sortiert!")
    assert_equal("{BF}",sps[2],"Falsch sortiert!")
    assert_equal("{01}",sps[3],"Falsch sortiert!")
  end 
  
end