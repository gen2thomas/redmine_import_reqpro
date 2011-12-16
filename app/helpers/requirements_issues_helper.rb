module RequirementsIssuesHelper
  
  # update issues parents from requirements information
  # recursive call included
  def update_issue_parents(rp_req_unique_names)
    rp_req_unique_names.each do |rp_req_unique_name_key, rp_req_unique_name_value|
      # check for "I'm a child" --> a parent exist
      if rp_req_unique_name_key.to_s.include?(".")
        set_parent_from_child(rp_req_unique_names, rp_req_unique_name_key)
      end
    end
  end
  
  private
  
  def set_parent_from_child(rp_req_unique_names, rp_req_unique_name_key)
    # check for "I'm a child" --> a parent exist
    # .chomp(".1") remove the last characters
    name_split = rp_req_unique_name_key.split(".") 
    if name_split.length > 1
      name_split.delete_at(name_split.length-1)
      my_parent_rp_req_unique_name_key = name_split.join(".")
      child_issue = Issue.find_by_id(rp_req_unique_names[rp_req_unique_name_key])
      child_issue.parent_issue_id = rp_req_unique_names[my_parent_rp_req_unique_name_key]
      if child_issue.save
        set_parent_from_child(rp_req_unique_names, my_parent_rp_req_unique_name_key)
      else
        debugger
        puts "Parent could not be added: " + my_parent_rp_req_unique_name_key + "-->" + rp_req_unique_name_key
        debugger
      end
    end
  end
  
end