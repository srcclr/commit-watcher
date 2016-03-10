# Commit Watcher

Commit Watcher monitors the commits of a configurable list GitHub projects. If any commit matches a rule such as "contains the pattern `/vulnerability disclosure/`" or "Gemfile was modified", it is recorded so it can be examined later.

The goal of this project was to allow the research team to watch the commits of certain repositories for commits which look like they fix undisclosed security vulnerabilities which we could then investigate and share with the community. In some cases the developer may not realize or wish to disclose that a vulnerability existed or that a particular commit fixed the vulnerability, but the commit message or changed code may hint that a commit has to do with a security fix.

Commit Watcher is intended to be an API accessible backend service. The UI is only there for testing, and the scope of functionality is limited to 1.) collecting commits and 2.) auditing them against a set of rules.

## Setup

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

The rest of the setup depends on how you want to run Commit Watcher. You can either run it locally, which is good for quick development or you can run it with Docker.

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

Second, modify [`configs/database.yml`](configs/database.yml) by commenting out `socket` in favor of `host`, like this:

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
