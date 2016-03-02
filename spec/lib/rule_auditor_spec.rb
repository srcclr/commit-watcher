require 'rails_helper'
require 'hash_dot'

describe RuleAuditor do
    Hash.use_dot_syntax = true

    describe '.audit' do
        subject { RuleAuditor.audit(commit, rule_type_id, rule_value, diff) }

        let(:patch_herpy_java) {
            {
                file: 'path/herpy.java',
                body: 'System.out.println("hello,world!");',
                changed_lines: [],
            }
        }
        let(:patch_derpy_java) {
            {
                file: 'wow/derpy.java',
                body: "The sky above the port was the color of television,\ntuned to a dead channel." ,
                changed_lines: [{ content: 'tuned to a dead channel.' }],
            }
        }
        let(:patch_herpy_txt) {
            {
                file: 'path/herpy.txt',
                body: 'dead channel',
                changed_lines: [],
            }
        }

        context 'with filename rule' do
            let(:commit) { nil }
            let(:rule_type_id) { RuleTypes.select { |k, v| v['name'] == 'filename' }.keys.first }
            let(:rule_value) { 'herpy.java' }

            context 'with matching diff' do
                let(:diff) { [patch_herpy_java, patch_derpy_java] }

                it { should eq %w(path/herpy.java) }
            end

            context 'with unmatching diff' do
                let(:diff) { [patch_herpy_txt, patch_derpy_java] }

                it { should be nil }
            end
        end

        context 'with changed_code_pattern rule' do
            let(:commit) { nil }
            let(:rule_type_id) { RuleTypes.select { |k, v| v['name'] == 'changed_code_pattern' }.keys.first }
            let(:rule_value) { 'dead channel' }

            context 'with matching diff' do
                let(:diff) { [patch_herpy_java, patch_derpy_java] }

                it {
                    should eq [
                        {
                            file: patch_derpy_java.file,
                            body: patch_derpy_java.body,
                            changed_lines: [patch_derpy_java.changed_lines.first.content],
                        }
                    ]
                }
            end

            context 'with unmatching diff' do
                let(:diff) { [patch_herpy_txt, patch_herpy_java] }

                it { should be nil }
            end
        end

        context 'with code_pattern rule' do
            let(:commit) { nil }
            let(:rule_type_id) { RuleTypes.select { |k, v| v['name'] == 'code_pattern' }.keys.first }
            let(:rule_value) { 'dead channel' }

            context 'with matching diff' do
                let(:diff) { [patch_herpy_java, patch_derpy_java] }

                it { should eq [{ file: patch_derpy_java.file, body: patch_derpy_java.body }] }
            end

            context 'with unmatching diff' do
                let(:diff) { [patch_herpy_java] }

                it { should be nil }
            end
        end

        context 'with expression rule' do
            let(:rule_type_id) { RuleTypes.select { |k, v| v['name'] == 'expression' }.keys.first }
            let(:rule1) {
                type_id = RuleTypes.select { |k, v| v['name'] == 'filename' }.keys.first
                { name: 'rule1', rule_type_id: type_id, rule_value: '\.txt\z' }
            }
            let(:rule2) {
                type_id = RuleTypes.select { |k, v| v['name'] == 'filename' }.keys.first
                { name: 'rule2', rule_type_id: type_id, rule_value: '\.java\z' }
            }
            let(:rules) { double('Rules') }
            let(:diff) {
                [{ file: 'path/herpy.java' }, { file: 'wow/derpy.txt' }]
            }
            let(:commit) { nil }

            context 'with rule value that should match both filenames in diff' do
                let(:rule_value) { 'rule1 || rule2' }

                it {
                    allow(rules).to receive(:where).and_return([rule1, rule2])
                    stub_const('Rules', rules)
                    is_expected.to include rule_name: 'rule1', result: %w(wow/derpy.txt)
                    is_expected.to include rule_name: 'rule2', result: %w(path/herpy.java)
                }
            end

            context 'with rule value that should match only one filename in diff' do
                let(:rule_value) { '!rule2' }

                it {
                    allow(rules).to receive(:where).and_return([rule2])
                    stub_const('Rules', rules)
                    is_expected.to include rule_name: 'rule2', result: nil
                }
            end
        end
    end
end
