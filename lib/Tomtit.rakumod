#!raku

unit module Tomtit:ver<0.1.35>;

use File::Directory::Tree;

use YAMLish;

use Sparrow6::Task::Repository;

use Sparrow6::DSL;

my %profiles is Map = (
  'perl' => ( 'set-pause', 'make-dist', 'install', 'test', 'changes', 'release' ),
  'raku' =>  ( 'test', 'install', 'changes', 'release' ),
  'cro' => ( 'cro-yaml' ),
  'git' => ( 'set-git', 'commit', 'push', 'git-branch-delete', 'pull', 'status', 'git-summary', 'git-publish', 'update-branch-list', 'github-url-https-to-ssh' ),
  'gitlab' => ( 'gitlab-run-pipeline' ), 
  'ruby' => ( 'rvm' ),
  'azure' => ( 'az-resources', 'az-account-set' , 'az-kv-show', 'az-sql-server-check-fw' ),
  'ado' => ( 'ado-pipeline-build-list', 'ado-pipeline-build-run' ),
  'hello' => ( 'world' ),
  'yaml' => ( 'yaml-lint' ),
  'tomtit' => ( 'tomtit-pl6-to-raku' ),
  'code' => ( 'search' ),
  'go' => ( 'go-build', 'go-format', 'proto' ),
);

# tom cli initializer

our sub check-if-init ( $dir ) is export {

  if ! ($dir.IO ~~ :d) {
	say "tomtit is not initialized, run tom --init";
	exit(1);
  }

}

our sub init ($dir) is export {

  mkdir $dir;

}
  
our sub load-conf () is export {

  my %conf = Hash.new;

  if $*DISTRO.is-win {
    if "{%*ENV<HOMEDRIVE>}{%*ENV<HOMEPATH>}/tom.yaml".IO ~~ :e {
      %conf = load-yaml(slurp "{%*ENV<HOMEDRIVE>}{%*ENV<HOMEPATH>}/tom.yaml");
    }
  } else {  
    if "{%*ENV<HOME>}/tom.yaml".IO ~~ :e {
      %conf = load-yaml(slurp "{%*ENV<HOME>}/tom.yaml");
    }
  }

  %conf;

}

sub tomtit-usage () is export  {
  say 'usage: tom $action|$options $thing'
}

sub tomtit-help () is export  {
  say q:to/DOC/;
  usage:
    tom $action|$options $thing

  run scenario:
    tom $scenario

  remove scenario:
    tom --remove $scenario

  print out scenario:
    tom --cat $scenario

  install profile:
    tom --profile $profile

  set default ennvironment
    tom --env-set $env

  actions:
	tom --init				# initialize tomtit
    tom --list              # list available scenarios
    tom --profile           # list available profiles
    tom --profile $profile  # list profile scenarios
    tom --last              # what is the last run?
    tom --completion        # install Bash completion
    tom --env-set $env      # set current environment
    tom --env-set           # show current environment
    tom --env-list          # list available environments

  options:
    --env=$env  # run scenario for the given environment
    --verbose   # run scenarios in verbose mode
    --quiet,-q  # run scenrios in less verbose mode
  DOC
}

# clean tomtit internal data
# is useful as with time it might grow

sub tomtit-clean ($dir) is export { 

  say "cleaning $dir/.cache ...";

  if "$dir/.cache/".IO ~~ :e {
    empty-directory "$dir/.cache"
  }

}

sub scenario-last ($dir) is export {
  if "$dir/.cache/history".IO ~~ :e {
    my @history =  "$dir/.cache/history".IO.lines;
    say @history[*-1];
  }
}

