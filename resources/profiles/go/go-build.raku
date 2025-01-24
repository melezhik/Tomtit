my $path = [
  "cmd/main.go",
];

task-run "build", "go-build", %(
  :$path,
);
