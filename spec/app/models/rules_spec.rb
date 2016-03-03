require 'rails_helper'

describe Rules do
    describe '.new' do
        let(:name) { 'name' }
        let(:rule_type_id) { RuleTypes.keys.sample }
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
    end
end
