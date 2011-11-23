module AttributesHelper
  def collect_attributes(some_projects, requirement_types, used_attributes_in_rts, deep_check_attrs)
    attributes = collect_attributes_fast(some_projects, requirement_types, used_attributes_in_rts)
    if deep_check_attrs
      attributes = update_attributes_for_reqpro_needing(some_projects, attributes)
    end
    return attributes
  end
  
  def remap_attributes_to_label(attributes, conflate_attributes)
    # remap attributes to the key :project+:attrlabel
    # if conflation is allowed, project is not used for key (all projects have (nearly) the same attributes)
    # take same prefixes of several projects together
    # needing: ":attrlabel", ":project"=>[], ":rtprefix"=>[], ":datatype", ":itemtext"=>[]
    remaped_attributes = Hash.new
    attributes.each_pair do |attr_key,attr_type|
      if conflate_attributes
        hash_key = attr_type[:attrlabel]
      else
        hash_key = attr_type[:project] + "." + attr_type[:attrlabel]
      end
      if remaped_attributes[hash_key] == nil # not existend
        remaped_attributes[hash_key] = Hash.new
        remaped_attributes[hash_key][:projects] = Array.new
        remaped_attributes[hash_key][:datatypes] = Array.new
        remaped_attributes[hash_key][:rtprefixes] = Array.new
        remaped_attributes[hash_key][:itemtext] = Array.new
      end
      #attrlabel (use always the last one)
      remaped_attributes[hash_key][:attrlabel] = attr_type[:attrlabel]
      #projects  
      remaped_attributes[hash_key][:projects].push(attr_type[:project])
      remaped_attributes[hash_key][:projects].uniq!
      remaped_attributes[hash_key][:projects].sort!
      #datatypes  
      remaped_attributes[hash_key][:datatypes].push(attr_type[:datatype])
      remaped_attributes[hash_key][:datatypes].uniq!
      remaped_attributes[hash_key][:datatypes].sort!
      #rtprefixes
      if attr_type[:rtprefixes] != nil #there is a new entry for the list
        remaped_attributes[hash_key][:rtprefixes].push(attr_type[:rtprefixes])
        remaped_attributes[hash_key][:rtprefixes].uniq!
        remaped_attributes[hash_key][:rtprefixes].sort!
      end
      #itemtext
      if attr_type[:itemtext] != nil #there is a new entry for the list
        remaped_attributes[hash_key][:itemtext].push(attr_type[:itemtext])
        remaped_attributes[hash_key][:itemtext].uniq!
        remaped_attributes[hash_key][:itemtext].sort!
      end
      #itemlist to itemtext for viewing
      if attr_type[:itemlist] != nil #there is a new entry for the list
        remaped_attributes[hash_key][:itemtext].concat(attr_type[:itemlist])
        #remaped_attributes[hash_key][:itemtext].flatten!
        remaped_attributes[hash_key][:itemtext].uniq!
        remaped_attributes[hash_key][:itemtext].sort!
        remaped_attributes[hash_key][:itemtext].delete("")
      end        
    end
    return remaped_attributes
  end
  
  def update_attributes_for_map_needing(attributes,attributes_mapping)
    #call after manual mapping in view
    # delete not mapped (means not used) requirements
    # add :mapping target if needed      
    attributes.each do |key,attri|      
      if  attributes_mapping[attri[:attrlabel]] == nil
        attributes.delete(key) # entry not used
      else
        attri[:mapping] = attributes_mapping[attri[:attrlabel]][:attr_name]
      end
    end
    return attributes
  end
  
  
