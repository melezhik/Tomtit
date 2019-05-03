#/usr/bin/env bash

_dothis_completions()
{
  
  cur_word="${COMP_WORDS[COMP_CWORD]:-UNKNOWN}"
  prev_word=${COMP_WORDS[COMP_CWORD-1]:-UNKNOWN}

  type=$(perl6 -MTomtit::Completion -ecomplete $( IFS=$'\t'; echo "${COMP_WORDS[*]}" ) ${prev_word} ${cur_word} tp)
  list=$(perl6 -MTomtit::Completion -ecomplete $( IFS=$'\t'; echo "${COMP_WORDS[*]}" ) ${prev_word} ${cur_word} ls)


  if test "${type}" = "profile_list2"; then
    COMPREPLY=( $( compgen -W "${list}"))
  fi

  if test "${type}" = "profile_list"; then
    COMPREPLY=( $( compgen -W "${list}" -- ${COMP_WORDS[COMP_CWORD]}  ))
  fi

  if test "${type}" = "scenario_list2"; then
    COMPREPLY=( $( compgen -W "${list}"))
  fi

  if test "${type}" = "scenario_list"; then
    COMPREPLY=( $( compgen -W "${list}" -- ${COMP_WORDS[COMP_CWORD]}  ))
  fi

  if test "${type}" = "env_list2"; then
    COMPREPLY=( $( compgen -W "${list}" ))
  fi

  if test "${type}" = "env_list"; then
    COMPREPLY=( $( compgen -W "${list}" -- ${COMP_WORDS[COMP_CWORD]}  ))
  fi


  if test "${type}" = "opt_list"; then
    COMPREPLY=( $( compgen -W "${list}" -- ${COMP_WORDS[COMP_CWORD]}  ))
  fi


}

complete -F _dothis_completions tom
