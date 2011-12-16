class CreateReqproimportInProgresses < ActiveRecord::Migration
  def self.up
    create_table :reqproimport_in_progresses do |t|
      t.column :user_id, :integer, :null => false
      t.column :created, :datetime
    end
  end

  def self.down
    drop_table :reqproimport_in_progresses
  end
end
