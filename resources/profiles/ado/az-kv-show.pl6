#!perl6

task-run "keyvault secret", "azure-kv-show", %(
  kv      => 'changme', # key vault name
  secret  => 'changme'  # key vault secret
);

