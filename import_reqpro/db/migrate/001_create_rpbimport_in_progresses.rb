class CreateRpbimportInProgresses < ActiveRecord::Migration
  def self.up
    create_table :rpbimport_in_progresses do |t|
      t.column :user_id, :integer, :null => false
      t.string :quote_char, :limit => 8
      t.string :col_sep, :limit => 8
      t.string :encoding, :limit => 64
      t.column :created, :datetime
      t.column :csv_data, :binary, :limit => 4096*1024
    end
  end

  def self.down
    drop_table :rpbimport_in_progresses
  end
end
