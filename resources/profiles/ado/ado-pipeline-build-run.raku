task-run 'build run', 'ado-pipeline-build', %(
    name => config()<pipeline-name>,
    action => "run"
)