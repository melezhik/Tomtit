#!perl6

task-run "check json files", "json-lint", %( path =>  "{$*CWD}" );

bash "perl6 -c lib/Tomtit.pm6";
bash "perl6 -c bin/tom";
bash "zef test .";
