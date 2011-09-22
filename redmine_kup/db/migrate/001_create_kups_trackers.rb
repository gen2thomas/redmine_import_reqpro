class CreateKupsTrackers < ActiveRecord::Migration
  def self.up
    #add some "KUP" trackers (only if not exist)
    IssueAdd::KUP_TRACES.each do |trackername,relation|
      #find this new tracker in list
      tracker=Tracker.find(:all, :conditions => ["name=?", trackername])
      #check for not existend tracker and add
      if tracker.length==0
        Tracker.create :name => trackername #create new tracker with that name
        tracker=Tracker.find(:all, :conditions => ["name=?", trackername]) #find this new tracker in list
        # Associates this new tracker to all projects
        Project.find(:all).each do |project|
          project.trackers+=tracker.to_a()
        end
      end
    end
  end

  def self.down
    #delete this new trackers only if not in use!
    IssueAdd::KUP_TRACES.each do |trackername,relation|
      tracker=Tracker.find(:all, :conditions => ["name=?", trackername]) #find this new tracker in list --> array
      if tracker.length != 0
        if Issue.find(:first, :conditions => ["tracker_id=?", tracker[0].id])
          puts "\"" + tracker[0].name + "\" can't be deleted. This tracker is in use." 
        else 
          Tracker.destroy(tracker[0].id)
        end
      end
    end
  end
end
