require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/../../app/helpers/files_helper'

class HelperClassForModules
  include FilesHelper
end

class TcFilesHelper < ActiveSupport::TestCase 
    
  def test_collect_all_data_files
    puts "test_collect_all_data_files"
    #prepare call
    hc=HelperClassForModules.new()
    cf= hc.collect_all_data_files(File.dirname(__FILE__) + '/../samples')
    assert_equal(8, cf.count, "Es sollten genau 8 Dateien sein!")
    assert(cf.include?("Baseline02_Mlc/Project.XML"), "Datei fehlt")
    assert(cf.include?("Baseline01_App/Project.XML"), "Datei fehlt")
  end
  
  def test_string_data_pathes_to_array
    puts "test_string_data_pathes_to_array"
    #prepare call
    hc=HelperClassForModules.new()
    cdp = hc.string_data_pathes_to_array("d1/d11/f111\n/d2/f21\n/d3/f31")
    assert_equal(cdp.count, 3, "Es sollten genau 3 Dateipfade sein!")
    assert(cdp.include?("d1/d11/f111"), "Pfad fehlt: d1/d11/f111")
    assert(cdp.include?("/d2/f21"), "Pfad fehlt: /d2/f21")
    assert(cdp.include?("/d3/f31"), "Pfad fehlt: /d3/f31")
  end
  
  def test_open_xml_file
    puts "test_open_xml_file"
    #prepare call
    hc=HelperClassForModules.new()
    xd=hc.open_xml_file(File.dirname(__FILE__) + '/../samples/Baseline02_Mlc/', "Project.XML")
    assert(xd!=nil, "XDocument ist nicht vorhanden!")
    assert_equal("Multisprayer-Painting-Entwicklung", xd.elements["Project"].attributes["Description"], "Inhalt stimmt nicht!")
  end  
end