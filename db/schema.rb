Sequel.migration do
  change do
    create_table(:configuration) do
      primary_key :id, :type=>"int(11) unsigned"
      column :crawl_frequency, "int(11) unsigned", :default=>1440, :null=>false
      column :global_patterns, "text", :null=>false
      column :github_token, "char(40)", :default=>"", :null=>false
      column :crawl_queue_interval, "smallint(5) unsigned", :default=>1, :null=>false
    end
    
    create_table(:patterns) do
      primary_key :id, :type=>"int(11) unsigned"
      column :pattern, "text", :null=>false
    end
    
    create_table(:projects) do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(100)", :default=>"", :null=>false
      column :patterns, "text"
      column :ignore_global_patterns, "tinyint(1) unsigned", :default=>false, :null=>false
      column :last_crawled, "datetime"
      column :last_commit_date, "datetime"
      column :new_commits, "mediumint(8) unsigned", :default=>0, :null=>false
      column :date_created, "timestamp", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
    end
    
    create_table(:commits) do
      primary_key :id, :type=>"int(11) unsigned"
      foreign_key :project_id, :projects, :type=>"int(11) unsigned", :null=>false, :key=>[:id]
      column :commit_date, "datetime", :null=>false
      column :matched_patterns, "mediumtext", :null=>false
      column :commit, "char(40)", :default=>"", :null=>false
      column :date_created, "timestamp", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      index [:project_id], :name=>:project_id
    end
    
    create_table(:crawl_queue) do
      primary_key :id, :type=>"int(11) unsigned", :table=>:commits, :key=>[:project_id]
      column :project_id, "int(11) unsigned"
      column :date_created, "timestamp", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      
      index [:project_id], :name=>:project_id
    end
  end
end
