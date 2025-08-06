# Tomtit

Tomtit - Raku Task Runner

# Build Status

![SparkyCI](https://sparky.sparrowhub.io/badge/gh-melezhik-Tomtit?foo=bar)

# Install

```bash
zef install Tomtit
```

# Quick start

Tomtit is a task runner based on Sparrow6 engine, so just drop a few tasks under _some_ folder
and run them as Raku scenarios:

```bash
mkdir -p tasks/hello
```

`tasks/hello/task.bash`:

```bash
echo "hello world"
```

`.tom/hello.raku`:

```raku
task-run "tasks/hello";
```

You can do _more_ then that, [read more](https://github.com/melezhik/Sparrow6/blob/master/documentation/development.md) 
about Sparrow6 tasks on Sparrow6 documentation.

# Cli api

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

# Create scenarios

Tomtit scenarios are just Raku wrappers for underlying Sparrow6 tasks. 

Create a `.tom` directory, to hold all the scenarios:

    mkdir .tom/
    nano .tom/build.raku
    nano .tom/test.raku
    nano .tom/install.raku

And the drop some tasks at _some_ folder:

`tasks/build/task.bash`:

```bash
set -e
make
make test
sudo make install 
```

`.tom/build.raku`:

```raku
task-run "tasks/build";
```

Note above that the primary task in the folder has the filename `task.bash`.
In your scenario file, the `task-run` command will only take a directory, but 
it will be looking for a file with the name `task.*` (where * can be any of 
the supported languages).

You might want to ignore Tomtit cache which commit files to SCM:

    git add .tom/
    echo .tom/.cache >> .gitignore


# Using pre built Sparrow6 DSL functions

[Sparrow6 DSL](https://github.com/melezhik/Sparrow6/blob/master/documentation/dsl.md) provides
one with ready to use function for some standard automation tasks:


`.tom/example.raku`:

```raku

# you can use Sparrow6 DSL functions
# to do many system tasks, like:

# creation of files and directories

file 'passwords.txt', %( 
    owner => "root",
    mode => "700",    
    content => "super secret" 
);

directory '.cache', %(
    owner => "server"
);

# or restarting of services

service-restart "web-app";

# or you can run a specific sparrow plugin
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
```

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

Tomtit exposes API to create portable profiles as regular Raku modules.

You should create Raku module in `Tomtit::Profile` namespace with the _our_ function `profile-data`, 
returning `Hash` with scenarios data.

For example:

```raku
unit module Tomtit::Profile::Pets:ver<0.0.1>;

our sub profile-data () {

    my %a is Map  = (
        cat   => (slurp %?RESOURCES<cat.raku>.Str),
        dog   => (slurp %?RESOURCES<dog.raku>.Str),
        fish  => (slurp %?RESOURCES<fish.raku>.Str)
    );

}
```

The above module defines [Tomtit::Profile::Pets](https://github.com/melezhik/tomtit-profile-pets) profile with 3 scenarios `cat, dog, fish` installed as module resources:

    resources/
      cat.raku
      dog.raku
      fish.raku


Now we can install it as regular Raku module and use through tom:

    zef install Tomtit::Profile::Pets

Once module is installed we can install related profile. Note that we should replace `::` by `-` (\*) symbols
when referring to profile name.

    tom --list --profile Tomtit-Profile-Pets

    load portable profile Tomtit::Profile::Pets as Raku module ...
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

* Tomtit environments are configuration files, written on Raku and technically speaking are plain Raku Hashes

* Environment configuration files should be placed at `.tom/conf` directory:

.tom/env/config.raku:


    {
        name => "Tomtit",
        who-are-you => "smart bird"

    }

Run Tomtit.

It will pick the `.tom/env/config.raku` and read configuration from it, variables will be accessible as `config` Hash,
inside Tomtit scenarios:


    my $name = config<name>;
    my $who-are-you = config<who-are-you>;


To define _named_ configuration ( environment ), simply create `.tom/env/config{$env}.raku` file and refer to it through 
`--env=$env` parameter:

    nano .tom/env/config.prod.raku

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

## Common environments

It's handy to have so called common environments that get mixed into any environment
adding some common configuration data. Just create `any` environemnt and that's will be it:

```bash
tom --edit any
```

```raku
#!raku
%(
  foo => "bar",
  id => 1000,
)
```

```bash
tom --edit my
```

```raku
#!raku
%(
  # override some default
  # parameters
  # defined in any
  foo => "bar1",
  name => "John",
)
```

```
tom --edit dump-conf
```

```raku
say config().raku;
```

```
tom --env=my dump-conf
```

```
load configuration from /Users/alex/projects/Tomtit/.tom/env/config.my.raku
mix in common configuration from /Users/alex/projects/Tomtit/.tom/env/config.any.raku
14:11:47 :: [repository] - index updated from https://sparrowhub.io/repo/api/v1/index
{:foo("bar1"), :id(1000), :name("John")}
```

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

    --verbose          # run scenario in verbose mode
    --quiet,-q         # run scenario in less verbose mode
    --color            # color output
    --no_index_update  # don't update Sparrow repository index
    --dump_task        # dump task code before execution, see SP6_DUMP_TASK_CODE Sparrow documentation

Example of `~/tom.yaml` file:

```yaml
options:
  no_index_update: true
  quiet: true
```

# Bash completion

You can install Bash completion for tom cli.

    tom --completion
    source  ~/.tom_completion.sh

# Development

    git clone https://github.com/melezhik/Tomtit.git
    zef install --/test .
    zef install Tomtit
    tom

# See also

* [ake](https://github.com/Raku/ake) - a Raku make-a-like inspired by rake

# Author

Alexey Melezhik

# Thanks to

God Who gives me inspiration in my work
