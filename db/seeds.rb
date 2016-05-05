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

Configurations.create(name: 'default', audit_frequency: 24 * 60 * 60, github_token: '')

rules = [
  {
    name: 'strong_vuln_patterns',
    rule_type_id: 4,
    value: '(?i)(advisory|attack|(un)?authoriz(e|ation)|clickjack|cross.site|csrf|\bCVE\b|deadlock|denial.of.service|\bEOP\b|exploit|hijack|infinite.loop|malicious|\bNVD\b|OSVDB|\bRCE\b|\bReDoS\b|remote.code.execution|security|victim|\bvuln|\bXEE\b|\bXSRF\b|\bXSS\b|\bXXE\b)',
    description: 'Strong indication of a silent vulnerability fix'
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
    description: 'Popular non source code file types'
  },
  {
    name: 'medium_vuln_patterns',
    rule_type_id: 4,
    value: '(?i)(authenticat(e|ion)|brute force|bypass|constant.time|crack|credential|\bDoS\b|expos(e|ing)|hack|harden|injection|lockout|overflow|password|\bPoC\b|proof.of.concept|poison|privelage|\b(in)?secur(e|ity)|(de)?serializ|spoof|timing|traversal)',
    description: 'Medium indication of a silent vulnerability fix'
  },
  {
    name: 'weak_vuln_patterns',
    rule_type_id: 4,
    value: '(?i)(abuse|compliant|constant.time|credential|\bcrypto|escalate|exhaustion|forced|infinite|RFC\d{4,5})',
    description: 'Weak indication of a silent vulnerability fix'
  },

  {
    name: 'npm_authentication_file',
    rule_type_id: 1,
    value: '(?i)\.npmrc_auth',
    description: 'NPM Registry authentication data'
  },
  {
    name: 'docker_cfg',
    rule_type_id: 1,
    value: '(?i)\.dockercfg',
    description: 'Docker configuration file'
  },
  {
    name: 'contains_auth',
    rule_type_id: 3,
    value: '(?i)\bauth\b',
    description: 'Contains the word "auth"'
  },
  {
    name: 'find_docker_credentials',
    rule_type_id: 7,
    value: 'docker_cfg && contains_auth',
    description: 'Docker registry authentication data'
  },
  {
    name: 'crypto_key_file',
    rule_type_id: 1,
    value: '(?i)\.(pem|pkcs12|pfx|p12|asc\z)',
    description: 'Crypto key file'
  },
  {
    name: 'puttygen_key_file',
    rule_type_id: 1,
    value: '(?i)\.ppk',
    description: 'PuTTYgen key file'
  },
  {
    name: 'ssh_key_file',
    rule_type_id: 1,
    value: '(?i)(id_[rd]sa|\A[^_]+(rsa|dsa|ed25519|ecdsa)\z)',
    description: 'SSH key file'
  },
  {
    name: 'contains_PRIVATE',
    rule_type_id: 3,
    value: '\bPRIVATE\b',
    description: 'Contains the word "PRIVATE"'
  },
  {
    name: 'private_crypto_key',
    rule_type_id: 7,
    value: 'ssh_key_file || ((crypto_key_file || puttygen_key_file) && contains_PRIVATE)',
    description: 'Private crypto key'
  },
  {
    name: 'sql_file',
    rule_type_id: 1,
    value: '(?i)\.sql',
    description: 'SQL file'
  },
  {
    name: 'contains_dump',
    rule_type_id: 3,
    value: '\bdump\b',
    description: 'Contains the word "dump"'
  },
  {
    name: 'sql_dump_file',
    rule_type_id: 7,
    value: 'sql_file && contains_dump',
    description: 'SQL dump file'
  },
  {
    name: 'file_contains_credentials',
    rule_type_id: 1,
    value: '(?i)credentials',
    description: 'File name contains "credentials"'
  },
  {
    name: 'contains_aws_access_key_id',
    rule_type_id: 3,
    value: '\baws_access_key_id\b',
    description: 'Contains the word "aws_access_key_id"'
  },
  {
    name: 'aws_access_key_file',
    rule_type_id: 7,
    value: 'file_contains_credentials && contains_aws_access_key_id',
    description: 'AWS Access key credentials'
  },
  {
    name: 's3_config',
    rule_type_id: 1,
    value: '(?i)\.s3cfg',
    description: 'Amazon S3 configuration file'
  },
  {
    name: 'wordpress_config',
    rule_type_id: 1,
    value: '(?i)wp-config\.php',
    description: 'WordPress Configuration file'
  },
  {
    name: 'htpasswd_file',
    rule_type_id: 1,
    value: '(?i)\.htpasswd',
    description: 'Apache HTPasswd file'
  },
  {
    name: 'env_file',
    rule_type_id: 1,
    value: '(?i)\.env',
    description: 'Environment variables file'
  },
  {
    name: 'git_credentials_file',
    rule_type_id: 1,
    value: '(?i)\.git-credentials',
    description: 'Git credentials storage file'
  },
  {
    name: 'shell_script_file',
    rule_type_id: 1,
    value: '(?i)\.sh',
    description: 'Shell script file'
  },
  {
    name: 'contains_PT_TOKEN',
    rule_type_id: 3,
    value: 'PT_TOKEN',
    description: 'Contains the word "PT_TOKEN" for PivotalTracker'
  },
  {
    name: 'pivotaltracker_token',
    rule_type_id: 7,
    value: 'shell_script_file && contains_PT_TOKEN',
    description: 'SQL dump file'
  },
  {
    name: 'shell_rc_file',
    rule_type_id: 1,
    value: '(?i)\.(bashrc|zshrc|cshrc|bash_profile|zsh_profile|csh_profile|bash_history|zsh_history|csh_history|history|sh_history|bash_aliases|zsh_aliases)',
    description: 'Shell run commands file'
  },
  {
    name: 'contains_password',
    rule_type_id: 3,
    value: 'password',
    description: 'Contains the word "password"'
  },
  {
    name: 'find_rc_passwords',
    rule_type_id: 7,
    value: 'shell_rc_file && contains_password',
    description: 'Find "password" in run commands files'
  },
  {
    name: 'contains_mailchimp',
    rule_type_id: 3,
    value: 'mailchimp',
    description: 'Contains the word "mailchimp"'
  },
  {
    name: 'find_rc_mailchimp',
    rule_type_id: 7,
    value: 'shell_rc_file && contains_mailchimp',
    description: 'Find "mailchimp" in run commands files'
  },
  {
    name: 'contains_aws',
    rule_type_id: 3,
    value: '\baws\b',
    description: 'Contains the word "aws"'
  },
  {
    name: 'find_rc_aws',
    rule_type_id: 7,
    value: 'shell_rc_file && contains_aws',
    description: 'Find "aws" in run commands files'
  },
  {
    name: 'contains_rds_info',
    rule_type_id: 3,
    value: 'rds\.amazonaws\.com',
    description: 'Contains the word "rds.amazonaws.com"'
  },
  {
    name: 'find_amazon_rds_credentials',
    rule_type_id: 7,
    value: 'contains_rds_info && contains_aws',
    description: 'Find files with possible Amazon RDS credentials'
  },
  {
    name: 'json_file',
    rule_type_id: 1,
    value: '(?i)\.json',
    description: 'JSON file'
  },
  {
    name: 'contains_forecast_api',
    rule_type_id: 3,
    value: 'api\.forecast\.io',
    description: 'Contains the word "api.forecast.io"'
  },
  {
    name: 'find_forecast_api_key',
    rule_type_id: 7,
    value: 'json_file && contains_forecast_api',
    description: 'Find files with possible Forecast.io API key'
  },
  {
    name: 'yaml_file',
    rule_type_id: 1,
    value: '(?i)\.yaml',
    description: 'YAML file'
  },
  {
    name: 'js_file',
    rule_type_id: 1,
    value: '(?i)\.js',
    description: 'JavaScript file'
  },
  {
    name: 'contains_jsforce',
    rule_type_id: 3,
    value: 'jsforce',
    description: 'Contains the word "jsforce" for SalesForce'
  },
  {
    name: 'contains_conn_login',
    rule_type_id: 3,
    value: 'conn\login',
    description: 'Contains the word "conn.login"'
  },
  {
    name: 'find_salesforce_nodejs_credentials',
    rule_type_id: 7,
    value: 'js_file && contains_jsforce && contains_conn_login',
    description: 'Find files with possible SalesForce credentials in node.js projects'
  },
  {
    name: 'contains_sf_username',
    rule_type_id: 3,
    value: 'SF_USERNAME "salesforce"',
    description: 'Contains the SF_USERNAME for SalesForce'
  },
  {
    name: 'contains_API_KEY',
    rule_type_id: 3,
    value: 'API_KEY',
    description: 'Contains the word "API_KEY"'
  },
  {
    name: 'tugboat_config',
    rule_type_id: 1,
    value: '(?i)\.tugboat',
    description: 'Tugboat config file'
  },
  {
    name: 'netrc_file',
    rule_type_id: 1,
    value: '(?i)[._]netrc',
    description: 'Net run commands file'
  },
  {
    name: 'find_netrc_with_password',
    rule_type_id: 7,
    value: 'netrc_file && contains_password',
    description: 'Find netrc files which contain "password"'
  },
  {
    name: 'robomongo_credentials_file',
    rule_type_id: 1,
    value: '(?i)robomongo\.json',
    description: 'RoboMongo credentials file for mongodb'
  },
  {
    name: 'filezilla_config_file',
    rule_type_id: 1,
    value: '(?i)(filezilla|recentservers)\.xml',
    description: 'FileZilla config file'
  },
  {
    name: 'contains_Pass',
    rule_type_id: 3,
    value: 'Pass\b',
    description: 'Contains the word "Pass"'
  },
  {
    name: 'find_filezilla_credentials',
    rule_type_id: 7,
    value: 'filezilla_config_file && contains_Pass',
    description: 'Find FileZilla files with possible credentials'
  },
  {
    name: 'config_json_file',
    rule_type_id: 1,
    value: '(?i)config\.json',
    description: 'config.json file'
  },
  {
    name: 'contains_auths',
    rule_type_id: 3,
    value: 'auths',
    description: 'Contains the word "api.forecast.io"'
  },
  {
    name: 'find_docker_auth_data',
    rule_type_id: 7,
    value: 'config_json_file && contains_auths',
    description: 'Docker registry authentication data'
  },
  {
    name: 'idea_key_file',
    rule_type_id: 1,
    value: '(?i)idea\d{2}\.key',
    description: 'Intellij Idea key, e.g. idea14.key'
  },
  {
    name: 'config_file',
    rule_type_id: 1,
    value: '(?i)\Aconfig\z',
    description: 'Possible IRC configuration'
  },
  {
    name: 'contains_irc_pass',
    rule_type_id: 3,
    value: 'irc_pass',
    description: 'Contains the word "irc_pass"'
  },
  {
    name: 'find_irc_pass',
    rule_type_id: 7,
    value: 'config_file && contains_irc_pass',
    description: 'Find IRC credentials'
  },
  {
    name: 'db_connections_file',
    rule_type_id: 1,
    value: '(?i)connections\.xml',
    description: 'Possible configuration with DB connection credentials'
  },
  {
    name: 'openshift_config_file',
    rule_type_id: 1,
    value: '(?i)openshift[^e]+express\.conf',
    description: 'OpenShift configuration file'
  },
  {
    name: 'postgres_pass_file',
    rule_type_id: 1,
    value: '(?i)\.pgpass',
    description: 'PostgreSQL password file'
  },
  {
    name: 'proftpd_passwd_file',
    rule_type_id: 1,
    value: '(?i)proftpdpasswd',
    description: 'ProFPTD password file'
  },
  {
    name: 'ventrilo_config_file',
    rule_type_id: 1,
    value: '(?i)ventrilo_srv\.ini',
    description: 'Ventrilo server configuration file'
  },
  {
    name: 'winframe_client_config',
    rule_type_id: 3,
    value: '\[WFClient\] Password= extension:ica',
    description: 'Contains WinFrame-Client configuration for connecting to Citrix App Servers'
  },
  {
    name: 'goldsrc_config_file',
    rule_type_id: 1,
    value: '(?i)server\.cfg',
    description: 'GoldSrc engine server configuration file, e.g. CounterStrike, Half-Life'
  },
  {
    name: 'contains_rcon',
    rule_type_id: 3,
    value: '\brcon\b',
    description: 'Contains the word "rcon"'
  },
  {
    name: 'find_goldsrc_rcon_passwords',
    rule_type_id: 7,
    value: 'goldsrc_config_file && contains_rcon && contains_password',
    description: 'Find files with possible Forecast.io API key'
  },
  {
    name: 'contains_JEKYLL_GITHUB_TOKEN',
    rule_type_id: 3,
    value: 'JEKYLL_GITHUB_TOKEN',
    description: 'Contains the word "JEKYLL_GITHUB_TOKEN"'
  },
  {
    name: 'sshd_config_file',
    rule_type_id: 1,
    value: '(?i)sshd_config',
    description: 'SSH daemon configuration file'
  },
  {
    name: 'dhcpd_config_file',
    rule_type_id: 1,
    value: '(?i)dhcpd\.conf',
    description: 'DHCP daemon configuration file'
  },
  {
    name: 'otr_private_key_file',
    rule_type_id: 1,
    value: '(?i)otr\.private_key',
    description: 'Pidgin OTR private key file'
  },
  {
    name: 'mysql_history_file',
    rule_type_id: 1,
    value: '(?i)\.?mysql_history',
    description: 'MySQL history file'
  },
  {
    name: 'postgres_history_file',
    rule_type_id: 1,
    value: '(?i)\.?psql_history',
    description: 'PostgreSQL history file'
  },
  {
    name: 'irb_history_file',
    rule_type_id: 1,
    value: '(?i)\.?irb_history',
    description: 'Interactive Ruby Debugger (irb) history file'
  },
  {
    name: 'pidgin_accounts',
    rule_type_id: 1,
    value: '(?i)\.?purple/accounts\.xml',
    description: 'Pidgen client account configuration file'
  },
  {
    name: 'xchat_serverlist_file',
    rule_type_id: 1,
    value: '(?i)\.?xchat2/servlist_?\.conf',
    description: 'Pidgen client account configuration file'
  },
  {
    name: 'irssi_config_file',
    rule_type_id: 1,
    value: '(?i)\.?irssi/config',
    description: 'irssi IRC client configuration file'
  },
  {
    name: 'recon-ng_api_keys_file',
    rule_type_id: 1,
    value: '(?i)\.?recon-ng/keys\.db',
    description: 'Recon-ng Web Reconnassance Framework API key database'
  },
  {
    name: 'dbeaver_config_file',
    rule_type_id: 1,
    value: '(?i)\.?dbeaver-data-sources.xml',
    description: 'DBeaver SQL database manager configuration file'
  },
  {
    name: 'mutt_rc_file',
    rule_type_id: 1,
    value: '(?i)\.?muttrc',
    description: 'mutt email client configuration file'
  },
  {
    name: 'twitter_cli_config_file',
    rule_type_id: 1,
    value: '(?i)\.?trc\b',
    description: 'Twitter command line client configuration file'
  },
  {
    name: 'ovpn_config_file',
    rule_type_id: 1,
    value: '(?i)\.?ovpn',
    description: 'OpenVPN client configuration file'
  },
  {
    name: 'gitrob_config_file',
    rule_type_id: 1,
    value: '(?i)\.?gitrobrc',
    description: 'Gitrob configuration file :D'
  },
  {
    name: 'rails_secret_token_file',
    rule_type_id: 1,
    value: '(?i)secret_token\.rb',
    description: 'Rails secret token file'
  },
  {
    name: 'omniauth_config_file',
    rule_type_id: 1,
    value: '(?i)omniauth\.rb',
    description: 'OmniAuth configuration file'
  },
]
rules.each { |r| Rules.create(r) }


