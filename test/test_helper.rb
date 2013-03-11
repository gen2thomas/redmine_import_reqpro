# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

class MyTestHelper
  
  def import_results
    return {:users => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                  :projects => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                  :trackers => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                  :versions => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                  :attributes => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                  :issues => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                  :issue_internal_relations => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                  :issue_external_relations => {:imported => 0, :updated => 0, :failed => 0, :sum =>0},
                  :sum => {:imported => 0, :updated => 0, :failed => 0, :sum =>0}
           }
  end
  
  def uploaded_test_file(name, mime)
    ActionController::TestUploadedFile.new(File.dirname(__FILE__) + "/files/#{name}", mime)
  end
  
  def known_attributes
    known_attributes = Hash.new
    #Issue attribute
    known_attributes["Author"] = Hash.new
    known_attributes["Author"][:custom_field_id] = ""
    #available custom fields of issues
    IssueCustomField.find(:all).each do |cu_fi|
      key = cu_fi[:name]
      known_attributes[key] = Hash.new
      known_attributes[key][:custom_field_id] = cu_fi[:id]
    end
    return known_attributes 
  end
  
  def version_map
    #ReqPro_ProjID=>ReqPro_Attr_Label
    version_map=Hash.new
    version_map["{0815}"]="rp_VersionForProj1"
    version_map["{0916}"]="rp_VersionForProj2"
    return version_map
  end
  
  def versions_mapping
    #proj_id=>attr_id
    versions_mapping=Hash.new
    versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"]=Hash.new
    versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"]= "{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}" #Developer
    return versions_mapping
  end
  
  def new_versions_mapping
    #[proj_id, version_name] => version
    new_versions_mapping=Hash.new
    new_versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"]=Hash.new
    version_name="OODev_first"
    new_versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"][version_name]=Version.find_by_name(version_name)
    version_name="OODev_second"
    new_versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"][version_name]=Version.find_by_name(version_name)
    version_name="OODev_third"
    new_versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"][version_name]=Version.find_by_name(version_name)
    version_name="OODev_fourth"
    new_versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"][version_name]=Version.find_by_name(version_name)
    version_name="OODev_fifth"
    new_versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"][version_name]=Version.find_by_name(version_name)
    version_name="OODev_sixth"
    new_versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"][version_name]=Version.find_by_name(version_name)
    version_name="OODev_seventh"
    new_versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"][version_name]=Version.find_by_name(version_name)
    return new_versions_mapping
  end
  
  def tracker_map
    #ReqPro_ReqType=>redmine_tracker_name
    tracker_map=Hash.new
    tracker_map["NEED"]="Defect"
    tracker_map["STRQ"]="Meine Story-mit erlaubten Zeichen"
    tracker_map["FUNC"]="Mei@ne>Func<mit)un(er;laub|ten&Zei$chen?"
    return tracker_map
  end
  
  def tracker_mapping
    #rt_prefix => [:tr_name]=>tracker.name{:tr_name=>"Mei_ne_Func_mit_un_er_laub_ten_Zei_chen_"}
    tracker_mapping=Hash.new
    tracker_mapping["NEED"]=Hash.new
    tracker_mapping["NEED"][:tr_name]="Defect" #already existend tracker in redmine
    tracker_mapping["NEED"][:trid]="1"
    tracker_mapping["TODO"]=Hash.new
    tracker_mapping["TODO"][:tr_name]="rm_TODO" #new tracker for redmine
    tracker_mapping["TODO"][:trid]="2"
    return tracker_mapping
  end
  
  def attributes_map
    #ReqPro_attribute=>redmine_issue_attribute_OR_custom_field
    attributes_map=Hash.new
    attributes_map["rp_Developer"]="rm_Developer"
    attributes_map["rp_Effort"]="rm_Effort"
    return attributes_map
  end
  
  def attributes_mapping
    #ReqPro_attribute=>{:attr_name => redmine_issue_attribute_OR_custom_field}
    attributes_mapping=Hash.new
    attributes_mapping["rp_Developer"]=Hash.new
    attributes_mapping["rp_Developer"][:attr_name]="rm_Developer"
    attributes_mapping["rp_Effort"]=Hash.new
    attributes_mapping["rp_Effort"][:attr_name]="rm_Effort"
    return attributes_mapping
  end
  
  def attributes_with_mapping
    attributes_with_mapping = self.attributes
    attributes_with_mapping.each do |attr_key, attr_val|
      attr_val[:mapping]="rp_Developer" if  attr_val[:attrlabel] == "Developer" #designed as version attribute
      attr_val[:mapping]="Effort" if  attr_val[:attrlabel] == "Effort (days)" #unknown icf
      attr_val[:mapping]="Status" if  attr_val[:attrlabel] == "Actual Iteration" #already known icf
    end
    return attributes_with_mapping
  end
  
  #Some RequPro attributes
  def attributes
    attributes=Hash.new
    #attr1
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"] = Hash.new
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:default] = ""
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:itemtext] = ""
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:itemlist] = Array.new
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:itemlist].push("Dev01")
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:itemlist].push("Dev02")
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:itemlist_used] = Array.new
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:attrlabel] = "Developer"
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:datatype] = "MultiSelect"
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:project] = "STP"
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:projectid] = "{065CCCD0-4129-497C-8474-27EBCD96065D}"
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:rtid] = "{P01RT01}"
    attributes["{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}"][:rtprefixes] = "NEED"
    #attr2
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"] = Hash.new
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"][:default] = "999"
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"][:itemtext] = "999"
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"][:itemlist] = Array.new
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"][:itemlist_used] = Array.new
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"][:attrlabel] = "Effort (days)"
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"][:datatype] = "Integer"
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"][:project] = "STP"
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"][:projectid] = "{065CCCD0-4129-497C-8474-27EBCD96065D}"
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"][:rtid] = "{P01RT02}"
    attributes["{A140FE86-A849-42B9-B71B-36DA2C67A85E}"][:rtprefixes] = "FEAT"
    #attr3
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"] = Hash.new
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:default] = ""
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:itemtext] = ""
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:itemlist] = Array.new
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:itemlist_used] = Array.new
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:attrlabel] = "Actual Iteration"
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:datatype] = "Integer"
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:project] = "MSP"
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:projectid] = "{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:rtid] = "{P02RT02}"
    attributes["{0E8304EF-59BF-440D-9315-5E56E523A58C}"][:rtprefixes] = "FUNC"
    #attr4
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"] = Hash.new
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"][:default] = "999"
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"][:itemtext] = "999"
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"][:itemlist] = Array.new
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"][:itemlist_used] = Array.new
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"][:attrlabel] = "Effort (days)"
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"][:datatype] = "Integer"
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"][:project] = "STP"
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"][:projectid] = "{065CCCD0-4129-497C-8474-27EBCD96065D}"
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"][:rtid] = "{P02RT03}"
    attributes["{51E59074-F681-44CA-9888-561861D2EBC0}"][:rtprefixes] = "NEED"      
    return attributes
  end
  
  def requirement_types
    requirement_types = Hash.new
    #RT "Need" of project1
    used_attributes1 = Array.new
    used_attributes1.push("{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}") #Developer
    used_attributes1.push("{51E59074-F681-44CA-9888-561861D2EBC0}") #Effort (days)
    requirement_types["{022D080E-A80B-48F4-B573-8C57DE8F3860}"] = Hash.new
    requirement_types["{022D080E-A80B-48F4-B573-8C57DE8F3860}"][:project] = "STP"
    requirement_types["{022D080E-A80B-48F4-B573-8C57DE8F3860}"][:name] = "User Need"
    requirement_types["{022D080E-A80B-48F4-B573-8C57DE8F3860}"][:prefix] = "NEED"
    requirement_types["{022D080E-A80B-48F4-B573-8C57DE8F3860}"][:attrids] = used_attributes1
    #RT "FUNC" of project2
    used_attributes2 = Array.new
    used_attributes2.push("{0E8304EF-59BF-440D-9315-5E56E523A58C}") #Actual Iteration
    requirement_types["{5E748E74-15E9-454E-8ACD-6D263D08E00F}"] = Hash.new
    requirement_types["{5E748E74-15E9-454E-8ACD-6D263D08E00F}"][:project] = "MSP"
    requirement_types["{5E748E74-15E9-454E-8ACD-6D263D08E00F}"][:name] = "Functionalities"
    requirement_types["{5E748E74-15E9-454E-8ACD-6D263D08E00F}"][:prefix] = "FUNC"
    requirement_types["{5E748E74-15E9-454E-8ACD-6D263D08E00F}"][:attrids] = used_attributes2
    #RT "Need" of project2
    used_attributes3 = Array.new
    used_attributes3.push("{895997FA-1A89-4470-ABB9-90ED4645858E}") #Developer
    used_attributes3.push("{04A20C42-647D-4F85-B803-474907FAE21A}") #Effort (days)
    requirement_types["{135E694F-67E6-45B5-A1C9-58477F5BBE6A}"] = Hash.new
    requirement_types["{135E694F-67E6-45B5-A1C9-58477F5BBE6A}"][:project] = "MSP"
    requirement_types["{135E694F-67E6-45B5-A1C9-58477F5BBE6A}"][:name] = "User Need"
    requirement_types["{135E694F-67E6-45B5-A1C9-58477F5BBE6A}"][:prefix] = "NEED"
    requirement_types["{135E694F-67E6-45B5-A1C9-58477F5BBE6A}"][:attrids] = used_attributes3
    return requirement_types
  end
  
  def some_projects
    data_pathes=get_data_pathes()
    #available projects
    ap=Hash.new
    ap["{065CCCD0-4129-497C-8474-27EBCD96065D}"]=Hash.new
    ap["{065CCCD0-4129-497C-8474-27EBCD96065D}"][:prefix]="STP"
    ap["{065CCCD0-4129-497C-8474-27EBCD96065D}"][:name]="Seltenes Testprojekt"
    ap["{065CCCD0-4129-497C-8474-27EBCD96065D}"][:path]=data_pathes[0]
    ap["{065CCCD0-4129-497C-8474-27EBCD96065D}"][:description]="An project stp for unit testing"
    ap["{065CCCD0-4129-497C-8474-27EBCD96065D}"][:date]="12-11-26"
    ap["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"]=Hash.new
    ap["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:prefix]="MPR3"
    ap["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:name]="MyProjectName3" #already existing name in Project.find(:all)
    ap["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:path]=data_pathes[1]
    ap["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:description]="An project msp for unit testing"
    ap["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:date]="12-11-27"
    ap["{0815A}"]=Hash.new
    ap["{0815A}"][:prefix]="PR1"
    ap["{0815A}"][:name]="MyProject_ForUser_asMember"
    ap["{0815A}"][:path]=data_pathes[2] #using non existend path
    ap["{0815A}"][:description]="An project PR1 for unit testing with members and wrong path"
    ap["{0815A}"][:date]="12-11-28"
    ap["{0915B}"]=Hash.new
    ap["{0915B}"][:prefix]="PR2"
    ap["{0915B}"][:name]="MyProject_Without_Path_Entry"
    ap["{0915B}"][:description]="An project PR2 for unit testing"
    ap["{0915B}"][:date]="12-11-29"
    return ap
  end
  
  def rpusers
    # rpusers
    rpus = Hash.new
    rpus["{01}"] = Hash.new
    rpus["{01}"][:project] = "PR1"
    rpus["{01}"][:email] = "usr1@mail.de" 
    rpus["{01}"][:login] = "usr_loginA"
    rpus["{01}"][:firstname] = "usr1_firstnam"
    rpus["{01}"][:lastname] = "usr1_Lastname"
    rpus["{01}"][:group] = "usr_grp"
    rpus["{01}"][:conf_key] = rpus["{01}"][:login]
    rpus["{02}"] = Hash.new
    rpus["{02}"][:project] = "PR1"
    rpus["{02}"][:email] = "usr2@mail.de" 
    rpus["{02}"][:login] = "usr_loginB"
    rpus["{02}"][:firstname] = "usr2_firstnam"
    rpus["{02}"][:lastname] = "usr2_Lastname"
    rpus["{02}"][:group] = "usr_grp"
    rpus["{02}"][:conf_key] = rpus["{02}"][:login]
    rpus["{03}"] = Hash.new
    rpus["{03}"][:project] = "PR1"
    rpus["{03}"][:email] = "usr3@mail.de" 
    rpus["{03}"][:login] = "usr_loginA"
    rpus["{03}"][:firstname] = "usr3_firstnam"
    rpus["{03}"][:lastname] = "usr3_Lastname"
    rpus["{03}"][:conf_key] = rpus["{03}"][:login]
    rpus["{03}"][:group] = "usr_grp"
    rpus["{04}"] = Hash.new
    rpus["{04}"][:project] = "PR2"
    rpus["{04}"][:email] = "usr4@mail.de" 
    rpus["{04}"][:login] = "usr_loginB"
    rpus["{04}"][:firstname] = "usr4_firstnam"
    rpus["{04}"][:lastname] = "usr4_Lastname"
    rpus["{04}"][:group] = "usr_grp"
    rpus["{04}"][:conf_key] = rpus["{04}"][:login]
    rpus["{05}"] = Hash.new
    rpus["{05}"][:project] = "PR2"
    rpus["{05}"][:email] = "usr0@mail.de" 
    rpus["{05}"][:login] = "usr_loginB"
    rpus["{05}"][:firstname] = "usr5_firstnam"
    rpus["{05}"][:lastname] = "usr5_Lastname"
    rpus["{05}"][:group] = "usr_grp"
    rpus["{05}"][:conf_key] = rpus["{05}"][:login]
    #already existend user while creation (no admin)
    rpus["{06}"] = Hash.new
    rpus["{06}"][:project] = "PR1"
    rpus["{06}"][:email] = "usr6@mail.de" 
    rpus["{06}"][:login] = "User02"
    rpus["{06}"][:firstname] = "usr6_firstnam"
    rpus["{06}"][:lastname] = "usr6_Lastname"
    rpus["{06}"][:group] = "usr_grp"
    rpus["{06}"][:conf_key] = rpus["{06}"][:login]
    #already existend user while creation (is an admin)
    rpus["{07}"] = Hash.new
    rpus["{07}"][:project] = "PR2"
    rpus["{07}"][:email] = "usr7@mail.de" 
    rpus["{07}"][:login] = "User01"
    rpus["{07}"][:firstname] = "usr7_firstnam"
    rpus["{07}"][:lastname] = "usr7_Lastname"
    rpus["{07}"][:group] = "usr_grp"
    rpus["{07}"][:conf_key] = rpus["{07}"][:login]
    return rpus
  end
  
  private
  
  def get_data_pathes
    #prepare data
    data_pathes = Array.new()
    path_to_samples=Dir.pwd + '/' + File.dirname(__FILE__) + '/samples'
    data_pathes.push(path_to_samples + '/Baseline01_App')
    data_pathes.push(path_to_samples + '/Baseline02_Mlc')
    data_pathes.push(path_to_samples + '/Baseline0815_PR1')
    return data_pathes
  end
end