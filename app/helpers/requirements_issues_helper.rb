module RequirementsIssuesHelper
  
  # update issues parents from requirements information
  # recursive call included
  def update_issue_parents(rp_req_unique_names, loglevel)
    rp_req_unique_names.each do |rp_req_unique_name_key, rp_req_unique_name_value|
      # check for "I'm a child" --> a parent exist
      if rp_req_unique_name_key.to_s.include?(".")
        set_parent_from_child(rp_req_unique_names, rp_req_unique_name_key, loglevel)
      end
    end
  end

  #TODO: new_issue.save force "assigned_to" to a user (only while first save), how and why?
  #wg. redmine Defect #11348
  def issue_save_with_assignee_restore(a_issue, stop_on_found_bug)
    # wegen bug, dass assigned_to zwangsweise bei issue.save angelegt wird
    tmp_a_to = a_issue.assigned_to
    tmp_a_to_id = a_issue.assigned_to_id
    if tmp_a_to != nil
      if tmp_a_to_id != tmp_a_to.id
        debugger if stop_on_found_bug
        puts "ID already not consistend! ID: " + tmp_a_to_id + "Issue.id: " + tmp_a_to.id
      end
    end
    if !a_issue.save
      puts "Error: save of the issue failed! Try save! for more information:"
      debugger
      a_issue.save!
      debugger
      a_issue = nil
    else
      #a_issue.reload
      if a_issue.assigned_to != tmp_a_to
        debugger if stop_on_found_bug
        if tmp_a_to != nil
          puts "assignee changed, old: " + tmp_a_to + ", new: " + a_issue.assigned_to
        else
          puts "assignee changed, old: nil, new: " + a_issue.assigned_to.login
        end
      end
      a_issue.assigned_to = tmp_a_to
      a_issue.save
    end
    
    return a_issue.reload
  end
    
  private
  
  # each issue have to have an "RPUID" custom field
  # the corresponding redmine issue is given back
  def issue_find_by_rpuid(rpuid)
    the_issue_custom_field = IssueCustomField.find_by_name("RPUID")
    if the_issue_custom_field==nil
      return nil
    end
    custom_value = CustomValue.find(:first, :conditions => { :value => rpuid, :customized_type => "Issue", :custom_field_id=>the_issue_custom_field.id })
    if custom_value == nil
      return nil
    end
    return Issue.find_by_id(custom_value.customized_id)
  end
  
  # set the parent_issue_id of an given issue recursively (parent, grand-parent etc.)
  # rp_req_unique_names => the complete list of all requpro requirements
  # f.e. {"NEED1.1.1" => 5 }, {"NEED1.1" => 6 }, {"NEED1" => 7 }
  # {"NEED1.1.1" => 5 } means {rp_req_unique_name_key => id}
  # where id is an issue[:id] inside redmine
  # NEED1 is the parent of NEED1.1 which is the parent of NEED1.1.1 a.s.f.
  def set_parent_from_child(rp_req_unique_names, rp_req_unique_name_key, loglevel)
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
            child_issue=issue_save_with_assignee_restore(child_issue, false)
            if child_issue != nil
              set_parent_from_child(rp_req_unique_names, my_parent_rp_req_unique_name_key, loglevel)
            else
              debugger
              puts "Error: Parent could not be added: " + my_parent_rp_req_unique_name_key + "-->" + rp_req_unique_name_key
              debugger
            end
          else
            puts "Issue of the parent requirement \""+ my_parent_rp_req_unique_name_key + "\" not found in the list." if loglevel > 0
          end
        else
          puts "Issue with id \"" + child_issue_id.to_s() + "\" not found in the system." if loglevel > 0
        end
      else
        puts "Issue of child requirement \""+ rp_req_unique_name_key + "\" not found in the system." if loglevel > 0
      end
    end
  end
   
end