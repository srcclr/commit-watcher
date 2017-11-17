Sequel.migration do
  change do
    alter_table :rules do
      add_column :value2, 'longtext'
    end
  end
end
