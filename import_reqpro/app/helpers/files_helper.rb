module FilesHelper
  
  def list_all_data_files(collected_files)  
      # write out all XML-Files
      collected_files.each {|filename|
        puts filename
      }      
  end
  
  def collect_all_data_files(filepath)
    #change to the right data directory
    Dir.chdir(filepath)
    #get all XML files in that directory
    collect_files = Dir["**/**/*.XML"]
  end
  
  def string_data_pathes_to_array(filepath_as_string)
    #split filepathes in a string to each elemnt of an array
    actual_datas = Array.new
    filepath_as_string.split("\n").each do |path|
      actual_datas.insert(path.to_s)
    end
  end
  
  def open_xml_file(filepath, filename)
    actual_data_file = filepath + filename
    puts "Processing data file: " + actual_data_file
    xmlfile = File.new(actual_data_file)
    #REXML:: ist notwendig, da es scheinbar verschiedene Document.new() gibt
    xmldoc = REXML::Document.new(xmlfile)
  end
  
end