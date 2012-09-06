# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

class MyTestHelper
  
  def versions_mapping
    #proj_id=>attr_id
    versions_mapping=Hash.new
    versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"]=Hash.new
    versions_mapping["{065CCCD0-4129-497C-8474-27EBCD96065D}"]= "{4F29CB44-FBD9-4961-9BB2-0F64A3280EC8}" #Developer
    return versions_mapping
  end
  
  def tracker_mapping
    #rt_prefix=>attr_id
    tracker_mapping=Hash.new
    tracker_mapping["NEED"]=Hash.new
    tracker_mapping["NEED"][:tr_name]="Defect"
    return tracker_mapping
  end
  
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
    #available projects (only prefix and path needed at the moment)
    ap=Hash.new
    ap["{065CCCD0-4129-497C-8474-27EBCD96065D}"]=Hash.new
    ap["{065CCCD0-4129-497C-8474-27EBCD96065D}"][:prefix]="STP"
    ap["{065CCCD0-4129-497C-8474-27EBCD96065D}"][:path]=data_pathes[0]
    ap["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"]=Hash.new
    ap["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:prefix]="MSP"
    ap["{BFCD0B9E-E4B5-4B0A-8C59-F568269DCCE3}"][:path]=data_pathes[1]
    return ap
  end
  
  def rpusers
    # rpusers
    rpus = Hash.new
    rpus["{01}"] = Hash.new
    rpus["{01}"][:project] = "PR1"
    rpus["{01}"][:email] = "usr1_mail" 
    rpus["{01}"][:login] = "usr_loginA"
    rpus["{01}"][:firstname] = "usr1_firstnam"
    rpus["{01}"][:lastname] = "usr1_Lastname"
    rpus["{01}"][:group] = "usr_grp"
    rpus["{01}"][:conf_key] = rpus["{01}"][:login]
    rpus["{02}"] = Hash.new
    rpus["{02}"][:project] = "PR1"
    rpus["{02}"][:email] = "usr2_mail" 
    rpus["{02}"][:login] = "usr_loginB"
    rpus["{02}"][:firstname] = "usr2_firstnam"
    rpus["{02}"][:lastname] = "usr2_Lastname"
    rpus["{02}"][:group] = "usr_grp"
    rpus["{02}"][:conf_key] = rpus["{02}"][:login]
    rpus["{03}"] = Hash.new
    rpus["{03}"][:project] = "PR1"
    rpus["{03}"][:email] = "usr3_mail" 
    rpus["{03}"][:login] = "usr_loginA"
    rpus["{03}"][:firstname] = "usr3_firstnam"
    rpus["{03}"][:lastname] = "usr3_Lastname"
    rpus["{03}"][:conf_key] = rpus["{03}"][:login]
    rpus["{03}"][:group] = "usr_grp"
    rpus["{04}"] = Hash.new
    rpus["{04}"][:project] = "PR2"
    rpus["{04}"][:email] = "usr4_mail" 
    rpus["{04}"][:login] = "usr_loginB"
    rpus["{04}"][:firstname] = "usr4_firstnam"
    rpus["{04}"][:lastname] = "usr4_Lastname"
    rpus["{04}"][:group] = "usr_grp"
    rpus["{04}"][:conf_key] = rpus["{04}"][:login]
    rpus["{05}"] = Hash.new
    rpus["{05}"][:project] = "PR2"
    rpus["{05}"][:email] = "usr0_mail" 
    rpus["{05}"][:login] = "usr_loginB"
    rpus["{05}"][:firstname] = "usr5_firstnam"
    rpus["{05}"][:lastname] = "usr5_Lastname"
    rpus["{05}"][:group] = "usr_grp"
    rpus["{05}"][:conf_key] = rpus["{05}"][:login]
    return rpus
  end
  
  private
  
  def get_data_pathes
    #prepare data
    data_pathes = Array.new()
    path_to_samples=Dir.pwd + '/' + File.dirname(__FILE__) + '/samples'
    data_pathes.push(path_to_samples + '/Baseline01_App')
    data_pathes.push(path_to_samples + '/Baseline02_Mlc')
    return data_pathes
  end
end