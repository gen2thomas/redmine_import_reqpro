module RequirementTypesHelper
  
  def collect_requirement_types(some_projects, deep_check_req_types, loglevel)
    requirement_types = collect_requirement_types_fast(some_projects, loglevel)
    if deep_check_req_types
      requirement_types = update_requ_types_for_reqpro_needing(requirement_types, some_projects, loglevel)
    end
    return requirement_types
  end
  
  # remap prefixes to key: .project+_+:prefix
  # fill in only needed or not tested req types (status = "+" or "?")
  # * conflate_req_types == true --> project is not used for key (all projects have (nearly) the same req_types)
  def remap_req_types_to_project_prefix(requirement_types, conflate_req_types)
    remaped_req_types = Hash.new
    requirement_types.each_pair do |req_key,req_type|
      if conflate_req_types
        hash_key = req_type[:prefix]
      else
        hash_key = req_type[:project].downcase + "_" + req_type[:prefix]
      end 
      if remaped_req_types[hash_key] == nil # not existand
        remaped_req_types[hash_key] = Hash.new
        remaped_req_types[hash_key][:projects] = Array.new
      end
      remaped_req_types[hash_key][:name] = req_type[:name]  
      remaped_req_types[hash_key][:projects].push(req_type[:project])
      remaped_req_types[hash_key][:projects].uniq!
      remaped_req_types[hash_key][:projects].sort!
    end
    return remaped_req_types
  end
  
  # call after manual mapping in view
  # delete not mapped (means not used) requirements
  # add :mapping target if needed
  def update_requ_types_for_map_needing(requirement_types, tracker_mapping)
    requirement_types.each do |key,rq|
      if  tracker_mapping[rq[:prefix]] != nil
        rq[:mapping] = tracker_mapping[rq[:prefix]][:tr_name]
      else
        # in case of not conflated requirement types
        if  tracker_mapping[rq[:project].downcase + "_" + rq[:prefix]] != nil
          rq[:mapping] = tracker_mapping[rq[:project].downcase + "_" + rq[:prefix]][:tr_name]
        end
      end
      if rq[:mapping] == nil
        requirement_types.delete(key) # entry not used
      end
    end
    return requirement_types
  end
  
  #make from list rt_key=>attrids[] a list
  #attrid => rt_key
  def make_attr_list_from_requirement_types(requirement_types)
    attr_list = Hash.new
    requirement_types.each do |rt_key, rt_values|
      if rt_values[:attrids] != nil
        rt_values[:attrids].each do |attrid|
          attr_list[attrid] = rt_key
        end
      end
    end
    return attr_list
  end
  
private

  #get an data path to open an ProjectStructure file
  #collect all prefixes and guids to an array of hash
  def collect_requirement_types_fast(some_projects, loglevel)
    requirement_types = Hash.new
    some_projects.each_value do |a_project|
      xmldoc = open_xml_file(a_project[:path],"ProjectStructure.XML", loglevel)  
      if xmldoc!= nil
        xmldoc.elements.each("PROJECT/RequirementTypes/RequirementType") do |req_type|
          # collect used attributes
          used_attributes = Array.new
          if req_type.elements["Attributes"] != nil
            req_type.elements["Attributes"].each_element("Attribute") do |attri|
              used_attributes.push(attri.attributes["ID"])
            end
          end
          hash_key = req_type.attributes["ID"]
          if requirement_types[hash_key] == nil #not known
            requirement_types[hash_key] = Hash.new
            requirement_types[hash_key] [:project] = a_project[:prefix] 
            requirement_types[hash_key] [:name] = req_type.attributes["Name"]
            requirement_types[hash_key] [:prefix] = req_type.attributes["RequirementPrefix"]
            requirement_types[hash_key] [:attrids] = used_attributes
          else
            #this should never be the case --> better is to raise an error in that case 
            #make an array and add the next project
            requirement_types[hash_key] [:project] = requirement_types[hash_key] [:project].to_a 
            requirement_types[hash_key] [:project].push(a_project[:prefix])
            requirement_types[hash_key] [:project].uniq!
            requirement_types[hash_key] [:project].sort!
            #make an array and add the next attrs  
            requirement_types[hash_key] [:attrids].push(used_attributes)
          end
          requirement_types[hash_key] [:attrids].uniq!
          requirement_types[hash_key] [:attrids].sort!
        end
      end
    end
    return requirement_types
  end
  
  # search inside all files of all projects for using of requ types
  # change status for found req type to "+" (needed and available)
  def update_requ_types_for_reqpro_needing(requirement_types, some_projects, loglevel)  
    some_projects.each_value do |a_project|
      filepath = a_project[:path] # this is the main path of project
      all_files = collect_all_data_files(filepath)
      if all_files!=nil
        all_files.each do |filename|
          xmldoc = open_xml_file(filepath,filename, loglevel)
          if xmldoc!=nil
            xmldoc.elements.each("PROJECT/Pkg/Requirements/Req/RTID") do |e|
              if e.text != nil #not empty
                hash_key = e.text
                if requirement_types[hash_key] != nil
                  requirement_types[hash_key][:status] = "+"
                end #rtid in hash
              end #rtid not empty
            end #each rtid
          end #xmldoc available
        end #each files
      end #some files available
    end #each project
    requirement_types.each do |key,rq|
      if rq[:status] != "+"
        requirement_types.delete(key) # entry not used 
      else
        rq.delete(:status) #"status" not needed anymore
      end
    end
    return requirement_types
  end
  
end