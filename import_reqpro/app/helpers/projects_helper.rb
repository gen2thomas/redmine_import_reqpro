module ProjectsHelper
  
  def collect_projects(data_pathes, deep_check_ext_projects)
    # generate the projects content
    available_projects = collect_available_projects(data_pathes)
    # add external projects
    available_projects.each_value do |a_project|
      data_path = a_project[:path]
      #check for external projects
      external_projects = collect_external_projects(data_path, deep_check_ext_projects, available_projects)
      external_prefixes = external_prefixes_to_string(external_projects)
      a_project[:extprefixes] = external_prefixes
    end
    return available_projects
  end
  
  def collected_projects_to_content_array(some_projects)
    some_projects_content = Array.new
    idx = 0
    some_projects.each_value do |project| 
      some_projects_content.push([idx,project[:name],project[:description], project[:prefix], project[:date],project[:extprefixes]])
      idx += 1
    end
    return some_projects_content
  end
  
private

  def collect_available_projects(data_pathes)
    #collect all GUID and prefixes of all available projects
    available_projects = Hash.new
    data_pathes.each do |data_path|
    (
      xmldocmain = open_xml_file(data_path,"Project.XML")
      hash_key = xmldocmain.elements["Project"].attributes["ID"]
      if available_projects[hash_key] == nil # not already known
        available_projects[hash_key] = Hash.new
        available_projects[hash_key] [:prefix] = xmldocmain.elements["Project"].attributes["Prefix"]
        available_projects[hash_key] [:path] = data_path
        available_projects[hash_key] [:author_rpid] = xmldocmain.elements["Project"].attributes["AuthorGUID"]
        available_projects[hash_key] [:name] = xmldocmain.elements["Project"].attributes["Name"]
        available_projects[hash_key] [:description] = xmldocmain.elements["Project"].attributes["Description"]
        available_projects[hash_key] [:prefix] = xmldocmain.elements["Project"].attributes["Prefix"]
        available_projects[hash_key] [:date] = xmldocmain.elements["Project"].attributes["VersionDateTime"]
      end
    )
    end
    return available_projects    
  end
  
end