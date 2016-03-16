Configurations.create(name: 'default', audit_frequency: 24 * 60, github_token: '')

rules = [
    {
        name: 'strong_vuln_patterns',
        rule_type_id: 4,
        value: '(?i)(advisory|attack|(un)?authoriz(e|ation)|clickjack|crack|cross.site|csrf|\bCVE\b|deadlock|denial.of.service|\bEOP\b|exploit|hack|hijack|infinite.loop|malicious|\bNVD\b|OSVDB|\bPoC\b|proof.of.concept|\bRCE\b|\bReDoS\b|remote.code.execution|security|victim|\bvuln|\bXEE\b|\bXSRF\b|\bXSS\b|\bXXE\b)',
        description: 'Strong indication of a security fix'
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
        rule_type_id: 4,
        value: '(?i)(authenticat(e|ion)|brute force|bypass|constant.time|credential|\bDoS\b|expos(e|ing)|harden|injection|lockout|overflow|password|poison|privelage|\b(in)?secur(e|ity)|(de)?serializ|spoof|timing|traversal)',
        description: 'Moderate indication of a security fix'
    },
    {
        name: 'weak_vuln_patterns',
        rule_type_id: 4,
        value: '(?i)(abuse|compliant|constant.time|credential|\bcrypto|escalate|exhaustion|forced|infinite|RFC\d{4,5})',
        description: 'Weakly associated with security fixes'
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
