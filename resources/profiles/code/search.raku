my $ext = prompt("ext (go): ");

$ext = "go" unless $ext;

my $search1 = prompt("search1: ");

my $search2 = prompt("search2: ");

my $exclude = prompt("exclude: ");

task-run "find $search1 $search2 in $ext", "find", %(
  :$ext,
  :$search1,
  :$search2,
  :$exclude,
);
