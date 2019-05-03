task-run "check fw rules", "azure-sql-server-check-fw", %(
  name => "changeme",
  group => "changeme",
  allow => [ # allowed ip addresses
    #["192.168.0.0", "192.168.0.0.255"],
    ["0.0.0.0", "0.0.0.0"],
  ]
);