private

  def collect_attributes_fast(some_projects, requirement_types, used_attributes_in_rts)
    #get an data path to open an ProjectStructure file
    #collect all labels to a hash
    attributes = Hash.new
    some_projects.each_value do |a_project|
      xmldoc = open_xml_file(a_project[:path],"ProjectStructure.XML")
      xmldoc.elements.each("PROJECT/Attributes/Attribute") do |attri|
        # check for this attribute is used inside requirement types 
        if used_attributes_in_rts.include?(attri.attributes["ID"])
          rtid = used_attributes_in_rts[attri.attributes["ID"]]
          # generate a key
          hash_key = attri.attributes["ID"]
          if attributes[hash_key] == nil #already not known
            #make a new entry
            attributes[hash_key] = Hash.new
            attributes[hash_key][:default] = attri.attributes["DefaultValue"]
            attributes[hash_key][:itemtext] = attri.attributes["DefaultValue"]
            attributes[hash_key][:itemlist] = Array.new
            attributes[hash_key][:itemlist_used] = Array.new
            #TODO: evtl. entfernen attributes[hash_key][:itemlist] = Hash.new
            attributes[hash_key][:attrlabel] = attri.attributes["Label"]
            attributes[hash_key][:datatype] = attri.attributes["DataTypeName"]
            attributes[hash_key][:project] = a_project[:prefix]
            attributes[hash_key][:rtid] = rtid
            attributes[hash_key][:rtprefixes] = requirement_types[rtid][:prefix]
            #check for list items  
            if attri.elements["ListItems"] != nil
              # there are some list items
              attri.elements["ListItems"].each do |item|  
                if item.attributes["ItemText"] != nil
                  #check for a new entry for default
                  if item.attributes["Default"]=="True"
                    attributes[hash_key][:default] = item.attributes["ItemText"]
                  end
                  attributes[hash_key][:itemlist].push(item.attributes["ItemText"])
                  #TODO: evtl. entfernen attributes[hash_key][:itemlist][item.attributes["ID"]] = item.attributes["ItemText"]
                end  
              end
            end
          else
            #this should normally never be the case, better would be a raised error
            #add this project to known projects
            puts "Already known attribute-item found: " + hash_key + "->" + attri.attributes["Label"]
            debugger
            attributes[hash_key][:project] = attributes[hash_key][:project].to_a
            attributes[hash_key][:project].push(a_project[:prefix])
            attributes[hash_key][:project].uniq! #delete double entries
          end
        else
          #puts "This attribute is not used yet: " + attri.attributes["ID"] + "->" + attri.attributes["Label"]
        end
      end
    end
    return attributes
  end
  
  def update_attributes_for_reqpro_needing(some_projects, attributes)
    #search inside all files of all projects for using of attributes
    # change status for found attributes to "+" (needed and available)
    some_projects.each_value do |a_project|
      filepath = a_project[:path] # this is the main path of project
      all_files = collect_all_data_files(filepath)
      all_files.each do |filename|
        xmldoc = open_xml_file(filepath,filename)
        xmldoc.elements.each("PROJECT/Pkg/Requirements/Req") do |req|
          if req.elements["FVs"] != nil
            req.elements["FVs"].each do |fv|
              if fv != nil #not empty
                hash_key = fv.elements["FGUID"].text
                if attributes[hash_key] != nil
                  attributes[hash_key][:status] = "+"
                  #TODO: evtl. entfernen attributes[hash_key][:rtid] = req.elements["RTID"].text
                end
              end
            end
          end
          if req.elements["LVs"] != nil
            req.elements["LVs"].each do |lv|
              if lv != nil #not empty
                #hash_key = lv.elements["LGUID"].text --> this is only the list item ID!
                hash_key = lv.elements["UDF"].text # this is the attribute ID
                if attributes[hash_key] != nil
                  attributes[hash_key][:status] = "+"
                  #TODO: evtl. entfernen attributes[hash_key][:rtid] = req.elements["RTID"].text
                  attributes[hash_key][:itemlist_used].push(lv.elements["LITxt"].text)
                end
              end
            end
          end
        end
      end
    end
    #check for used attributes
    attributes.each do |key, attri|
      if attri[:status] != "+"
        attributes.delete(key) # entry not used
      else
        attri.delete(:status) #"status" not needed anymore
        # update itemlist
        attri[:itemlist] = attri[:itemlist_used]
        attri[:itemlist].uniq!
        attri[:itemlist].sort!
        attri.delete(:itemlist_used) #"itemlist_used" not needed anymore
      end
    end
    return attributes
  end
  
end