# knife-mysql

`knife-mysql` is a [knife](http://docs.getchef.com/knife.html) plugin for working with MySQL databases on servers managed by [Chef](http://getchef.com/).

## Installation

`gem install knife-mysql`

## Usage

### scp

    knife mysql scp SOURCE DESTINATION (options)

The `knife mysql scp` subcommand makes it easy to copy databases between nodes.

This task will `ssh` to each node matching the [source query](http://docs.getchef.com/essentials_search.html) and `mysqldump` the requested databases to a SQL file,
then download the resulting file to your local machine, and then upload it to each node matching the destination query, finally importing the data to `mysql` and
cleaning up all the files.

#### Examples

Copying a single database from one node to another.

    $ knife mysql scp name:db1.example.com name:db2.example.com --databases db_example

Copying everything from your `production` database servers into a `staging` environment.

    $ knife mysql scp "role:database AND chef_environment:production" "role:database AND chef_environment:staging"

See `knife mysql scp --help` for the full list of options.

## Contributing

Please do! Open a pull request with your changes and I'll be happy to review it.

## License

Copyright (c) 2014 Logan Koester. Released under the MIT license. See LICENSE-MIT for details.
