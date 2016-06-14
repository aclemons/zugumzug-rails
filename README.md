# Zug um Zug as a rails app

This is a simple implementation of the game Zug um Zug as a Rails app.

## Installation

This requires `ruby` (tested with `ruby 2.2.5p319`) and the ruby gem `bundler` (tested with `1.12.1`).

After cloning this repo run:

        $ gem install -i vendor/bundle -v 1.12.1 bundler
        $ ./bin/bundle install --path vendor/bundle

## Configuration

The default configuration for development uses a PostgreSQL database. The
configuration for this should be done in `config/database.yml`. You'll need
adapt this for your PostgreSQL instance. To get started quickly, you can
comment out the PostgreSQL development database in the file, and restore the
sqlite values.

Then to initialise the database:

        $ ./bin/rake db:migrate RAILS_ENV=development
        $ ./bin/rake db:seed RAILS_ENV=development

## Running

To start the server in development mode:

        $ ./bin/rails s

To listen on all interfaces:

        $ ./bin/rails s --binding=0.0.0.0

## CLI

The app also provides a set of rest services for interacting with
the game. There is an example client implemented as a shell script
`cli.sh`. It requires a few dependencies:

* posix compliant sh
* awk
* curl
* dialog
* gnuplot
* jsawk
* sed

These should all be available through your package manager. On OS X, you will
have to edit the gnuplot homebrew formula to compile in support for libcaca:

        $ brew install libcaca
        $ brew edit gnuplot
        $ # add the option with-caca
        $ brew install -s gnuplot --with-wxmac

