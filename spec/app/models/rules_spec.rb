require 'rails_helper'

describe Rules do
    describe '.new' do
        let(:name) { 'name' }
        let(:expression_id) { RuleTypes.select { |k, v| v['name'] == 'expression' }.keys.first }
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
