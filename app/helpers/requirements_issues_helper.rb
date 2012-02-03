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
  def update_traces(rp_relation_list, import_intern_relation_allowed, import_extern_relation_allowed, import_results, debug)
    #{SPRJ1_ID => {TPRJ1_ID => {SREQ1_ID => [TREQ1_ID, TREQ2_ID]},
    #              TPRJ2_ID => {SREQ2_ID => [TREQ1_ID, TREQ4_ID]}}}
    rp_relation_list.each do |source_pid, target_pid_list|
      target_pid_list.each do |target_pid, source_iid_list|
        intern_relation = (source_pid == target_pid and import_intern_relation_allowed)
        extern_relation = (source_pid != target_pid and import_extern_relation_allowed)
        source_iid_list.each do |source_iid, target_iid_array|
          source_issue = issue_find_by_rpuid(source_iid, debug)
          if source_issue == nil
            import_results[:failed][:issue_internal_relations] += 1 if intern_relation
            import_results[:failed][:issue_external_relations] += 1 if extern_relation
            puts "No source issue found from RPUID " + source_iid + ", take next relation." if debug
            next
          end
          target_iid_array.each do |target_iid|
            target_issue = issue_find_by_rpuid(target_iid, debug)
            if target_issue == nil
              import_results[:failed][:issue_internal_relations] += 1 if intern_relation
              import_results[:failed][:issue_external_relations] += 1 if extern_relation
              puts "Related target issue (according to this internal trace) was not found, take next relation." if debug
              next
            end
            # check if relation exist
            if !IssueRelation.find(:all, :conditions => ["issue_from_id=? AND issue_to_id=? AND relation_type=?", source_issue, target_issue, "relates"])[0]
              issue_relation_new = IssueRelation.new
              issue_relation_new.issue_from = source_issue
              issue_relation_new.issue_to = target_issue
              issue_relation_new.relation_type = "relates"
              if !(issue_relation_new.save)
                # failed relation is normal for installed KUP-Plugin
                import_results[:failed][:issue_internal_relations] += 1 if intern_relation
                import_results[:failed][:issue_external_relations] += 1 if extern_relation
                puts "Failed to save new internal issue relation." if (debug and intern_relation)
                puts "Failed to save new external issue relation." if (debug and extern_relation)
              else
                import_results[:imported][:issue_internal_relations] += 1 if intern_relation
                import_results[:imported][:issue_external_relations] += 1 if extern_relation
              end
            end
          end
        end
      end
    end
    return import_results
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
      puts "This is not an issue-RPUID: " + rpuid + "type is an " + custom_value.customized_type if debug
      return nil
    end
    return Issue.find_by_id(custom_value.customized_id)
  end
  
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