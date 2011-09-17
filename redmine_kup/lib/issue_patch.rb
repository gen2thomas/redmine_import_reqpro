require_dependency 'issue'
                
module IssuePatch
  
  def self.included(base) # :nodoc:
      base.extend(ClassMethods)
  
      base.send(:include, InstanceMethods)
  
      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        alias_method_chain :safe_attributes=, :safe_attributes_kup #extend the original safe_attributes
      end
  
  end
  
  module ClassMethods
      
  end
    
  module InstanceMethods    
    # Returns true if +issue+ is any KUP type
    def iskup?
      return IssueAdd::KUP_TRACES.has_key?(self.tracker.to_s)
    end
    
    #extend the original "safe_attributes"
    def safe_attributes_with_safe_attributes_kup=(attrs, user=User.current)
      return unless attrs.is_a?(Hash)
      #call the old one
      attrs = safe_attributes_without_safe_attributes_KUP=(attrs) #this call the original one
      #force tracker to tracker of parent
      if attrs.has_key?('parent_issue_id')
        if attrs['parent_issue_id'].to_i!=0
          attrs['tracker_id']=Issue.find_by_id(attrs['parent_issue_id'].to_i).tracker_id
        end
      end
      self.attributes = attrs 
    end
    
  end
end

# Add module to IssueRelation
Issue.send(:include, IssuePatch)