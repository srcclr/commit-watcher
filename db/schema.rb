Sequel.migration do
  change do
    create_table(:configurations, charset: 'utf8', collate: 'utf8_general_ci') do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(50)", :default=>"", :null=>false
      column :audit_frequency, "int(11) unsigned", :default=>1440, :null=>false
      column :github_token, "char(40)", :default=>"", :null=>false

      index [:name], :name=>:name, :unique=>true
    end

    create_table(:notifications, charset: 'utf8', collate: 'utf8_general_ci') do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(50)", :default=>"", :null=>false
      column :notification_type_id, "tinyint(3)", :default=>0, :null=>false
      column :target, "varchar(200)", :default=>"", :null=>false
    end

    create_table(:projects, charset: 'utf8', collate: 'utf8_general_ci') do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(200)", :default=>"", :null=>false
      column :rule_sets, "varchar(200)", :default=>"", :null=>false
      column :next_audit, "int(11) unsigned", :default=>0, :null=>false
      column :last_commit_time, "datetime"
      column :date_created, "timestamp", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false

      index [:name], :name=>:name, :unique=>true
    end

    create_table(:rule_sets, charset: 'utf8', collate: 'utf8_general_ci') do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(50)", :default=>"", :null=>false
      column :rules, "longtext", :null=>false
      column :description, "text"

      index [:name], :name=>:name, :unique=>true
    end

    create_table(:commits, charset: 'utf8', collate: 'utf8_general_ci') do
      primary_key :id, :type=>"int(11) unsigned"
      foreign_key :project_id, :projects, :type=>"int(11) unsigned", :null=>false, :key=>[:id], :on_delete=>:cascade
      column :status_type_id, "tinyint(3) unsigned", :default=>0, :null=>false
      column :commit_date, "datetime", :null=>false
      column :commit_hash, "char(40)", :null=>false
      column :audit_results, "longtext", :null=>false
      column :date_created, "timestamp", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false

      index [:project_id], :name=>:project_id
      index [:commit_hash], :name=>:uq_commit_hash, :unique=>true
    end

    create_table(:rules, charset: 'utf8', collate: 'utf8_general_ci') do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(50)", :default=>"", :null=>false
      column :rule_type_id, "int(11) unsigned", :null=>false
      column :value, "longtext", :null=>false
      column :description, "text"
      foreign_key :notification_id, :notifications, :type=>"int(11) unsigned", :key=>[:id]

      index [:name], :name=>:name, :unique=>true
      index [:notification_id], :name=>:notification_id
    end
  end
end
