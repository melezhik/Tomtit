#!perl6

task-run "Keyvault Secrets", "azure-kv-show", %(
  kv      => 'changme', # key vault name
  secret  => 'changme'  # key vault secret
);

