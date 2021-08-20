# Tomtit

Tomtit - Raku Task Runner.

# Build Status

[![Build Status](https://travis-ci.org/melezhik/tomtit.svg?branch=master)](https://travis-ci.org/melezhik/tomtit)

# INSTALL

    zef install tomtit

# USAGE

    tom $action|$options $thing

Initialize tomtit:

	tom --init

Run scenario:

    tom $scenario

Default action (list of scenarios):

    tom

List available scenarios:

    tom --list

Get help:

    tom --help

Show the last executed scenario:

    tom --last

Clean Tomtit cache:

    tom --clean

Example:

    tom --list

    [scenarios list]
    test
    build
    install

    tom test        

# Defining scenarios

Tomtit scenarios are just Sparrow6 scenarios you create in `.tom` directory, which is base Tomtit directory:
  
    mkdir .tom/
    nano .tom/build.pl6
    nano .tom/test.pl6
    nano .tom/install.pl6

You want to ignore Tomtit cache which commit files to SCM:

    git add .tom/
    echo .tom/.cache >> .gitignore


# Scenario example

You can do anything, allowable through [Sparrow6 DSL](https://github.com/melezhik/Sparrow6/blob/master/documentation/dsl.md), like:

    cat .tom/example.pl6

    # you can use Sparrow6 DSL functions
    # to do many system tasks, like:

    # create files and directories

    file 'passwords.txt', %( content => "super secret" );

    directory '.cache';

    # or restart service

    service-restart "web-app";

    # or you can run a certain sparrow plugin
    # by using task-run function:

    task-run 'my task', 'plugin', %( foo => 'bar' );

    # for example, to set git repository, 
    # use git-base plugin:
 
    task-run "set git", "git-base", %(
      email => 'melezhik@gmail.com',
      name  => 'Alexey Melezhik',
      config_scope => 'local',
      set_credential_cache => 'on'
    );

    
And so on.

As result you minimize code to execute many typical tasks.


# Profiles

Profiles are predefined sets of Tomtit scenarios.
To start using scenarios from profile you say:

    tom --profile $profile

Once the command is executed the profile scenarios get installed to the
base Tomtit directory.

To list available profiles say this:

    tom --profile

To list profiles scenarios say this:

    tom --list --profile $profile

You can install selected scenario from profile by using special notation:

    tom --profile $profile@$scenario

For example to install `commit` scenario from `git` profile:

    tom --profile git@commit 

# Portable profiles

Tomtit exposes API to create portable profiles as regular Perl6 modules.

You should create Perl6 module in `Tomtit::Profile` namespace with the _our_ function `profile-data`, 
returning `Hash` with scenarios data.

For example:


    #!raku

    use v6;

    unit module Tomtit::Profile::Pets:ver<0.0.1>;

    our sub profile-data () {

      my %a is Map  = (
        cat   => (slurp %?RESOURCES<cat.pl6>.Str),
        dog   => (slurp %?RESOURCES<dog.pl6>.Str),
        fish  => (slurp %?RESOURCES<fish.pl6>.Str)
      );

    }



The above module defines [Tomtit::Profile::Pets](https://github.com/melezhik/tomtit-profile-pets) profile with 3 scenarios `cat, dog, fish` installed 
as module resources:

    resources/
      cat.pl6
      dog.pl6
      fish.pl6


Now we can install it as regular Perl6 module and use through tom:

    zef install Tomtit::Profile::Pets

Once module is installed we can install related profile. Note that we should replace `::` by `-` (\*) symbols
when refering to profile name.

    tom --list --profile Tomtit-Profile-Pets

    load portable profile Tomtit::Profile::Pets as Perl6 module ...
    [profile scenarios]
    Tomtit::Profile::Pets@cat       installed: False
    Tomtit::Profile::Pets@dog       installed: False
    Tomtit::Profile::Pets@fish      installed: False

    tom --profile Tomtit-Profile-Pets

    install Tomtit::Profile::Pets@cat ...
    install Tomtit::Profile::Pets@dog ...
    install Tomtit::Profile::Pets@fish ...

(\*) Tomtit require such a mapping so that Bash completion could work correctly.

# Removing scenarios

To remove installed scenario say this:

    tom --remove $scenario

# Edit scenario source code

Use `--edit` to create scenario from the scratch or to edit existed scenario source code:

    tom --edit $scenario

# Getting scenario source code

Use `--cat` command to print out scenario source code:

    tom --cat $scenario

Use `--lines` flag to print out with line numbers.

# Environments

* Tomtit environments are configuration files, written on Perl6 and technically speaking are plain Perl6 Hashes

* Environment configuration files should be placed at `.tom/conf` directory:

.tom/env/config.pl6:


    {
        name => "Tomtit",
        who-are-you => "smart bird"

    }

Run Tomtit.

It will pick the `.tom/env/config.pl6` and read configuration from it, variables will be accessible as `config` Hash,
inside Tomtit scenarios:


    my $name = config<name>;
    my $who-are-you = config<who-are-you>;


To define _named_ configuration ( environment ), simply create `.tom/env/config{$env}.pl6` file and refer to it through 
`--env=$env` parameter:


    nano .tom/env/config.prod.pl6

    tom --env=prod ... other parameters here # will run with production configuration

You can run editor for environment configuration by using --edit option:

    tom --env-edit test    # edit test enviroment configuration

    tom --env-edit default # edit default configuration

You can activate environment by using `--env-set` parameter:

    tom --env-set prod    # set prod environment as default
    tom --env-set         # to list active (current) environment
    tom --env-set default # to set current environment to default

To view environment configuration use `--env-cat` command:

    tom --env-cat $env

You print out the list of all environments by using `--env-list` parameters:

    tom --env-list

# Tomtit cli configuration

You can set Tomtit configuration in `~/tom.yaml` file:

    # list of portable Tomtit profiles,
    # will be available through Bash completion

    profiles:

      - Tomtit-Foo
      - Tomtit-Bar
      - Tomtit-Bar-Baz

    # you can also setup some Tomtit cli options here

    options:

      quiet: true

# Options

        --verbose   # run scenario in verbose mode
        --quiet,-q  # run scenario in less verbose mode
        --color     # color output

# Bash completion

You can install Bash completion for tom cli.

    tom --completion
    source  ~/.tom_completion.sh

# Development


    git clone https://github.com/melezhik/Tomtit.git
    zef install --/test .
    zef install Tomty
    tomty --all # run tests


# Author

Alexey Melezhik


# Thanks to

God Who gives me inspiration in my work

