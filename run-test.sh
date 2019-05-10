#!/bin/bash

st=0

for i in $(ls -1 test/); do 

  export scenario=$i

  perl6 -MSparrow6::Task::Runner -e '
  
  Sparrow6::Task::Runner::Api.new(
    name  => "{%*ENV<scenario>}",
    root  => "test/{%*ENV<scenario>}",
  ).task-run' || st=1
  
  echo $i; 

done


if test $st -eq 0; then
  echo all tests passed
else
  echo some tests failed
fi

exit $st

