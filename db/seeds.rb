Configurations.create(name: 'default', audit_frequency: 24 * 60, github_token: '')

rules = [
    {
        name: 'strong_vuln_patterns',
        rule_type_id: 6,
        value: '(?i)(advisory|attack|\bCVE\b|exploit|\bPOC\b|proof.of.concept|victim|\bvuln|\bRCE\b|remote.code.execution|\bDOS\b|denial.of.service)',
        description: 'Likely to indicate vulnerability'
    },
    {
        name: 'markdown_file',
        rule_type_id: 1,
        value: '(?i)\.(md|markdown)\z',
        description: 'Markdown file'
    },
    {
        name: 'non_code_file',
        rule_type_id: 1,
        value: '(?i)\.(log|cfg|ini|text|config|md|markdown|txt|yml|yaml)\z',
        description: 'Plaintext file types'
    },
    {
        name: 'medium_vuln_patterns',
        rule_type_id: 6,
        value: '(?i)(insecure|\bsecure|\bsecurity|expose|exposing|RFC\d{4,5}|infinite loop|compliant|privelage|\bescalat|(de)?serializ)',
        description: 'Keywords sometimes associated with vulns'
    },
    {
        name: 'weak_vuln_patterns',
        rule_type_id: 4,
        value: '(?i)(\bweak|\bcrypto|escalate)',
        description: 'Weakly associated with vulns'
    },
    {
        name: 'high_profile',
        rule_type_id: 7,
        value: 'strong_vuln_patterns && !non_code_file',
        description: 'Strong vuln pattern but not in a non code file'
    },
]
rules.each { |r| Rules.create(r) }

RuleSets.create(name: 'global', rules: ['high_profile'].to_json, description: 'Global rule set')

Projects.create(name: 'srcclr/commit_watcher', rule_sets: ['global'].to_json)
