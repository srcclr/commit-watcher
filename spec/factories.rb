require 'faker'

FactoryGirl.define do

  factory :commits do
    before(:create) do |commit|
        project = FactoryGirl.create(:projects)
        commit.project_id = project.id
    end
    commit_date { Faker::Date.between(2.days.ago, Date.today) }
    commit_hash { Faker::Lorem.characters(40) }
    audit_results "['audit results']"
    date_created { Faker::Date.between(2.days.ago, Date.today) }

    to_create { |e| e.save }
  end

  factory :projects do
    name { Faker::Company.name }
    rule_sets '[]'
    next_audit { Faker::Time.forward(23, :morning).to_i }
    last_commit_time { Faker::Date.between(2.days.ago, Date.today) }
    date_created { Faker::Date.between(2.days.ago, Date.today) }

    to_create { |e| e.save }
  end

end
