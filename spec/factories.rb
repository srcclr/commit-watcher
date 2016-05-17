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
