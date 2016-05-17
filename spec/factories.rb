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

require 'faker'

FactoryGirl.define do
  factory :commit, class: Commits do
    before(:create) do |commit|
      project = FactoryGirl.create(:project)
      commit.project_id = project.id
    end
    commit_date { Faker::Date.between(2.days.ago, Date.today) }
    commit_hash { Faker::Lorem.characters(40) }
    audit_results { ['audit results'].to_json }
    date_created { Faker::Date.between(2.days.ago, Date.today) }

    to_create { |e| e.save }
  end

  factory :project, class: Projects do
    name { "#{Faker::Name.first_name}/#{Faker::Name.last_name}" }
    rule_sets [].to_json
    next_audit { Faker::Time.forward(23, :morning).to_i }
    last_commit_time { Faker::Date.between(2.days.ago, Date.today) }
    date_created { Faker::Date.between(2.days.ago, Date.today) }

    to_create { |e| e.save }
  end
end
