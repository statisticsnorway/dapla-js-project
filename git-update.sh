#!/usr/bin/env bash

function update() {
  printf "Updating $1$2... "
  output=$(git -C ${1}/ pull --rebase 2>&1)
  handle_response
}

function clone() {
  printf "Cloning $1... "
  output=$(git clone git@github.com:statisticsnorway/${1}.git 2>&1)
  handle_response
}

function green() {
  printf '\e[32m%s\e[0m' "$1"
}

function yellow() {
  printf '\e[33m%s\e[0m' "$1"
}

function red() {
  printf '\e[31m%s\e[0m' "$1"
}

function handle_response() {
  if [ $? -eq 0 ]; then
    case "$output" in
    *"up-to-date"*)
      echo $(green "Already up-to-date")
      ;;
    *"Cloning"*)
      echo $(green "OK")
      ;;
    *)
      echo $(green "OK")
      echo "$output"
      ;;
    esac
  else
    echo $(red "ERROR")
    echo "$output"
  fi
}

update "." "dapla-js-project"
while read -r repo; do
  if [ -d ${repo} ]; then
    update ${repo}
  else
    clone ${repo}
  fi

  if [[ $repo == cra* ]]; then
    echo $(yellow "Not installing because repo is a template")
  else
    cd ${repo}
    echo "Installing..."
    yarn install --silent
    echo $(green "Finished installing")
    cd ..
  fi
  printf "\n"

done <repos.txt
