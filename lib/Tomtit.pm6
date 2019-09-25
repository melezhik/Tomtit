#!perl6

use v6;

unit module Tomtit:ver<0.1.4>;

use File::Directory::Tree;

use YAMLish;

use Sparrow6::Task::Repository;

use Sparrow6::DSL;

my %profiles is Map = (
  'perl' => ( 'set-pause', 'make-dist', 'install', 'test', 'changes', 'release' ),
  'perl6' =>  ( 'set-pause', 'test', 'install', 'changes', 'release' ),
  'git' => ( 'set-git', 'commit', 'push', 'pull', 'status', 'git-summary', 'git-publish', 'update-branch-list' ),
  'ruby' => ( 'rvm' ),
  'azure' => ( 'az-resources', 'az-account-set' , 'az-kv-show', 'az-sql-server-check-fw' ),
  'ado' => ( 'ado-pipeline-build-list', 'ado-pipeline-build-run' ),
  'hello' => ( 'world' ),
  'yaml' => ( 'yaml-lint' )
);

# tom cli initializer
  
our sub init () is export {

  mkdir ".tom/.cache";
  mkdir ".tom/env";
  my %conf = Hash.new;

  if $*DISTRO.is-win {
    if "{%*ENV<HOMEDRIVE>}{%*ENV<HOMEPATH>}/tomty.yaml".IO ~~ :e {
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

  die "scenario $scenario not found" unless "$dir/$scenario.pl6".IO ~~ :e;

  my $fh = open "$dir/.cache/history", :a;
  $fh.print($scenario,"\n");
  $fh.close;

  my $conf-file;

  my $current-env = current-env("{$dir}/env");

  if %args<env> {

    $conf-file = %args<env> eq 'default' ?? "$dir/env/config.pl6" !! "$dir/env/config.{%args<env>}.pl6";

  } elsif $current-env eq 'default' &&  "$dir/env/config.pl6".IO ~~ :e {

    $conf-file =  "$dir/env/config.pl6";

  } elsif "$dir/env/config.{$current-env}.pl6".IO ~~ :e  {

    $conf-file = "$dir/env/config.{$current-env}.pl6";

  }

  if $conf-file && $conf-file.IO ~~ :e {
    say "load configuration from $conf-file";
    set-config(EVALFILE $conf-file);
  }

  Sparrow6::Task::Repository::Api.new().index-update;

  EVALFILE "$dir/$scenario.pl6";

}

sub scenario-remove ($dir,$scenario) is export {

  if "$dir/$scenario.pl6".IO ~~ :e {
    unlink "$dir/$scenario.pl6";
    say "scenario $scenario removed"
  } else {
    say "scenario $scenario not found"
  }

}

sub scenario-cat ($dir,$scenario,%args?) is export {

  if "$dir/$scenario.pl6".IO ~~ :e {
    say "[scenario $scenario]";
    my $i=0;
    
    for "$dir/$scenario.pl6".IO.lines -> $l {
      $i++;
      say %args<lines> ?? "[$i] $l" !! $l;
    }
  } else {
    say "scenario $scenario not found"
  }

}

sub scenario-edit ($dir,$scenario) is export {

    die "you should set EDITOR ENV to run editor" unless  %*ENV<EDITOR>;

    unless "$dir/$scenario.pl6".IO ~~ :e {
      my $confirm = prompt("$dir/$scenario.pl6 does not exit, do you want to create it? (type Y to confirm): ");
      return unless $confirm eq 'Y';
    }

    shell "{%*ENV<EDITOR>} $dir/$scenario.pl6";

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

    my $conf-file = ( $env eq 'default' ) ?? "$dir/config.pl6" !! "$dir/config.{$env}.pl6";

    unless $conf-file.IO ~~ :e {
      my $confirm = prompt("$conf-file does not exit, do you want to create it? (type Y to confirm): ");
      return unless $confirm eq 'Y';
    }

    shell "{%*ENV<EDITOR>} $conf-file";

}

sub environment-list ($dir) is export {

    say "[environments list]";

    my @list = Array.new;

    my $current = current-env($dir);

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.pl6$/;

      if $f.basename ~~ /config\.(.*)\.pl6/ {

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

  spurt "$dir/current", $env;

}

sub environment-show ($dir) is export {

  if "$dir/current".IO ~~ :e {

    my $current = "$dir/current".IO.resolve.IO.basename;

      if $current ~~ /config\.(.*)\.pl6/ {

        say "current environment: $0"

      } else {

        say "current environment: default"

      }

  } elsif "$dir/config.pl6".IO ~~ :e {

    say "default";

  } else {

    say "default environment is not set, create default configuration file (.tom/env/config.pl6)
or use tom --set-env \$env to set default environments"
  }
  
}

sub environment-cat ($dir,$env,%args?) is export {

  my $conf-file;

  if $env eq "default" {
    $conf-file = "$dir/config.pl6"
  } else {
    $conf-file = "$dir/config.{$env}.pl6"
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

  die "scenario $scenario not found" unless "$dir/$scenario.pl6".IO ~~ :e;

  run $*EXECUTABLE, '--doc', "$dir/$scenario.pl6";

}

sub scenario-list ($dir) is export {

    my @list = Array.new;

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.pl6$/;
      my $scenario-name = substr($f.basename,0,($f.basename.chars)-4);
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

    my $installed = "$dir/$s.pl6".IO ~~ :f;

    say "$profile\@$s\tinstalled: $installed";

  }

}

sub profile-install ($dir, $profile is copy, %args?) is export {

  my @list;

  my $is-portable = False;

  if $profile ~~ /^ 'Tomtit-Profile-' \w/ { # Portable profile, installed as Perl6 module

    $is-portable = True;

    $profile.=subst('-', '::', :g);

  } elsif $profile ~~ s/ '@' (.*) // { # Core profile, $profile@scenario form

    my $s1 = $0;

    @list = sort &[cmp], grep { $_ eq $s1 }, %profiles{$profile}

  } else { # Core profile, $profile form

    @list = %profiles{$profile}.sort

  }

  if $is-portable {

    say "load prortable profile $profile as Perl6 module ...";

    require ::($profile);

    my $f = "profile-data"; 

    # profile-data() function is provided by $profile module

    my %list =  ::($profile ~ '::&profile-data')();

    for %list.keys.sort -> $s {
      say "install $profile\@$s ...";
      my $fh = open "$dir/$s.pl6", :w;
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
      if %?RESOURCES{"profiles/$profile/$s.pl6"}.Str.IO ~~ :f {
        say "install $profile\@$s ...";
        my $fh = open "$dir/$s.pl6", :w;
        $fh.print(slurp %?RESOURCES{"profiles/$profile/$s.pl6"}.Str);
        $fh.close;
      } else {
        say "no perl6 resource found for $profile\@$s scenario ... skipping it";
      }
    }

  }
    
}


sub completion-install () is export {

  say "install completion.sh ...";

  my $fh = open '/home/' ~ %*ENV<USER> ~ '/.tom_completion.sh' , :w;

  $fh.print(slurp %?RESOURCES{"completion.sh"}.Str);

  $fh.close;

  say "to activate completion say: source " ~ '/home/' ~ %*ENV<USER> ~ '/.tom_completion.sh';  
    
}

