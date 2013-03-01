require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/../../app/helpers/ext_projects_helper'
require 'mocha'

class HelperClassForModules
  include FilesHelper
  include ExtProjectsHelper
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

class TcExtProjectsHelper < ActiveSupport::TestCase
  
  def test_collect_external_projects_fast
    puts "test_collect_external_projects_fast"
    #prepare data
    path_to_samples=Dir.pwd + '/' + File.dirname(__FILE__) + '/../samples'
    data_path=path_to_samples + '/Baseline01_App'
    #prepare call of private function
    HelperClassForModules.class_eval{def cepf(a,b) return collect_external_projects_fast(a,b) end}
    hc=HelperClassForModules.new()
    #call return a hash
    eps=hc.cepf(data_path, hc.loglevel_high())
    assert(eps.count==2, "Es sollten genau 2 Projekte sein!")
    p1=eps["{D8365C50-839F-49A9-BC66-E400921E7D47}"]
    assert(p1!=nil, "Falsches Projekt 1!")
    if p1!= nil
      assert(p1[:prefix]=="NFL", "Falscher Prefix Projekt 1!")
      assert(p1[:status]=="?", "Falscher Status Projekt 1!")        
    end
    
    p2=eps["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"]
    assert(p2!=nil, "Falsches Projekt 2!")
    if p2!= nil
      assert(p2[:prefix]=="MSP", "Falscher Prefix Projekt 2!")
      assert(p2[:status]=="?", "Falscher Status Projekt 2!")
    end
  end 
  
  def test_update_status_for_needed_ext_projects
    puts "test_update_status_for_needed_ext_projects"
    #prepare data
    eps=Hash.new
    eps["{D8365C50-839F-49A9-BC66-E400921E7D47}"]=Hash.new
    eps["{D8365C50-839F-49A9-BC66-E400921E7D47}"][:prefix]="NFL"
    eps["{D8365C50-839F-49A9-BC66-E400921E7D47}"][:status]="?"
    eps["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"]=Hash.new
    eps["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:prefix]="MSP"
    eps["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:status]="?"
    path_to_samples=Dir.pwd + '/' + File.dirname(__FILE__) + '/../samples'
    data_path=path_to_samples + '/Baseline01_App'
    #prepare call of private function
    HelperClassForModules.class_eval{def usfnep(a,b,c) return update_status_for_needed_ext_projects(a,b,c) end}
    hc=HelperClassForModules.new()
    #call will return a hash
    eps=hc.usfnep(eps,data_path,hc.loglevel_high())
    #tests
    assert_equal("-",eps["{D8365C50-839F-49A9-BC66-E400921E7D47}"][:status], "Status von externem Projekt 1 nicht korrigiert!")
    assert_equal("-",eps["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:status], "Status von externem Projekt 2 nicht korrigiert!")
  end
  
  def test_external_prefixes_to_string
    puts "test_external_prefixes_to_string"
    #prepare data
    eps=Hash.new
    eps["{D8}"]=Hash.new
    eps["{D8}"][:prefix]="NFL"
    eps["{D8}"][:status]="?"
    eps["{BF}"]=Hash.new
    eps["{BF}"][:prefix]="MSP"
    eps["{BF}"][:status]="+"
    #prepare call
    hc=HelperClassForModules.new()
    epsstring=hc.external_prefixes_to_string(eps)
    #tests
    assert("NFL?, MSP+"==epsstring || "MSP+, NFL?"==epsstring,"Daten im ext Projekt-String nicht korrekt!")
  end
  
  def test_collect_external_projects
    puts "test_collect_external_projects"
    #prepare data
    eps=Hash.new
    eps["{D8}"]=Hash.new
    eps["{D8}"][:prefix]="NFL"
    eps["{D8}"][:status]="?"
    eps["{BF}"]=Hash.new
    eps["{BF}"][:prefix]="MSP"
    eps["{BF}"][:status]="?"
    eps["{AF}"]=Hash.new
    eps["{AF}"][:prefix]="AGR"
    eps["{AF}"][:status]="?"
    #make a deep copy of eps
    eps2 = Marshal.load(Marshal.dump(eps))
    eps2["{D8}"][:status]="-" #needed
    eps2["{BF}"][:status]="-" #needed (later on not available)
    eps2["{AF}"][:status]="?" #not available, not needed
    #available projects
    ap=Hash.new
    ap["{D8}"]=Hash.new
    #prepare stubs and call
    hc=HelperClassForModules.new()  
    #stub the not to test methode
    #external_projects = collect_external_projects_fast(filepath)
    hc.stubs(:collect_external_projects_fast).returns(eps)
    #stub the not to test methode
    #external_projects = update_status_for_needed_ext_projects(external_projects, filepath)
    hc.stubs(:update_status_for_needed_ext_projects).returns(eps2)
    #call
    ep=hc.collect_external_projects("any_path", true, ap, hc.loglevel_high())
    assert_equal("+", ep["{D8}"][:status], "NFL muss verfügbar sein!")
    assert_equal("-", ep["{BF}"][:status], "MSP muss nicht verfügbar sein!")
    assert_equal("*", ep["{AF}"][:status], "AGR muss nicht benoetigt sein!")
  end
end