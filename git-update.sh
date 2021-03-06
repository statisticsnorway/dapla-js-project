#!/usr/bin/env bash

function setGitMaster() {
  output=$(git -C "${1}"/ checkout master 2>&1)
  handle_response
}

function update() {
  printf 'Updating %s... ' "$1$2"
  setGitMaster "${1}"
  output=$(git -C "${1}"/ pull --rebase origin 2>&1)
  handle_response
}

function clone() {
  printf 'Cloning %s... ' "$1"
  output=$(git clone git@github.com:statisticsnorway/"${1}".git 2>&1)
  handle_response
}

function green() {
  printf '\e[32m%s\e[0m\n' "$1"
}

function yellow() {
  printf '\e[33m%s\e[0m\n' "$1"
}

function red() {
  printf '\e[31m%s\e[0m\n' "$1"
}

function handle_response() {
  if [ $? -eq 0 ]; then
    case "$output" in
    *"up-to-date"*)
      green "Already up-to-date"
      ;;
    *"Cloning"*)
      green "OK"
      ;;
    *)
      echo "$output"
      ;;
    esac
  else
    red "ERROR"
    echo "$output"
  fi
}

update "." "dapla-js-project"
printf "\n"

while read -r repo; do
  if [ -d "${repo}" ]; then
    update "${repo}"
  else
    clone "${repo}"
  fi

  if [[ $repo == cra* ]]; then
    yellow "Not installing because repo is a template"
  else
    cd "${repo}" || continue
    echo "Installing..."
    yarn install >/dev/null 2>&1 || red "Failed to install!"
    green "Finished installing"
    cd ..
  fi
  printf "\n"

done <repos.txt
