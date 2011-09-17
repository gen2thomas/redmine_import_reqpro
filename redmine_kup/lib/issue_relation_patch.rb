require_dependency 'issue_relation'

# Patches Redmine's IssueRelation dynamically.
                
module IssueRelationPatch
  
  def self.included(base) # :nodoc:
   base.extend(ClassMethods)
   
   base.send(:include, InstanceMethods)
  
    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      alias_method_chain :validate, :validate_kup #extend the original validater
    end
  end
  
  module ClassMethods
      
  end
    
  module InstanceMethods
    #if trace between trackers allowed than return true
    def kuptrace_is_valid?()
      if issue_from.iskup?
        (IssueAdd::KUP_TRACES[issue_from.tracker.to_s][:rel_to]).each do |knowntype|
          if issue_to.tracker.to_s == knowntype
            return true
          end
        end
      end
      return false
    end
    
    #extend the original validater "validate"
    def validate_with_validate_kup()
      validate_without_validate_kup #this call the original one
      #validater for all issues
      #1.) <relates> are only possible between different issue tracker types
      if relation_type==IssueRelation::TYPE_RELATES
        errors.add(:base, :only_different_tracker, :reltype=>l(label_for(issue_from))) if issue_from.tracker_id==issue_to.tracker_id
      else
        #2.) all other relations are only possible between same issue tracker types
        errors.add(:base, :only_same_tracker, :reltype=>l(label_for(issue_from))) if issue_from.tracker_id!=issue_to.tracker_id
      end
      #validater for KUP issues
      if issue_from && issue_to
        errors.add_to_base :to_kupissue_trace_error if !issue_from.iskup?() && issue_to.iskup?()
        errors.add_to_base :from_kupissue_trace_error if issue_from.iskup?() && !issue_to.iskup?()
        if issue_from.iskup?() && issue_to.iskup?() && !kuptrace_is_valid?()
          if issue_from.tracker_id!=issue_to.tracker_id
            issue_from_tracker=Tracker.find(issue_from.tracker_id).name
            errors.add_to_base :want_bug_link_to if issue_from_tracker==IssueAdd::ISSUE_ISBUG
            errors.add_to_base :want_story_link_to if issue_from_tracker==IssueAdd::ISSUE_ISSTORY
            errors.add_to_base :want_need_link_to if issue_from_tracker==IssueAdd::ISSUE_ISNEED
            errors.add_to_base :want_func_link_to if issue_from_tracker==IssueAdd::ISSUE_ISFUNC
            errors.add_to_base :want_feat_link_to if issue_from_tracker==IssueAdd::ISSUE_ISFEAT
            errors.add_to_base :want_spec_link_to if issue_from_tracker==IssueAdd::ISSUE_ISSPEC
            errors.add_to_base :want_testc_link_to if issue_from_tracker==IssueAdd::ISSUE_ISTESTC
          end
        end
      end
    end
    
  end
  
end

# Add module to IssueRelation
IssueRelation.send(:include, IssueRelationPatch)