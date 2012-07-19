module RequirementsIssuesHelper
  
  # update issues parents from requirements information
  # recursive call included
  def update_issue_parents(rp_req_unique_names, debug)
    rp_req_unique_names.each do |rp_req_unique_name_key, rp_req_unique_name_value|
      # check for "I'm a child" --> a parent exist
      if rp_req_unique_name_key.to_s.include?(".")
        set_parent_from_child(rp_req_unique_names, rp_req_unique_name_key, debug)
      end
    end
  end
  
  private
  
  # each issue have to have an "RPUID" custom field
  # the corresponding redmine issue is given back
  def issue_find_by_rpuid(rpuid, debug)
    custom_value = CustomValue.find_by_value(rpuid)
    if custom_value == nil
      return nil
    end
    if custom_value.customized_type != "Issue"
      begin
        raise(DebugMessage, "This is not an issue-RPUID: " + rpuid + ", type is an " + custom_value.customized_type) if debug
      rescue DebugMessage => var
        puts "#{var.class}: #{var.message}"
      ensure
        return nil
      end
    end
    return Issue.find_by_id(custom_value.customized_id)
  end
  
  # set the parent_issue_id of an given issue recursively (parent, grand-parent etc.)
  # rp_req_unique_names => the complete list of all requpro requirements
  # f.e. {"NEED1.1.1" => 5 }, {"NEED1.1" => 6 }, {"NEED1" => 7 }
  # {"NEED1.1.1" => 5 } means {rp_req_unique_name_key => id}
  # where id is an issue[:id] inside redmine
  # NEED1 is the parent of NEED1.1 which is the parent of NEED1.1.1 a.s.f.
  def set_parent_from_child(rp_req_unique_names, rp_req_unique_name_key, debug)
    # check for "I'm a child" --> a parent exist
    # .chomp(".1") remove the last characters
    name_split = rp_req_unique_name_key.split(".") 
    if name_split.length > 1
      name_split.delete_at(name_split.length-1)
      my_parent_rp_req_unique_name_key = name_split.join(".")
      child_issue_id=rp_req_unique_names[rp_req_unique_name_key]
      if child_issue_id != nil
        child_issue = Issue.find_by_id(child_issue_id)
        if  child_issue != nil
          parent_issue_id = rp_req_unique_names[my_parent_rp_req_unique_name_key]
          if parent_issue_id != nil
            child_issue.parent_issue_id = parent_issue_id
            #wg. redmine Defect #11348
            if issue_save_with_assignee_restore(child_issue)
              set_parent_from_child(rp_req_unique_names, my_parent_rp_req_unique_name_key, debug)
            else
              debugger
              puts "Parent could not be added: " + my_parent_rp_req_unique_name_key + "-->" + rp_req_unique_name_key
              debugger
            end
          else
            puts "Issue of the parent requirement \""+ my_parent_rp_req_unique_name_key + "\" not found in the list." if debug
          end
        else
          puts "Issue with id \"" + child_issue_id.to_s() + "\" not found in the system." if debug
        end
      else
        puts "Issue of child requirement \""+ rp_req_unique_name_key + "\" not found in the system." if debug
      end
    end
  end
  
  #TODO: new_issue.save force "assigned_to" to a user (only while first save), how and why?
  #wg. redmine Defect #11348
  def issue_save_with_assignee_restore(a_issue)
    # wegen bug, dass assigned_to zwangsweise bei issue.save angelegt wird
    tmp_a_to = a_issue.assigned_to
    tmp_a_to_id = a_issue.assigned_to_id
    
    result = a_issue.save
    
    if a_issue.assigned_to != tmp_a_to
      debugger
      if tmp_a_to != nil
        puts "assignee canged, old: " + tmp_a_to + ", new: " + a_issue.assigned_to
      else
        puts "assignee canged, old: nil, new: " + a_issue.assigned_to.login
      end
      debugger
    end
    
    a_issue.assigned_to = tmp_a_to
    return result
  end
  
end