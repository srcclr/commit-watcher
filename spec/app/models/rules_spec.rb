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

describe Rules do
  describe '.new' do
    let(:name) { 'name' }
    let(:expression_id) { RuleTypes.select { |_, v| v[:name] == 'expression' }.keys.first }
    # Expression rules have special validation
    let(:rule_type_id) { (RuleTypes.keys - [expression_id]).sample }
    let(:value) { 'pattern' }
    let(:description) { 'test rule' }
    let(:rule) {
      Rules.new(name: name, rule_type_id: rule_type_id, value: value, description: description)
    }

    context 'with valid parameters' do
      subject { rule.valid? }

      it { should eq true }
    end

    context 'with a short name' do
      let(:name) { 'n' }

      it 'fails with the expected error' do
        expect(rule.valid?).to eq false
        expect(rule.errors).to have_key :name
      end
    end

    context 'with non-existant rule_type_id' do
      let(:rule_type_id) { 1234 }

      it 'fails with the expected error' do
        expect(rule.valid?).to eq false
        expect(rule.errors).to have_key :rule_type_id
      end
    end

    context 'with empty value' do
      let(:value) { '' }

      it 'fails with the expected error' do
        expect(rule.valid?).to eq false
        expect(rule.errors).to have_key :value
      end
    end

    context 'with value with invalid pattern' do
      let(:value) { 'unmatched ( paren' }

      it 'fails with the expected error' do
        expect(rule.valid?).to eq false
        expect(rule.errors).to have_key :value
      end
    end

    context 'with empty description' do
      let(:description) { '' }
      subject { rule.valid? }

      it { should eq true }
    end

    context 'with an expression rule' do
      let(:rule_type_id) {
        r = Rules.new(name: 'rule1', rule_type_id: 1, value: value, description: description)
        r.save
        r = Rules.new(name: 'rule2', rule_type_id: 1, value: value, description: description)
        r.save
        expression_id
      }

      context 'with a valid rule value' do
        let(:value) { 'rule1 && rule2 || rule1' }
        subject { rule.valid? }

        it { should eq true }
      end

      context 'with a rule value with invalid characters' do
        let(:value) { 'rule1 + rule2' }

        it 'fails with the expected error' do
          expect(rule.valid?).to eq false
          expect(rule.errors).to have_key :value
        end
      end

      context 'with a rule value that is not a boolean expression' do
        let(:value) { 'rule1 rule2' }

        it 'fails with the expected error' do
          expect(rule.valid?).to eq false
          expect(rule.errors).to have_key :value
        end
      end

      context 'with a rule value that references non-existant rules' do
        let(:value) { 'rule3' }

        it 'fails with the expected error' do
          expect(rule.valid?).to eq false
          expect(rule.errors).to have_key :value
        end
      end
    end
  end
end
