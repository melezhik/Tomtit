my $file = "file.proto";

my $st = task-run "list types", "proto-parser", %(
  :$file,
);


my $i = 1;

my @list = $st<list><>;

say "nn type name";

for @list -> $o {
  say "[$i] {$o<type>} {$o<name>}";
  $i++;
}

say "===";

if $st<list> {
  my $n = prompt("type (1 .. {@list.elems}): ");
  my $type = @list[$n-1]<name>;
  task-run "dump", "proto-parser", %(
    :$type,
    action => "dump",
    :$file,
  );
}
