class CopyDefaultWorkflow < ActiveRecord::Migration
  def self.up
    # set this new trackers with default workflow
    IssueAdd::KUP_TRACES.each do |trackername,relation|
      tracker=Tracker.find(:all, :conditions => ["name=?", trackername]) #find this new tracker in list
      #check for existend tracker
      if tracker.length != 0
        Role.find(:all).each do |role|
          #copy workflow from first tracker:
          Workflow.copy(Tracker.find(:first), role, tracker, role)
        end
      end
    end
  end

  def self.down
    #ToDo: Howto delete this workflows?
  end
end
