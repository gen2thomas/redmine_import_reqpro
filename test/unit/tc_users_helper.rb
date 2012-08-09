require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/../../app/helpers/users_helper'
require 'mocha'

class HelperClassForModules
  include UsersHelper
  include FilesHelper
end

class TcUsersHelper < ActiveSupport::TestCase
  self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
  fixtures :users, :custom_values
  
  def test_user_prerequisites
    puts "test_user_prerequisites"
    assert_equal(6,User.find(:all).count, "User nicht korrekt")
    assert_equal(12,CustomValue.find(:all).count, "CustomValue nicht korrekt")
  end

  def test_collect_rpusers
    puts "test_collect_rpusers"
    #prepare call
    hc=HelperClassForModules.new
    #stub the not to test methode
    #users = collect_users_fast(some_projects, conflate_users)
    hc.stubs(:collect_users_fast).returns(User.find_by_id(1))
    usr=hc.collect_rpusers(nil,nil)
    assert_equal(User.find_by_id(1),usr)
  end
    
  def test_collect_users_fast
    puts "test_collect_users_fast"
    #prepare data
    mth=MyTestHelper.new()
    #available projects (only prefix and path needed)
    ap=mth.some_projects()
    #prepare call of private function
    HelperClassForModules.class_eval{def cuf(a,b) return collect_users_fast(a,b) end}
    hc=HelperClassForModules.new
    #stub the not to test methode
    #fullname = get_fullname(user.attributes["FullName"], users[hash_key] [:email], users[hash_key] [:login])
    fn=Hash.new()
    fn[:firstname]="Vorname"
    fn[:lastname]="Nachname"
    hc.stubs(:get_fullname).returns(fn)
    #test for conflation: "email"
    su=hc.cuf(ap,"email")
    assert_equal(11,su.count,"Falsche Anzahl User!")
    u1=su["{DB0B60C4-70BE-4BD0-A55F-289CD21FAB3C}"]
    assert_equal("STP",u1[:project],"Falsches Projekt für user1")
    assert_equal("Vorname5Nachname5@supa-usr.de",u1[:conf_key],"Falscher conf_key -email- user1")
    u2=su["{0768C722-64AD-4AE3-884A-B39B97B19F29}"]
    assert_equal("MSP",u2[:project],"Falsches Projekt für user2")
    assert_equal("Vorname7Nachname7@supa-usr.de",u2[:conf_key],"Falscher conf_key -email- user2")
    #test for conflation: "login"
    su=hc.cuf(ap,"login")
    assert_equal(11,su.count,"Falsche Anzahl User!")
    u1=su["{9FA86666-A3FF-453A-A066-EFA5CCA65AC4}"]
    assert_equal("STP",u1[:project],"Falsches Projekt für user1")
    assert_equal("Nachname6",u1[:conf_key],"Falscher conf_key -login- user1")
    u2=su["{0BEBBAEB-D9AC-4AD7-8291-A4E6291B83BC}"]
    assert_equal("MSP",u2[:project],"Falsches Projekt für user2")
    assert_equal("Nachname5",u2[:conf_key],"Falscher conf_key -login- user2")
    #test for conflation: "name"
    su=hc.cuf(ap,"name")
    assert_equal(11,su.count,"Falsche Anzahl User!")
    u1=su["{16AA815A-4174-412A-947C-037F69A327B9}"]
    assert_equal("STP",u1[:project],"Falsches Projekt für user1")
    assert_equal("Vorname Nachname",u1[:conf_key],"Falscher conf_key -name- user1")
    u2=su["{3F7D2B87-D519-4BD9-AC5F-B931C5DE7801}"]
    assert_equal("MSP",u2[:project],"Falsches Projekt für user2")
    assert_equal("Vorname Nachname",u2[:conf_key],"Falscher conf_key -name- user2")
    #test for conflation: "none"
    su=hc.cuf(ap,nil)
    assert_equal(11,su.count,"Falsche Anzahl User!")
    u1=su["{5481430E-6FF7-404F-AFF4-617D230937E3}"]
    assert_equal("STP",u1[:project],"Falsches Projekt für user1")
    assert_equal("STP.Nachname3.Vorname3Nachname3@upusr.de",u1[:conf_key],"Falscher conf_key user1")
    u2=su["{1BCB3BC3-3620-459F-89DE-6DB5402031EE}"]
    assert_equal("MSP",u2[:project],"Falsches Projekt für user2")
    assert_equal("MSP.Nachname1.Vorname1Nachname1@supa-usr.de",u2[:conf_key],"Falscher conf_key user2")
  end
  
  def test_create_user_custom_field_for_rpuid
    puts "test_create_user_custom_field_for_rpuid"
    #prepare data
    ucf_count=UserCustomField.find(:all).count
    #prepare call
    hc=HelperClassForModules.new()
    #call
    ucf1 = hc.create_user_custom_field_for_rpuid(true)
    #test 1
    assert(ucf1!=nil, "ucf1 is nil!")
    if ucf1!=nil
      assert(ucf1[:name]=="RPUID", "ucf1 name must be RPUID!")
    end
    assert(ucf_count+1 == UserCustomField.find(:all).count, "ucf1 has to be added!")
    #prepare
    ucf1_id=ucf1.id
    #call
    ucf2 = hc.create_user_custom_field_for_rpuid(true)
    #test 2
    assert(ucf_count+1 == UserCustomField.find(:all).count, "ucf2 must not be added!")
    assert(ucf2[:id]==ucf1_id, "ucf1 id must be the same like ucf2!")
  end
    
  def test_user_find_by_rpuid
    puts "test_user_find_by_rpuid"
    #prepare custom values done by fixture
    #prepare users done by fixture
    #prepare call
    hc=HelperClassForModules.new()
    #function call
    usr_1=hc.user_find_by_rpuid("{30}") #known user
    usr_2=hc.user_find_by_rpuid("{03}") #same ID also for an Issue
    usr_nil = hc.user_find_by_rpuid("{01234}") #unknown rpuid
    no_usr = hc.user_find_by_rpuid("{10}") #wrong customized_type (Project)
    #test
    assert_equal(User.find_by_id(1), usr_1, "User 1 not found by ID!")
    assert_equal(User.find_by_id(3), usr_2, "User 2 not found by ID!")
    assert_nil(usr_nil, "usr_nil not nil!")
    assert_nil(no_usr, "no_usr not nil!")
  end
  
  def test_find_user_by_string
    puts "test_find_user_by_string"
    #prepare data
    sus=Hash.new
    sus["{01}"]=Hash.new
    sus["{01}"][:firstname]="Vorname1"
    sus["{01}"][:lastname]="Nachname1"
    sus["{01}"][:rmuser]=User.find_by_id(1) #test user for best level
    sus["{02}"]=Hash.new
    sus["{02}"][:firstname]="zz**Vorname1Nachname1++99"
    sus["{02}"][:lastname]="VollEgal"
    sus["{02}"][:rmuser]=User.find_by_id(2) #test user for second level
    sus["{03}"]=Hash.new
    sus["{03}"][:firstname]="VollEgal"
    sus["{03}"][:lastname]="Nachname1"
    sus["{03}"][:rmuser]=User.find_by_id(3) #test user for third level
    #prepare call
    hc=HelperClassForModules.new()
    #stub the not to test methode
    #fullname = get_fullname(user.attributes["FullName"], users[hash_key] [:email], users[hash_key] [:login])
    fn=Hash.new()
    fn[:firstname]="Vorname1"
    fn[:lastname]="Nachname1"
    hc.stubs(:get_fullname).returns(fn)
    #call for first level
    puts "test_find_user_by_string ***best level***"
    rmusr=hc.find_user_by_string("Any", sus)
    assert_equal(User.find_by_id(1),rmusr, "Falscher Redmine-User gefunden!")
    #prepare and call for second level
    puts "test_find_user_by_string ***second level***"
    sus["{01}"][:firstname]="Otto"
    rmusr=hc.find_user_by_string("Any", sus)
    assert_equal(User.find_by_id(2),rmusr, "Falscher Redmine-User gefunden!")
    #prepare and call for third level
    puts "test_find_user_by_string ***third level***"
    sus["{01}"][:lastname]="Meier"
    sus["{02}"][:firstname]="Hugo"
    rmusr=hc.find_user_by_string("Any", sus)
    assert_equal(User.find_by_id(3),rmusr, "Falscher Redmine-User gefunden!")
    #prepare and call for last level (firstname and lastname match)
    puts "test_find_user_by_string ***last level -lastname and firstname match in login-***"
    sus["{03}"][:lastname]="Lehmann"
    rmusr=hc.find_user_by_string("Any", sus)
    assert_equal(User.find_by_id(4),rmusr, "Falscher Redmine-User gefunden!")
    #prepare and call for fourth level (lastname match in login)
    puts "test_find_user_by_string ***last level -lastname match in login-***"
    fn[:lastname]="Nachname5Login"
    rmusr=hc.find_user_by_string("Any", sus)
    assert_equal(User.find_by_id(5),rmusr, "Falscher Redmine-User gefunden!")
    #prepare and call for fourth level (firstname match in login)
    puts "test_find_user_by_string ***last level -firstname match in login-***"
    fn[:lastname]="Vorname6Login"
    rmusr=hc.find_user_by_string("Any", sus)
    assert_equal(User.find_by_id(6),rmusr, "Falscher Redmine-User gefunden!")
  end
  
  def test_get_fullname()
    puts "test_get_fullname"
    #prepare call
    hc=HelperClassForModules.new
    #case 1: name: space is the delimiter
    fn=hc.get_fullname("fn ln","fnm.lnm@usr.de", "fnllnllogin")
    assert_equal("Fn",fn[:firstname],"case1 Vorname falsch!")
    assert_equal("Ln",fn[:lastname],"case1 Vorname falsch!")
    #case 2a: name: uppercase letters are the delimiter
    fn=hc.get_fullname("FnLn","fnm.lnm@usr.de", "fnllnllogin")
    assert_equal("Fn",fn[:firstname],"case2a Vorname falsch!")
    assert_equal("Ln",fn[:lastname],"case2a Nachname falsch!")
    #case 2b: name: uppercase letter of lastname is the delimiter
    fn=hc.get_fullname("fnLn","fnm.lnm@usr.de", "fnllnllogin")
    assert_equal("Fn",fn[:firstname],"case2b Vorname falsch!")
    assert_equal("Ln",fn[:lastname],"case2b Nachname falsch!")
    #case 3a: mail: dot is the delimiter
    fn=hc.get_fullname("fnln","fnm.lnm@usr.de", "fnllnllogin")
    assert_equal("Fnm",fn[:firstname],"case3a Vorname falsch!")
    assert_equal("Lnm",fn[:lastname],"case3a Nachname falsch!")
    #case 3b: mail: uppercase letter of lastname is the delimiter
    fn=hc.get_fullname("fnln","fnmLnm@usr.de", "fnllnllogin")
    assert_equal("Fnm",fn[:firstname],"case3b Vorname falsch!")
    assert_equal("Lnm",fn[:lastname],"case3b Nachname falsch!")
    #case 4: mail: login for lastname inside mail
    fn=hc.get_fullname("fnln","fnmlnlogin@usr.de", "lnlogin")
    assert_equal("Fnm",fn[:firstname],"case4 Vorname falsch!")
    assert_equal("Lnlogin",fn[:lastname],"case4 Nachname falsch!")
    #case 5: mail: login inside mail NOT found, firstname@lastname.de
    fn=hc.get_fullname("fnln","fnm@lnm.de", "fnlnlogin")
    assert_equal("Fnm",fn[:firstname],"case5 Vorname falsch!")
    assert_equal("Lnm",fn[:lastname],"case5 Nachname falsch!")
    #case 6: nothing else found
    fn=hc.get_fullname("fnln","", "fnlnlogin")
    assert_equal("Firstname",fn[:firstname],"case6 Vorname falsch!")
    assert_equal("Fnln",fn[:lastname],"case6 Nachname falsch!")
  end
  
  def test_update_rpusers_for_map_needing
    puts "test_update_rpusers_for_map_needing"
    #prepare data, conflation key is the "login"
    #rmusers
    rmus = Hash.new
    rmus[:rmusers] = Array.new
    rmus[:key_for_view] = Array.new
    User.find(:all).each do |usr|
     rmus[:key_for_view].push(usr[:login])
     rmus[:rmusers].push(usr)
    end
    # rpusers
    rpus = Hash.new
    rpus["{01}"] = Hash.new
    rpus["{01}"][:email] = "usr1_mail"
    rpus["{01}"][:login] = "usr1_login"
    rpus["{01}"][:conf_key] = rpus["{01}"][:login]
    rpus["{02}"] = Hash.new
    rpus["{02}"][:email] = "usr2_mail" 
    rpus["{02}"][:login] = "usr2_login"
    rpus["{02}"][:conf_key] = rpus["{02}"][:login]
    rpus["{03}"] = Hash.new
    rpus["{03}"][:email] = "usr3_mail" 
    rpus["{03}"][:login] = "usr3_login"
    rpus["{03}"][:conf_key] = rpus["{03}"][:login]
    rpus["{04}"] = Hash.new
    rpus["{04}"][:email] = "usr4_mail"
    rpus["{04}"][:login] = "usr4_login"
    rpus["{04}"][:conf_key] = rpus["{04}"][:login]
    # mapping
    umap=Hash.new
    umap["usr1_login"]="Nachname5Login"
    umap["usr2_login"]="User03"
    umap["usr4_login"]="NotExistend"
    #prepare call
    hc=HelperClassForModules.new  
    rpus_new=hc.update_rpusers_for_map_needing(rpus, rmus, umap, true)
    #test
    assert_equal(3,rpus_new.count, "Ein User muss gelöscht sein!")
    assert_equal(nil, rpus_new["{03}"], "User3 muss gelöscht sein!")
    assert_equal(User.find_by_id(5),rpus_new["{01}"][:rmuser], "User 5 nicht zugeordnet!")
    assert_equal(User.find_by_id(3),rpus_new["{02}"][:rmuser], "User 2 nicht zugeordnet!")
    assert_equal(nil,rpus_new["{04}"][:rmuser], "User 4 darf nicht zugeordnet sein!")
  end
  
  def test_remap_users_to_conflationkey
    puts "test_remap_users_to_conflationkey"
    #prepare data
    mth=MyTestHelper.new()
    rpus=mth.rpusers()
    #prepare call
    hc=HelperClassForModules.new
    rpus_new=hc.remap_users_to_conflationkey(rpus)
    #test
    assert_equal(2,rpus_new.count, "Zwei User müssen gefunden sein sein!")
    assert_equal(1, rpus_new["usr_loginA"][:logins].count, "1 login darf nur unter loginA sein!")
    assert_equal(1, rpus_new["usr_loginB"][:logins].count, "1 login darf nur unter loginB sein!")
    assert_equal(2, rpus_new["usr_loginA"][:names].count, "2 User-Namen müssen unter loginA sein!")
    assert_equal(3, rpus_new["usr_loginB"][:names].count, "3 User-Namen müssen unter loginB sein!")
    assert_equal(1, rpus_new["usr_loginA"][:projects].count, "1 Projekte müssen unter loginA sein!")
    assert_equal(2, rpus_new["usr_loginB"][:projects].count, "2 Projekte müssen unter loginB sein!")
    assert_equal(2, rpus_new["usr_loginA"][:emails].count, "2 Mails müssen unter loginA sein!")
    assert_equal(3, rpus_new["usr_loginB"][:emails].count, "3 Mails müssen unter loginB sein!")
    assert_equal(1, rpus_new["usr_loginA"][:groups].count, "1 Gruppen müssen unter loginA sein!")
    assert_equal(1, rpus_new["usr_loginB"][:groups].count, "1 Gruppen müssen unter loginB sein!")
    #test for sort
    assert_equal("usr0_mail", rpus_new["usr_loginB"][:emails][0], "Mails müssen für loginB sortiert sein!")
    assert_equal("usr2_mail", rpus_new["usr_loginB"][:emails][1], "Mails müssen für loginB sortiert sein!")
    assert_equal("usr4_mail", rpus_new["usr_loginB"][:emails][2], "Mails müssen für loginB sortiert sein!")
  end
  
end