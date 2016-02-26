Sequel.migration do
  change do
    create_table(:configurations) do
      primary_key :id, :type=>"int(11) unsigned"
      column :audit_frequency, "int(11) unsigned", :default=>1440, :null=>false
      column :global_rules, "text", :null=>false
      column :github_token, "char(40)", :default=>"", :null=>false
    end
    
    create_table(:projects) do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(100)", :default=>"", :null=>false
      column :rules, "text", :null=>false
      column :ignore_global_rules, "tinyint(1) unsigned", :default=>false, :null=>false
      column :next_audit, "int(11) unsigned", :default=>0, :null=>false
      column :last_commit_time, "timestamp", :null=>true
      column :date_created, "timestamp", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      index [:name], :name=>:name, :unique=>true
    end
    
    create_table(:rule_types) do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(30)", :default=>"", :null=>false
    end
    
    create_table(:commits) do
      primary_key :id, :type=>"int(11) unsigned"
      foreign_key :project_id, :projects, :type=>"int(11) unsigned", :null=>false, :key=>[:id]
      column :commit_date, "datetime", :null=>false
      column :commit_hash, "char(40)", :null=>false
      column :audit_results, "longtext", :null=>false
      column :date_created, "timestamp", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      index [:project_id], :name=>:project_id
      index [:commit_hash], :name=>:uq_commit_hash, :unique=>true
    end
    
    create_table(:rules) do
      primary_key :id, :type=>"int(10) unsigned"
      foreign_key :rule_type_id, :rule_types, :type=>"int(11) unsigned", :null=>false, :key=>[:id]
      column :rule, "text", :null=>false
      
      index [:rule_type_id], :name=>:fk_rule_type_id
    end
  end
end
