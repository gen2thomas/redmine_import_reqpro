module ExtProjectsHelper
  
  def external_prefixes_to_string(external_projects_list)
    #get a list of external projects
    #collect all prefixes inside a string
    external_prefixes = ""
    external_projects_list.each_value do |ext_proj| 
      if external_prefixes.length > 0
        external_prefixes += ", "
      end
      external_prefixes += (ext_proj[:prefix]+ext_proj[:status])
    end
    return external_prefixes
  end
  
  def collect_external_projects(filepath, deep_check_ext_projects, available_projects)
    # "available_projects" --> available (self and external) projects
    #check for external projects
    # --> known external projects, status = "?" means unknown
    external_projects = collect_external_projects_fast(filepath)
    if deep_check_ext_projects
      # --> update status of external projects
      # --> needed external projects
      # "-": needed but not available
      # "*": not needed
      #search inside the local project files for external traces (TTo.EPGUID, TFrom.EPGUID)
      external_projects = update_status_for_needed_ext_projects(external_projects, filepath)
      #modify status of known external projects
      # "+": needed and available
      external_projects.each do |proj_key,proj_value|
        if available_projects[proj_key] != nil # available
          proj_value[:status]="+"
        else
          if proj_value[:status] == "?"
            proj_value[:status]="*" #not needed
          end
        end
      end
    end
    return external_projects
  end
  
private

  def collect_external_projects_fast(filepath)
    #get an data path to open an external project file
    #collect all prefixes and guids to an array of hash
    xmldocexternal = open_xml_file(filepath,"ExternalProjects.XML")
    external_projects = Hash.new
    xmldocexternal.elements.each("PROJECT/ExternalProject") do |ext_proj|
      hash_key =  ext_proj.attributes["GUID"]
      external_projects[hash_key] = Hash.new
      external_projects[hash_key] [:prefix] = ext_proj.attributes["Prefix"] 
      external_projects[hash_key] [:status] = "?"
    end
    return external_projects
  end
  
  def update_status_for_needed_ext_projects(external_projects, filepath)
    #search inside the files for external traces (TTo.EPGUID, TFrom.EPGUID)
    # change status for found GUID to "-" (needed but not available)
    # availability is checked later on
    all_files = collect_all_data_files(filepath)
    all_files.each do |filename|
      xmldoc = open_xml_file(filepath,filename)
      xmldoc.elements.each("PROJECT/Pkg/Requirements/Req/TFrom/TReq/EPGUID") do |e|
        if e.text != nil #not empty
          hash_key = e.text
          external_projects[hash_key][:status] = "-"
        end
      end
      xmldoc.elements.each("PROJECT/Pkg/Requirements/Req/TTo/TReq/EPGUID") do |e|
        if e.text != nil #not empty
          hash_key = e.text
          external_projects[hash_key][:status] = "-"
        end
      end
    end
    return external_projects
  end
    
end