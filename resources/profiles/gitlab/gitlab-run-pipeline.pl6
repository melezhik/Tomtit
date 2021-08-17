#!raku

task-run "pipe-run", "gitlab-run-pipeline", %(
  debug => True,
  project => 1001,
  gitlab_api => "https://git.company.com/api/v4/",
  variables => %(
    color => "green",
    size => "big",
    use_salt => True
  )
)