sub scenario-run ($dir,$scenario,%args?) is export {

  die "scenario $scenario not found" unless "$dir/$scenario.raku".IO ~~ :e;

  mkdir "$dir/.cache";

  my $fh = open "$dir/.cache/history", :a;
  $fh.print($scenario,"\n");
  $fh.close;

  my $conf-file;

  my $current-env = current-env("{$dir}/env");

  if %args<env> {

    $conf-file = %args<env> eq 'default' ?? "$dir/env/config.raku" !! "$dir/env/config.{%args<env>}.raku";

  } elsif $current-env eq 'default' &&  "$dir/env/config.raku".IO ~~ :e {

    $conf-file =  "$dir/env/config.raku";

  } elsif "$dir/env/config.{$current-env}.raku".IO ~~ :e  {

    $conf-file = "$dir/env/config.{$current-env}.raku";

  }

  if $conf-file && $conf-file.IO ~~ :e {
    say "load configuration from $conf-file";
    set-config(EVALFILE $conf-file);
  }

  Sparrow6::Task::Repository::Api.new().index-update unless %args<no-index-update>;

  EVALFILE "$dir/$scenario.raku";

}

sub scenario-remove ($dir,$scenario) is export {

  if "$dir/$scenario.raku".IO ~~ :e {
    unlink "$dir/$scenario.raku";
    say "scenario $scenario removed"
  } else {
    say "scenario $scenario not found"
  }

}

sub scenario-cat ($dir,$scenario,%args?) is export {

  if "$dir/$scenario.raku".IO ~~ :e {
    say "[scenario $scenario]";
    my $i=0;
    
    for "$dir/$scenario.raku".IO.lines -> $l {
      $i++;
      say %args<lines> ?? "[$i] $l" !! $l;
    }
  } else {
    say "scenario $scenario not found"
  }

}

sub scenario-edit ($dir,$scenario) is export {

    die "you should set EDITOR ENV to run editor" unless  %*ENV<EDITOR>;

    unless "$dir/$scenario.raku".IO ~~ :e {
      my $confirm = prompt("$dir/$scenario.raku does not exit, do you want to create it? (type Y to confirm): ");
      return unless $confirm eq 'Y';
    }

    shell "{%*ENV<EDITOR>} $dir/$scenario.raku";

}

sub current-env ($dir) {

  my $current;

  if "$dir/current".IO ~~ :e {
    $current = slurp "$dir/current";
  }

  return $current || "default"

}


sub environment-edit ($dir,$env) is export {

    die "you should set EDITOR ENV to run editor" unless  %*ENV<EDITOR>;

    mkdir $dir;

    my $conf-file = ( $env eq 'default' ) ?? "$dir/config.raku" !! "$dir/config.{$env}.raku";

    unless $conf-file.IO ~~ :e {
      my $confirm = prompt("$conf-file does not exit, do you want to create it? (type Y to confirm): ");
      return unless $confirm eq 'Y';
    }

    shell "{%*ENV<EDITOR>} $conf-file";

}

sub environment-list ($dir) is export {

    say "[environments list]";

    mkdir $dir;

    my @list = Array.new;

    my $current = current-env($dir);

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.raku$/;

      if $f.basename ~~ /config\.(.*)\.raku/ {

        @list.push("$0");

      } else {

        @list.push("default")

      }

    }

    for @list.sort -> $l {
      say $current eq $l ?? "$l *" !! $l
    };

}

sub environment-set ($dir,$env) is export {

  # next lines removes "current" symlink if it exist
  # we don't need this for tomty projects
  # generated by the latest version of Tomty
  # where environment manager no longer
  # uses symlinks

  unlink "$dir/current" if "$dir/current".IO ~~ :e;

  mkdir $dir;

  spurt "$dir/current", $env;

}

sub environment-show ($dir) is export {

  if "$dir/current".IO ~~ :e {

    my $current = "$dir/current".IO.resolve.IO.basename;

      if $current ~~ /config\.(.*)\.raku/ {

        say "current environment: $0"

      } else {

        say "current environment: default"

      }

  } elsif "$dir/config.raku".IO ~~ :e {

    say "default";

  } else {

    say "default environment is not set, create default configuration file (.tom/env/config.raku)
or use tom --set-env \$env to set default environments"
  }
  
}

