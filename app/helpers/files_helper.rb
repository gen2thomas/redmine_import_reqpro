module FilesHelper
  
  # write out all XML-File names
  def list_all_data_files(collected_files)
      collected_files.each {|filename|
        puts filename
      }      
  end
  
  # collect all data files of the given directory
  # including two subdirectory levels
  def collect_all_data_files(filepath)
    oldpath=Dir.pwd
    #change to the right data directory
    Dir.chdir(filepath)
    #get all XML files in that directory
    collect_files = Dir["**/**/*.XML"]
    #switch back to the old directory
    Dir.chdir(oldpath)
    return collect_files
  end
  
  #split filepathes in a string to each element of an array
  def string_data_pathes_to_array(filepath_as_string)
    actual_datas = Array.new
    filepath_as_string.split("\n").each do |path|
      actual_datas.insert(path.to_s)
    end
  end
  
  def open_xml_file(filepath, filename)
    oldpath=Dir.pwd
    #change to the right data directory
    Dir.chdir(filepath)
    puts "Processing data file: " + Dir.pwd + "/" + filename
    xmlfile = File.new(filename)
    #REXML:: ist notwendig, da es verschiedene Document.new() gibt
    xmldoc = REXML::Document.new(xmlfile)
    #switch back to the old directory
    Dir.chdir(oldpath)
    return xmldoc
  end
  
end