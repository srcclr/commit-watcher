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

describe RuleSets do
  describe '.new' do
    let(:name) { 'name' }
    let(:rules) { ['rule1'].to_json }
    let(:description) { 'test rule set' }
    let(:rule_set) {
      r = Rules.new(name: 'rule1', rule_type_id: 1, value: 'val', description: 'desc')
      r.save
      RuleSets.new(name: name, rules: rules, description: description)
    }

    context 'with valid parameters' do
      subject { rule_set.valid? }

      it { should eq true }
    end

    context 'with a short name' do
      let(:name) { 'n' }

      it 'fails with the expected error' do
        expect(rule_set.valid?).to eq false
        expect(rule_set.errors).to have_key :name
      end
    end

    context 'with an empty rules value' do
      let(:rules) { [].to_json }

      it 'fails with the expected error' do
        expect(rule_set.valid?).to eq false
        expect(rule_set.errors).to have_key :rules
      end
    end

    context 'with a rules value that references a non-existant rule' do
      let(:rules) { ['no-existy'].to_json }

      it 'fails with the expected error' do
        expect(rule_set.valid?).to eq false
        expect(rule_set.errors).to have_key :rules
      end
    end

    context 'with a rules value thats invalid JSON' do
      let(:rules) { 'bro, do you even json?' }

      it 'fails with the expected error' do
        expect(rule_set.valid?).to eq false
        expect(rule_set.errors).to have_key :rules
      end
    end

    context 'with empty description' do
      let(:description) { '' }
      subject { rule_set.valid? }

      it { should eq true }
    end
  end
end