sub environment-cat ($dir,$env,%args?) is export {

  my $conf-file;

  if $env eq "default" {
    $conf-file = "$dir/config.raku"
  } else {
    $conf-file = "$dir/config.{$env}.raku"
  }

  if "$conf-file".IO ~~ :e {
    say "[environment $env]";
    my $i=0;
    
    for "$conf-file".IO.lines -> $l {
      $i++;
      say %args<lines> ?? "[$i] $l" !! $l;
    }
  } else {
    say "environment $env not found"
  }

}

# scenario-doc function is implemented, but not presented in public API, 
# as there are some issues with compiling Sparrowdo scenarios

sub scenario-doc ($dir,$scenario) is export {

  die "scenario $scenario not found" unless "$dir/$scenario.raku".IO ~~ :e;

  run $*EXECUTABLE, '--doc', "$dir/$scenario.raku";

}

sub scenario-list ($dir) is export {

    my @list = Array.new;

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.raku$/;
      my $scenario-name = substr($f.basename,0,($f.basename.chars)-5);
      @list.push($scenario-name);

    }

    return @list.sort;

}

sub scenario-list-print ($dir) is export {

    my $current-env = current-env("$dir/env");

    say "[$current-env@scenarios list]";

    my @list = scenario-list($dir);

    say join "\n", @list.sort;

}

multi sub profile-list  is export {

  say "[profiles]";

  for %profiles.keys.sort -> $i {
    say "$i"
  }
}

multi sub profile-list($dir,$profile is copy)  is export {

  my @list;

  if $profile ~~ /^ 'Tomtit-Profile-' \w/ { # Portable profile, installed as Perl6 module

    $profile.=subst('-', '::', :g);

    say "load portable profile $profile as Perl6 module ...";

    require ::($profile);

    my $f = "profile-data"; 

    # profile-data() function is provided by $profile module

    @list = ::($profile ~ '::&profile-data')().keys.sort;
    
  } else {

    unless %profiles{$profile}:exists {
      say "profile $profile does not exist";
      return;
    }

    @list = %profiles{$profile}.sort;

  }

  say "[profile scenarios]";

  for @list -> $s {

    my $installed = "$dir/$s.raku".IO ~~ :f;

    say "$profile\@$s\tinstalled: $installed";

  }

}

sub profile-install ($dir, $profile is copy, %args?) is export {

  my @list;

  my $is-portable = False;

  if $profile ~~ /^ 'Tomtit-Profile-' \w/ { # Portable profile, installed as Raku module

    $is-portable = True;

    $profile.=subst('-', '::', :g);

  } elsif $profile ~~ s/ '@' (.*) // { # Core profile, $profile@scenario form

    my $s1 = $0;

    @list = sort &[cmp], grep { $_ eq $s1 }, %profiles{$profile}

  } else { # Core profile, $profile form

    @list = %profiles{$profile}.sort

  }

  if $is-portable {

    say "load prortable profile $profile as Raku module ...";

    require ::($profile);

    my $f = "profile-data"; 

    # profile-data() function is provided by $profile module

    my %list =  ::($profile ~ '::&profile-data')();

    for %list.keys.sort -> $s {
      say "install $profile\@$s ...";
      my $fh = open "$dir/$s.raku", :w;
      $fh.print(%list{$s});
      $fh.close;
    }

  } else {

    unless %profiles{$profile}:exists {
      say "profile $profile does not exist";
      return;
    }

    if @list.elems == 0 {
      say "no scenarios found ...";
      return;
    }

    for @list -> $s {
      if %?RESOURCES{"profiles/$profile/$s.raku"}.IO ~~ :f {
        say "install $profile\@$s ...";
        my $fh = open "$dir/$s.raku", :w;
        $fh.print(slurp %?RESOURCES{"profiles/$profile/$s.raku"});
        $fh.close;
      } else {
        say "no perl6 resource found for $profile\@$s scenario ... skipping it";
      }
    }

  }
    
}


sub completion-install () is export {

  say "install completion.sh ...";

  my $fh = open %*ENV<HOME> ~ '/.tom_completion.sh' , :w;

  $fh.print(slurp %?RESOURCES{"completion.sh"});

  $fh.close;

  say "to activate completion say: source " ~ %*ENV<HOME> ~ '/.tom_completion.sh';  
    
}