sensitive_rules = %w(
  npm_authentication_file find_docker_credentials
  crypto_key_file private_crypto_key sql_dump_file
  aws_access_key_file s3_config wordpress_config
  htpasswd_file env_file git_credentials_file
  pivotaltracker_token shell_rc_file find_rc_passwords
  find_rc_mailchimp find_rc_aws find_amazon_rds_credentials
  find_forecast_api_key find_salesforce_nodejs_credentials
  contains_sf_username contains_API_KEY tugboat_config
  netrc_file find_netrc_with_password robomongo_credentials_file
  find_filezilla_credentials find_docker_auth_data idea_key_file
  find_irc_pass db_connections_file openshift_config_file
  postgres_pass_file proftpd_passwd_file ventrilo_config_file
  winframe_client_config find_goldsrc_rcon_passwords
  contains_JEKYLL_GITHUB_TOKEN otr_private_key_file
  mysql_history_file postgres_history_file irb_history_file
  pidgin_accounts xchat_serverlist_file irssi_config_file
  recon-ng_api_keys_file dbeaver_config_file mutt_rc_file
  twitter_cli_config_file ovpn_config_file gitrob_config_file
  rails_secret_token_file omniauth_config_file
)

RuleSets.create(name: 'vulns', rules: ['strong_vuln_patterns'].to_json, description: 'Finds fixes for vulnerabilities')
RuleSets.create(name: 'sensitive', rules: sensitive_rules.to_json, description: 'Finds files which may contain sensitive information')

Projects.create(name: 'srcclr/commit_watcher', rule_sets: ['vulns'].to_json)
