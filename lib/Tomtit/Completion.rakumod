use v6;

# this module is not meant for direct usage
# it's used for Bash completion
# perl -MTomtit::Completion -ecomplete @args
# see also resources/completion.sh


unit module Tomtit::Completion;

require Tomtit;

my %config = ::("Tomtit::" ~ '&load-conf')();

sub complete () is export {

  my @args = @*ARGS;

  my $mode = @args[*-1]:delete;
  my $current-word = @args[*-1]:delete;
  my $prev-word = @args[*-1]:delete;


  my $args = @args.join(" ");

    if %*ENV<TOMTIT_COMPLETE_DEBUG> {

      my $fh = open "/tmp/complete.txt", :a;
      $fh.say("current word: <$current-word>");
      $fh.say("prev word: <$prev-word>");
      $fh.say("history: <$args>");
      $fh.close;

    }



  if $prev-word eq '--help' {
    return
  }


  # scenarios

  if $prev-word eq 'tom' and $current-word ~~ /^ '--cat' | '--edit' | '--remove' /  {

    my $list = scenario-list("{$*CWD}/.tom",2);

    print $mode eq 'tp' ?? 'scenario_list' !! $list;

    return

  }

  if $prev-word ~~ /^ '--cat' | '--edit' | '--remove' / or $current-word ~~ /^ '--cat' | '--edit'  | '--remove' / {

    my $list = scenario-list("{$*CWD}/.tom");

    print $mode eq 'tp' ?? 'scenario_list' !! $list;

    return

  }

  # profiles

  if $prev-word eq 'tom' and $current-word ~~ /^ '--profile'  /  {

    my $list = profile-list(2);

    print $mode eq 'tp' ?? 'profile_list' !! $list;

    return

  }

  if $prev-word ~~ /^ '--profile' / or $current-word ~~ /^ '--profile' / {

    my $list = profile-list();

    print $mode eq 'tp' ?? 'profile_list' !! $list;

    return

  }

  # environments

  if $prev-word eq 'tom' and $current-word ~~ /^ '--env-set' | '--env-edit' | '--env-cat' /  {

    my $list = environment-list("{$*CWD}/.tom/env",2);

    print $mode eq 'tp' ?? 'env_list' !! $list;

    return

  }

  if $prev-word ~~ /^ '--env-set' | '--env-edit' | '--env-cat' / or $current-word ~~ /^ '--env-set' | '--env-edit' | '--env-cat' / {

    my $list = environment-list("{$*CWD}/.tom/env");

    print $mode eq 'tp' ?? 'env_list' !! $list;

    return

  }


  # scenarios

  if $prev-word eq 'tom' && $current-word eq "UNKNOWN" {

    my $list = scenario-list("{$*CWD}/.tom/");

    print $mode eq 'tp' ?? 'scenario_list2' !! $list;

    return;

  }

  # options

  if $current-word ~~ /^ '-' ** 1..2 / {

    my $list = options-list();
    
    print $mode eq 'tp' ?? 'opt_list' !! $list;
   
    return;

  }


  # scenarios

  my $list = scenario-list("{$*CWD}/.tom/");

  print $mode eq 'tp' ?? 'scenario_list' !! $list;

  return;

}



sub options-list {

  my $list =  "--verbose --quiet -q --color --completion --clean --dump_task --help --init --list --profile --remove --doc --cat --lines --last --edit --env-cat --env-set --env-edit --env-list";

    if %*ENV<TOMTIT_COMPLETE_DEBUG> {

      my $fh = open "/tmp/complete.txt", :a;
      $fh.say("options list triggered");
      $fh.say($list);
      $fh.close;
    }

    return $list;
}

sub profile-list ($type = 1) {


  my @list = ( 'ado', 'azure', 'cro', 'git', 'gitlab', 'hello', 'perl', 'raku', 'ruby', 'yaml', 'tomtit' );

    if %*ENV<TOMTIT_COMPLETE_DEBUG> {

      my $fh = open "/tmp/complete.txt", :a;

      $fh.say("profiles list triggered, type: $type");
      $fh.say(join ' ', @list);
      $fh.close;

    }

    if %config<profiles>:exists && %config<profiles>.^name eq 'Array' {
      for %config<profiles> -> $p {
        unless $p.^name eq 'Bool' {
          push @list, $p;
        }
      }
    }

    return join ' ', @list;
}


sub scenario-list ($dir, $type = 1) {

    my @list = Array.new;

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.raku$/;
      my $scenario-name = substr($f.basename,0,($f.basename.chars)-5);
      @list.push($scenario-name);

    }

    if %*ENV<TOMTIT_COMPLETE_DEBUG> {

      my $fh = open "/tmp/complete.txt", :a;
      $fh.say("scenario list triggered, type: $type");
      $fh.say("{join " ", @list.sort}");
      $fh.close;

    }

    join " ", @list.sort;

}

sub environment-list ($dir, $type = 1 )  {


    my @list = Array.new;

    my $current = "default";

    if "$dir/current".IO ~~ :e  && "$dir/current".IO.resolve.IO.basename {

      if "$dir/current".IO.resolve.IO.basename ~~ /config\.(.*)\.raku/ {
        $current = "$0"
      }

    }

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.raku$/;

      if $f.basename ~~ /config\.(.*)\.raku/ {

        @list.push("$0");

      } else {

        @list.push("default")

      }

    }

    if %*ENV<TOMTIT_COMPLETE_DEBUG> {

      my $fh = open "/tmp/complete.txt", :a;
      $fh.say("environments list triggered, type: $type");
      $fh.say("{join " ", @list.sort}");
      $fh.close;

    }

    join " ", @list.sort;

}

