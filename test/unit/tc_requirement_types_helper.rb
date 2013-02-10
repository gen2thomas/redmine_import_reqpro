require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/../../app/helpers/requirement_types_helper'

class HelperClassForModules
  include RequirementTypesHelper
  include FilesHelper
end

class TcRequirementTypesHelper < ActiveSupport::TestCase 
   
  def test_collect_requirement_types
    puts "test_collect_requirement_types"
    rts = Hash.new
    rts["{01}"] = Hash.new
    rts["{01}"][:default]
    #prepare call
    hc=HelperClassForModules.new
    #stub the not to test methodes
    #requirement_types = collect_requirement_types_fast(some_projects)
    #requirement_types = update_requ_types_for_reqpro_needing(requirement_types, some_projects)
    hc.stubs(:collect_requirement_types_fast).returns(rts)
    hc.stubs(:update_requ_types_for_reqpro_needing).returns(rts)
    #call
    rts2=hc.collect_requirement_types(nil,true, hc.loglevel_high())
    #test
    assert_equal(rts,rts2,"Uebergabe unsauber!")
  end
  
  def test_remap_req_types_to_project_prefix_noconf
    puts "test_remap_req_types_to_project_prefix without conflation"
    #prepare data
    mth=MyTestHelper.new()
    rtys=mth.requirement_types()
    #prepare call
    hc=HelperClassForModules.new()
    rt4view=hc.remap_req_types_to_project_prefix(rtys, false)
    #test
    assert(rt4view["stp_NEED"][:projects].include?("STP"), "Falsches Projekt gemappt!")
    assert(rt4view["msp_NEED"][:projects].include?("MSP"), "Falsches Projekt gemappt!")
    assert_equal("User Need", rt4view["stp_NEED"][:name], "Falscher ReqType gemappt!")
    assert_equal("User Need", rt4view["msp_NEED"][:name], "Falscher ReqType gemappt!")
    assert(rt4view["msp_FUNC"][:projects].include?("MSP"), "Falsches Projekt gemappt!")
    assert_equal("Functionalities", rt4view["msp_FUNC"][:name], "Falsches ReqType gemappt!")
  end
  
  def test_remap_req_types_to_project_prefix_conf
    puts "test_remap_req_types_to_project_prefix with conflation"
    #prepare data
    mth=MyTestHelper.new()
    rtys=mth.requirement_types()
    #prepare call
    hc=HelperClassForModules.new()
    rt4view=hc.remap_req_types_to_project_prefix(rtys, true)
    #test
    assert(rt4view["NEED"][:projects].include?("STP"), "Falsches Projekt gemappt!")
    assert(rt4view["NEED"][:projects].include?("MSP"), "Falsches Projekt gemappt!")
    assert_equal("User Need", rt4view["NEED"][:name], "Falscher ReqType gemappt!")
    assert(rt4view["FUNC"][:projects].include?("MSP"), "Falsches Projekt gemappt!")
    assert_equal("Functionalities", rt4view["FUNC"][:name], "Falsches ReqType gemappt!")
  end
  
  def test_update_requ_types_for_map_needing
    puts "test_update_requ_types_for_map_needing"
    #prepare data
    mth=MyTestHelper.new()
    rtys=mth.requirement_types()
    tmap=mth.tracker_mapping()
    #prepare call
    hc=HelperClassForModules.new()
    rtlist=hc.update_requ_types_for_map_needing(rtys, tmap)
    assert_equal(2, rtlist.count, "Es müssen genau 2 rt in der Liste sein!")
    assert_equal("Defect", rtlist["{135E694F-67E6-45B5-A1C9-58477F5BBE6A}"][:mapping],"Mapping muss auf Defect zeigen!")
    assert_equal("Defect", rtlist["{022D080E-A80B-48F4-B573-8C57DE8F3860}"][:mapping],"Mapping muss auf Defect zeigen!")
  end
  
  def test_make_attr_list_from_requirement_types
    puts "test_make_attr_list_from_requirement_types"
    #prepare data
    mth=MyTestHelper.new()
    rtys=mth.requirement_types()
    #prepare call
    hc=HelperClassForModules.new()
    attlist=hc.make_attr_list_from_requirement_types(rtys)
    assert_equal(5, attlist.count, "Es müssen genau 3 atts in der Liste sein!")
    assert_equal("{022D080E-A80B-48F4-B573-8C57DE8F3860}", attlist["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"],"Developer P1 muss von NEED P1 sein!")
    assert_equal("{135E694F-67E6-45B5-A1C9-58477F5BBE6A}", attlist["{04A20C42-647D-4F85-B803-474907FAE21A}"],"Effort P2 muss von NEED P2 sein!")
    assert_equal("{135E694F-67E6-45B5-A1C9-58477F5BBE6A}", attlist["{895997FA-1A89-4470-ABB9-90ED4645858E}"],"Developer P2 muss von NEED P2 sein!")
    assert_equal("{022D080E-A80B-48F4-B573-8C57DE8F3860}", attlist["{51E59074-F681-44CA-9888-561861D2EBC0}"],"Effort P1 muss von NEED P1 sein!")
    assert_equal("{5E748E74-15E9-454E-8ACD-6D263D08E00F}", attlist["{0E8304EF-59BF-440D-9315-5E56E523A58C}"],"Actual Iteration muss von FUNC sein!")
  end
  
  def test_collect_requirement_types_fast
    puts "test_collect_requirement_types_fast"
    #prepare data
    mth=MyTestHelper.new()
    sop=mth.some_projects()
    #prepare call of private function
    HelperClassForModules.class_eval{def crtf(a,b) return collect_requirement_types_fast(a,b) end}
    hc=HelperClassForModules.new()
    retys=hc.crtf(sop, hc.loglevel_high())
    #test
    assert_equal(10, retys.count, "Es sollten genau 10 RequTypes in der Liste stehen!")
    #rety1 STP.NEED
    rety1=retys["{022D080E-A80B-48F4-B573-8C57DE8F3860}"]
    assert_equal("STP", rety1[:project], "Project muss STP sein!")
    assert_equal("NEED", rety1[:prefix], "Prefix muss NEED sein!")
    assert_equal(8, rety1[:attrids].count, "STP.NEED hat genau 8 Attribute!")
    #rety2 MSP.TC
    rety2=retys["{2A6D0DFE-DD3D-4479-B4F2-04BE899B1D9B}"]
    assert_equal("MPR3", rety2[:project], "Project muss MPR3 sein!")
    assert_equal("TC", rety2[:prefix], "Prefix muss TC sein!")
    assert_equal(16, rety2[:attrids].count, "MSP.TC hat genau 16 Attribute!")
  end
  
  def test_update_requ_types_for_reqpro_needing
    puts "test_update_requ_types_for_reqpro_needing"
    #prepare data
    mth=MyTestHelper.new()
    sop=mth.some_projects()
    rety=mth.requirement_types()
    #prepare call of private function
    HelperClassForModules.class_eval{def urtfrn(a,b,c) return update_requ_types_for_reqpro_needing(a,b,c) end}
    hc=HelperClassForModules.new()
    retys=hc.urtfrn(rety, sop, hc.loglevel_high())
    #test
    assert_equal(1, retys.count, "Genau ein RequType muss genutzt sein")
    assert_equal("NEED", retys["{022D080E-A80B-48F4-B573-8C57DE8F3860}"][:prefix], "Es muss der NEED sein!")
    assert_equal(nil, retys["{022D080E-A80B-48F4-B573-8C57DE8F3860}"][:status], "Status muss geloescht sein!")
    assert_equal(2, retys["{022D080E-A80B-48F4-B573-8C57DE8F3860}"][:attrids].count, "2 Attribute müssen da sein!")
  end
end