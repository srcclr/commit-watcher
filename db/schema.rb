=begin
Copyright 2016 SourceClear Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

Sequel.migration do
  change do
    create_table(:configurations) do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(50)", :default=>"", :null=>false
      column :audit_frequency, "int(11) unsigned", :default=>1440, :null=>false
      column :github_token, "char(40)", :default=>"", :null=>false

      index [:name], :name=>:name, :unique=>true
    end

    create_table(:projects) do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(200)", :default=>"", :null=>false
      column :rule_sets, "varchar(200)", :default=>"", :null=>false
      column :next_audit, "int(11) unsigned", :default=>0, :null=>false
      column :last_commit_time, "datetime"
      column :date_created, "timestamp", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false

      index [:name], :name=>:name, :unique=>true
    end

    create_table(:rule_sets) do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(50)", :default=>"", :null=>false
      column :rules, "longtext", :null=>false
      column :description, "text"

      index [:name], :name=>:name, :unique=>true
    end

    create_table(:rules) do
      primary_key :id, :type=>"int(11) unsigned"
      column :name, "varchar(50)", :default=>"", :null=>false
      column :rule_type_id, "int(11) unsigned", :null=>false
      column :value, "longtext", :null=>false
      column :description, "text"

      index [:name], :name=>:name, :unique=>true
    end

    create_table(:commits) do
      primary_key :id, :type=>"int(11) unsigned"
      foreign_key :project_id, :projects, :type=>"int(11) unsigned", :null=>false, :key=>[:id], :on_delete=>:cascade
      column :commit_date, "datetime", :null=>false
      column :commit_hash, "char(40)", :null=>false
      column :audit_results, "longtext", :null=>false
      column :date_created, "timestamp", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false

      index [:project_id], :name=>:project_id
      index [:commit_hash], :name=>:uq_commit_hash, :unique=>true
    end
  end
end
