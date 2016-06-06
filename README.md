# Commit Watcher

Commit Watcher finds interesting and potentially hazardous commits in git projects. Watch your own projects to make sure you didn't accidentally leak your AWS keys or other credentials, and watch open-source projects you use to find undisclosed security vulnerabilities and patches.

At [SourceClear](https://srcclr.com/), we want to help you use open-source software safely. Oftentimes when a security vulnerability is discovered and fixed in an open-source project, there isn't a public disclosure about it. In part, this is because the [CVE](https://en.wikipedia.org/wiki/Common_Vulnerabilities_and_Exposures) process is onerous and labor intensive, and notifying all the users of a project isn't possible.

Oh, and about that UI. Commit Watcher is intended to be an API accessible backend service. The UI is only there for testing, and the scope of functionality is limited to collecting commits and auditing them against a set of rules.

## Contributing

Commit Watcher ships with [dozens of rules and patterns](https://github.com/srcclr/commit-watcher/blob/master/db/seeds.rb) to find leaked credentials and potential security issues, but we'd love your help in adding more.

Additionally, if you find a security issue on an open-source project using Commit Watcher, our security research team would love to help verify it. You can open an issue against this repo from the UI, or just drop a link to the offending commit in a [new issue](https://github.com/srcclr/commit-watcher/issues/new).

## Setup

Install MySQL and Redis. On Mac, with Brew, you can do that with this command:

```bash
brew install mysql redis
```

Follow the instructions Brew gives you so the services are started properly.

Install gem dependencies:

```bash
gem install bundler
bundle install
```

Then setup some Rails secrets and passwords:

```bash
figaro install
echo "COMMIT_WATCHER_DATABASE_PASSWORD: 'changeme123'" >> config/application.yml
echo "SECRET_KEY_BASE: `rake secret`" >> config/application.yml
```

The rest of the setup depends on how you want to run Commit Watcher. You can either run it locally, which is good for quick development, or you can run it with Docker.

#### *Optional:* Configuring Email Notifications

To use email notifications, set your Gmail username and password with these commands:

```bash
echo "GMAIL_USERNAME: 'sah.dude@gmail.com'" >> config/application.yml
echo "GMAIL_PASSWORD: 'urpassbro'" >> config/application.yml
```

If you'd like to use another email provider other than Gmail, you'll have to change these two files: [`config/environments/development.rb`](config/environments/development.rb) and [`config/environments/production.rb`](config/environments/production.rb).

### Running Locally

Create the database, load the schema, and seed it with some sample rules:

```bash
rake db:setup
```

Now you're ready to start Rails with:

```bash
rails s
```

To start processing jobs, in another terminal:

```bash
bundle exec sidekiq
```

### Running with Docker

First, change the root and user passwords in [`.env.db`](.env.db).

```
# Not used but should set one for security.
MYSQL_ROOT_PASSWORD=changeme123

# This is for the commit_watcher user.
MYSQL_PASSWORD=changeme123
```

Second, modify [`config/database.yml`](config/database.yml) by commenting out `socket` in favor of `host`, like this:

```yaml
  # Use this for local mysql instances
  #socket: /tmp/mysql.sock

  # Use this for Docker
  host: db
```

Now start everything going with:

```bash
docker-compose up
```

This downloads the images and builds the database and rails app containers. When it's finished building, and both containers are running, you should see rails messages like this:

```
77bcf6cd5a_commitwatcher_web_1 | [2016-03-09 18:29:36] INFO  WEBrick 1.3.1
77bcf6cd5a_commitwatcher_web_1 | [2016-03-09 18:29:36] INFO  ruby 2.2.2 (2015-04-13) [x86_64-linux]
77bcf6cd5a_commitwatcher_web_1 | [2016-03-09 18:29:36] INFO  WEBrick::HTTPServer#start: pid=1 port=3000
```

Stop Docker with `Ctrl+C` so the database can be setup with:

```bash
docker-compose run web bundle exec rake db:schema:load db:seed
```

Now start everything up again with:

```bash
docker-compose up
```

## Use

If using Docker, the server will be accessible from the IP address given by:

```bash
docker-machine ip default
```

To crawl any projects, you must set a [GitHub API token](https://github.com/settings/tokens) in the default configuration. This can be reached here: [http://localhost:3000/configurations/1/edit](http://localhost:3000/configurations/1/edit).

The web UI contains a dashboard which links to all available pages. It's located here: [http://localhost:3000/](http://localhost:3000/).

Sidekiq dashboard is here: [http://localhost:3000/sidekiq/cron](http://localhost:3000/sidekiq/cron).

### Overview

The process starts by every few minutes any project which hasn't been checked in a while is polled for new commits. These commits are then checked against whatever rules are setup for the project. Any commits which match are recorded and available at the `/commits` endpoint.

Everything is broken up into different Sidekiq jobs. There are three:

1. Selecting projects which need to be polled
2. Collecting new commits
3. Auditing a single commit

### API Access

The API endpoints are similar to the web UI and are documented by code.

The app must have a hostname to access the API endpoints. This can be done in development by adding a record to the host file:

```bash
echo "127.0.0.1 api.my_app.dev" >> /etc/hosts
```

Then the API can be accessed by:
```bash
curl http://api.my_app.dev:3000/v1/commits
```

## Rules

Rule types are defined and described in [config/rule_types.yml](config/rule_types.yml). They are:

* `filename_pattern` - Regular expression for a filename
* `changed_code_pattern` - Regular expression for a changed line
* `code_pattern` - Regular expression for any code in a changed file
* `message_pattern` - Regular expression for a commit message
* `author_pattern` - Regular expression for a commit author name, normalized to "name <email>"
* `commit_pattern` - Combination of code_pattern and message_pattern
* `expression` - Boolean expression referencing one or more rules

### Expression Rules

This is a special rule type that allows for combining multiple rules in a boolean expression. The boolean expression has three operators: `&&` (and), `||` (or), `!` (not), and also allows for parenthetical expressions.

For example, if there are three rules:

1. `is_txt` - `/\.txt\z/` (filename_pattern)
2. `has_lulz_msg` - `/\blulz\b/` (message_pattern)
3. `has_42` - `/\b42\b/` (code_pattern)

To create an expression rule which would match commits that include "lulz" in the commit message and contains at least a single text file _or_ has a file with the word "42":

```
(is_txt && has_lulz_msg) || has_42
```

To match a commit where any file is not a text file and includes "42":

```
!is_txt && has_42
```

### Submitting Your Rules

To submit a rule to this project, use this commit as an example: [https://github.com/srcclr/commit-watcher/commit/3ae9e2d340f1ac4d10c9ebffae64c22b0a6ac706](https://github.com/srcclr/commit-watcher/commit/3ae9e2d340f1ac4d10c9ebffae64c22b0a6ac706)

Let's break down the rule a bit:

```
{
  name: 'markdown_file',
  rule_type_id: 1,
  value: '(?i)\.(md|markdown)\z',
  description: 'Markdown file'
}
```

There are four different values for the rule:

1. name - unique name, valid characters are alpha numeric, '-', '_', and '.'
2. rule\_type\_id - this is the ID for a rule type described above
3. value - regular expression; this example could be read as "case insensitive, starts with a '.' and is followed either by 'md' or 'markdown' and then the end of the string"
4. description - free text field for describing the rule
