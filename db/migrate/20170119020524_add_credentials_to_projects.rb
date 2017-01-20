Sequel.migration do
  change do
    alter_table :projects do
      add_column :username, 'text'
      add_column :access_token, 'text'
    end
  end
end
