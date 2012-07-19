module AttributesHelper
  def collect_attributes(some_projects, requirement_types, used_attributes_in_rts, deep_check_attrs)
    attributes = collect_attributes_fast(some_projects, requirement_types, used_attributes_in_rts)
    if deep_check_attrs
      attributes = update_attributes_for_reqpro_needing(some_projects, attributes)
    end
    return attributes
  end
  
  # remap {Project1_id=>[P1_Attrlabel1, P1_Attrlabel2], Project2_id=>[P2_Attrlabel1, P2_Attrlabel2]}
  # sort for keys and values already done (ids are sorted not labels or prefixes!)
  def remap_listattrlabels_to_projectid(attributes)
    remaped_attributes = Hash.new
    if attributes != nil
      attributes.each_pair do |attr_key, attr_val|
        if attr_val[:itemlist].length > 0
          # this attribute is possible for version
          hash_key = attr_val[:projectid]
          if remaped_attributes[hash_key] == nil
            remaped_attributes[hash_key] = Array.new
          end
          remaped_attributes[hash_key].push(attr_val[:attrlabel])
          remaped_attributes[hash_key].uniq!
          remaped_attributes[hash_key].sort!
        end
      end
    end
    return remaped_attributes.sort
  end
  
  def attribute_find_by_projectid_and_attrlabel(attributes, projectid, label)
    attributes.each do |attr_key, attr_value|
      return {attr_key => attr_value} if (attr_value[:attrlabel] == label)and(attr_value[:projectid] == projectid)
    end
    return nil
  end
    
  # remap attributes to the key :project+_+:attrlabel
  # if conflation is allowed, project is not used for key (all projects have (nearly) the same attributes)
  # take same prefixes of several projects together
  # needing: ":attrlabel", ":project"=>[], ":rtprefix"=>[], ":datatype", ":itemtext"=>[]
  def remap_noversionattributes_to_attrlabel(attributes, versions_mapping, conflate_attributes)
    remaped_attributes = nil
    if attributes != nil
      remaped_attributes = Hash.new
      attributes.each_pair do |attr_key,attr_val|
        next if (attr_key == versions_mapping[attr_val[:projectid]]) # atttribute is a version
        if conflate_attributes
          hash_key = attr_val[:attrlabel]
        else
          hash_key = attr_val[:project].downcase + "_" + attr_val[:attrlabel]
        end
        if remaped_attributes[hash_key] == nil # not existend
          remaped_attributes[hash_key] = Hash.new
          remaped_attributes[hash_key][:projects] = Array.new
          remaped_attributes[hash_key][:datatypes] = Array.new
          remaped_attributes[hash_key][:rtprefixes] = Array.new
          remaped_attributes[hash_key][:itemtext] = Array.new
        end
        #projects  
        remaped_attributes[hash_key][:projects].push(attr_val[:project])
        remaped_attributes[hash_key][:projects].uniq!
        remaped_attributes[hash_key][:projects].sort!
        #datatypes  
        remaped_attributes[hash_key][:datatypes].push(attr_val[:datatype])
        remaped_attributes[hash_key][:datatypes].uniq!
        remaped_attributes[hash_key][:datatypes].sort!
        #rtprefixes
        if attr_val[:rtprefixes] != nil #there is a new entry for the list
          remaped_attributes[hash_key][:rtprefixes].push(attr_val[:rtprefixes])
          remaped_attributes[hash_key][:rtprefixes].uniq!
          remaped_attributes[hash_key][:rtprefixes].sort!
        end
        #itemtext
        if attr_val[:itemtext] != nil #there is a new entry for the list
          remaped_attributes[hash_key][:itemtext].push(attr_val[:itemtext])
          remaped_attributes[hash_key][:itemtext].uniq!
          remaped_attributes[hash_key][:itemtext].sort!
        end
        #itemlist to itemtext for viewing
        if attr_val[:itemlist] != nil #there is a new entry for the list
          remaped_attributes[hash_key][:itemtext].concat(attr_val[:itemlist])
          #remaped_attributes[hash_key][:itemtext].flatten!
          remaped_attributes[hash_key][:itemtext].uniq!
          remaped_attributes[hash_key][:itemtext].sort!
          remaped_attributes[hash_key][:itemtext].delete("")
        end        
      end
    end
    return remaped_attributes
  end
  
  #call after manual mapping in view
  # delete not mapped (means not used) requirements
  # add :mapping target if needed
  def update_attributes_for_map_needing(attributes, versions_mapping, attributes_mapping)
    attributes.each do |attr_key, attr_val|
      if  attributes_mapping[attr_val[:attrlabel]] != nil
        attr_val[:mapping] = attributes_mapping[attr_val[:attrlabel]][:attr_name]
      else
        # in case of not conflated attributes
        if  attributes_mapping[attr_val[:project].downcase + "_" + attr_val[:attrlabel]] != nil
          attr_val[:mapping] = attributes_mapping[attr_val[:project].downcase + "_" + attr_val[:attrlabel]][:attr_name]
        end  
      end
      # delete unused entry in case of no version
      if attr_val[:mapping] == nil
        if (attr_key != versions_mapping[attr_val[:projectid]])
          attributes.delete(attr_key) # entry not used
        end
      end
    end
    return attributes
  end
  
  # force value into custom field values (test after save issue)
  def update_custom_value_in_issue(a_issue, a_custom_field, the_value, debug)
    a_issue.custom_field_values={a_custom_field.id => the_value.to_s}
    if !issue_save_with_assignee_restore(a_issue)
      puts "Error while save the issue within custom value update"
      debugger
    else
      if a_issue.custom_values.find_by_custom_field_id(a_custom_field.id) == nil
        puts "No custom value field is available for custom value, try to add an value field" if debug
        # add value as custom field
        new_custom_value = CustomValue.new
        new_custom_value.custom_field_id = a_custom_field.id
        new_custom_value.value = the_value.to_s
        new_custom_value.customized_id = a_issue.id
        new_custom_value.customized_type = "Issue"
        if !new_custom_value.save
         puts "Error while save the issue within custom value update. After push custom value"
         debugger
        else
          if a_issue.custom_values.find_by_custom_field_id(a_custom_field.id) == nil
            puts "After add an value field the value is not available!"
            debugger
          end
        end
      end
    end
    return a_issue
  end 
  
  # update issue custom field with project and tracker
  def update_issue_custom_field(issue_custom_field, new_tracker, new_project, debug)
    if !issue_custom_field
      puts "Issue custom field not exist at update with project and tracker."
      debugger
    else
      if new_tracker != nil
        if !issue_custom_field.trackers.include?(new_tracker)
          issue_custom_field.trackers.push(new_tracker)
          if !issue_custom_field.save
            debugger
            puts "Unable to update issue custom field with new tracker."
            debugger
          end
        end
      end
      if new_project != nil
        if !issue_custom_field.projects.include?(new_project)
          issue_custom_field.projects.push(new_project)
          if !issue_custom_field.save
            debugger
            puts "Unable to update issue custom field with new project."
            debugger
          end
        end
      end
    end
    return issue_custom_field
  end
  
  # create custom field for RPUID
  def create_issue_custom_field_for_rpuid(the_name, debug)
    new_issue_custom_field = IssueCustomField.find_by_name(the_name)
    if new_issue_custom_field == nil
      new_issue_custom_field = IssueCustomField.new 
      new_issue_custom_field.name = the_name
      new_issue_custom_field.field_format = "string"
      new_issue_custom_field.default_value = ""
      new_issue_custom_field.min_length = "0"
      new_issue_custom_field.max_length = "0"
      new_issue_custom_field.possible_values = ""
      new_issue_custom_field.trackers = Array.new
      new_issue_custom_field.searchable = "1"
      new_issue_custom_field.is_required = "0"
      new_issue_custom_field.regexp = ""
      new_issue_custom_field.is_for_all = "0"
      new_issue_custom_field.is_filter = "1"
      if !new_issue_custom_field.save
        debugger
        puts "Unable to create issue custom field for RPUID"
        debugger
      end
    else
      puts "Issue custom field for RPUID already exist." if debug
    end
    return new_issue_custom_field
  end
  
  # check for customfield id to update
  # if not a custom field, update the existend attribute
  # if the existend attribute deal with a user --> check the project members for this user
  def update_attribute_or_custom_field_with_value(a_issue, mapping, customfield_id, value, rpusers, debug)
    if customfield_id != ""
      if value.to_s != ""
        a_issue_custom_field = IssueCustomField.find_by_id(customfield_id)
        #update project using this custom field
        a_issue_custom_field = update_issue_custom_field(a_issue_custom_field, a_issue.tracker, a_issue.project, debug)
        # set value
        a_issue = update_custom_value_in_issue(a_issue, a_issue_custom_field, value, debug)
      else
        puts "Value for custom field was empty!" if debug
      end
    else
      case mapping
      when l_or_humanize(:assigned_to, :prefix=>"field_")
        a_issue.assigned_to = find_project_rpmember(value, rpusers, a_issue.project, debug)
      when l_or_humanize(:author, :prefix=>"field_")
        # author can't be empty
        a_issue.author = find_project_rpmember(value, rpusers, a_issue.project, debug) || User.current
      when l_or_humanize(:watchers, :prefix=>"field_")
        a_issue.watchers = find_project_rpmember(value, rpusers, a_issue.project, debug)
      when l_or_humanize(:category, :prefix=>"field_")
        a_issue.category = IssueCategory.find_by_name(value) || a_issue.category
      when l_or_humanize(:priority, :prefix=>"field_")
        a_issue.priority = IssuePriority.find_by_name(value)||IssuePriority.default
      when l_or_humanize(:status, :prefix=>"field_")
        # status can't be empty
        a_issue.status = IssueStatus.find_by_name(value)||IssueStatus.default
      when l_or_humanize(:start_date, :prefix=>"field_")
        a_issue.start_date = Time.at(value.to_i).strftime("%F")
      when l_or_humanize(:due_date, :prefix=>"field_")
        a_issue.due_date = Time.at(value.to_i).strftime("%F")
      when l_or_humanize(:done_ratio, :prefix=>"field_")
        value = 0 if value.to_i < 0
        a_issue.done_ratio = [value.to_i, 100].min
      when l_or_humanize(:estimated_hours, :prefix=>"field_")
        a_issue.estimated_hours = value
      else
        #
      end
    end
    return a_issue
  end
  
private

  def collect_attributes_fast(some_projects, requirement_types, used_attributes_in_rts)
    #get an data path to open an ProjectStructure file
    #collect all labels to a hash
    attributes = Hash.new
    some_projects.each do |a_projectid, a_project|
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
            attributes[hash_key][:attrlabel] = attri.attributes["Label"]
            attributes[hash_key][:datatype] = attri.attributes["DataTypeName"]
            attributes[hash_key][:project] = a_project[:prefix]
            attributes[hash_key][:projectid] = a_projectid
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