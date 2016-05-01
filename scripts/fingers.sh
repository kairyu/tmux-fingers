#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/config.sh
source $CURRENT_DIR/actions.sh
source $CURRENT_DIR/hints.sh

current_pane_id=$1
fingers_pane_id=$2
tmp_path=$3

BACKSPACE=$'\177'

function clear_screen() {
  clear
  tmux clearhist
}

function has_capitals() {
  echo $1 | grep [A-Z] | wc -l
}

clear_screen
print_hints

function handle_exit() {
  tmux swap-pane -s $current_pane_id -t $fingers_pane_id
  tmux kill-pane -t $fingers_pane_id
  rm -rf $tmp_path
}

function copy_result() {
  local result=$1
  clear
  echo -n "$result"
  start_copy_mode
  top_of_buffer
  start_of_line
  start_selection
  end_of_line
  cursor_left
  copy_selection
}

trap "handle_exit" EXIT

input=''
while read -r -s -n1 char
do
  if [[ $char == "$BACKSPACE" ]]; then
    input=""
  else
    input="$input$char"
  fi

  result=$(lookup_match "$input")

  tmux display-message "$input"

  if [[ -z $result ]]; then
    continue
  fi

  #TODO meeec, still not working
  #if [[ $(has_capitals $input) == "1" ]]; then
    #tmux command-prompt -p "fingers-exec:" "run-shell -t $fingers_pane_id $CURRENT_DIR/exec.sh '%%' '$result' '${current_pane_id//%}' '${fingers_pane_id//%}'"
  #else
  copy_result "$result"
  revert_to_original_pane $current_pane_id $fingers_pane_id
  #fi

  exit 0
done < /dev/tty