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
  
  # add internal traces as issue relations
  def update_internal_traces(rpid_issue_rmid, rp_internal_relation_list, import_results, debug)
    rp_internal_relation_list.each do |rpid, intern_rel_list|
      issue_to_change = Issue.find_by_id(rpid_issue_rmid[rpid].to_i)
      intern_rel_list.each do |int_rel|
        if rpid_issue_rmid[int_rel] == nil
          puts "related issue not imported, take next" if debug
          next
        end
        issue_relation_new = IssueRelation.new
        issue_relation_new.issue_from = issue_to_change
        issue_relation_new.issue_to = Issue.find_by_id(rpid_issue_rmid[int_rel].to_i)
        issue_relation_new.relation_type = "relates"
        if !(issue_relation_new.save)
          # failed relation is normal for installed KUP-Plugin
          import_results[:failed][:issue_internal_relations] += 1
          puts "Failed to save new internal issue relation." if debug
        else
          import_results[:imported][:issue_internal_relations] += 1
        end
      end
    end
    return import_results
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