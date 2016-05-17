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

require 'rails_helper'

describe Projects do
  describe '.new' do
    let(:name) { 'srcclr/commit-watcher' }
    let(:rule_sets) { %w(rule_set1).to_json }
    let(:project) {
      Rules.create(name: 'rule1', rule_type_id: 1, value: 'val', description: 'desc')
      RuleSets.create(name: 'rule_set1', rules: %w(rule1).to_json, description: 'desc')
      Projects.new(name: name, rule_sets: rule_sets)
    }

    context 'with valid parameters' do
      subject { project.valid? }

      it { should eq true }
    end

    context 'with a short name' do
      let(:name) { 'n' }

      it 'fails with the expected error' do
        expect(project.valid?).to eq false
        expect(project.errors).to have_key :name
      end
    end

    context 'with an empty rule sets' do
      let(:rule_sets) { [].to_json }
      subject { project.valid? }

      it { should eq true }
    end

    context 'with a rule sets value that references a non-existant rule set' do
      let(:rule_sets) { ['no-existy'].to_json }

      it 'fails with the expected error' do
        expect(project.valid?).to eq false
        expect(project.errors).to have_key :rule_sets
      end
    end

    context 'with a rule sets value thats invalid JSON' do
      let(:rule_sets) { 'bro, do you even json?' }

      it 'fails with the expected error' do
        expect(project.valid?).to eq false
        expect(project.errors).to have_key :rule_sets
      end
    end
  end
end
