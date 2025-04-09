my $type  = prompt("type: ");

task-run "dump type", "proto-parser", %(
  :file<file.proto>,
  :action<dump>,
  :$type,
);
