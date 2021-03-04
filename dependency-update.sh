#!/usr/bin/env bash

function green() {
  printf '\e[32m%s\e[0m\n' "$1"
}

function red() {
  printf '\e[31m%s\e[0m\n' "$1"
}

# TODO: run git-update.sh before deps update

failureArray=()
linksToPRArray=()

while read -r repo; do
  if [[ $repo != cra* ]] && [[ $repo != dapla-js-utilities ]] && [[ $repo != dapla-workbench ]]; then
    cd "${repo}" || continue
    echo "Updating $repo..."

    shouldUpgrade=false
    shouldAttemptPR=false
    currentFailureArrayLength=${#failureArray[@]}
    dependencies=$(yarn outdated --json | jq -s . | jq -c '.[1].data.body' | jq -c '.[]')

    for i in $dependencies; do
      dependency=$(jq '.[0]' <<<"$i" | sed -e 's/^"//' -e 's/"$//')
      current=$(jq '.[1]' <<<"$i" | sed -e 's/^"//' -e 's/"$//')
      latest=$(jq '.[3]' <<<"$i" | sed -e 's/^"//' -e 's/"$//')
      currentMajor=${current%%.*}
      latestMajor=${latest%%.*}

      if [[ $currentMajor != "$latestMajor" ]]; then
        red "Major version update required for $dependency"
        read -r -p "Do you wish to upgrade to latest version (y/n)? " answer </dev/tty

        if [[ $answer == "y" ]]; then
          if [[ $dependency == react-scripts ]]; then
            yarn add --exact "$dependency"@"$latest" >/dev/null 2>&1
          else
            yarn add "$dependency"@^"$latest" >/dev/null 2>&1
          fi
          shouldAttemptPR=true
        else
          red "Not updating $dependency"
        fi
      else
        shouldUpgrade=true
        shouldAttemptPR=true
      fi
    done

    if [ $shouldUpgrade == true ]; then
      yarn upgrade >/dev/null 2>&1
    fi

    if [ $shouldAttemptPR == true ]; then
      echo "Attempting to run yarn coverage"
      CI=true yarn coverage >/dev/null 2>&1 || failureArray+=("$repo: yarn coverage failed.")
      echo "Attempting to run yarn build"
      CI=true yarn build >/dev/null 2>&1 || failureArray+=("$repo: yarn build failed.")

      if [ -d "lib/" ]; then
        echo "Attempting to run yarn package"
        CI=true yarn package >/dev/null 2>&1 || failureArray+=("$repo: yarn package failed.")
      fi
    fi

    if [ "$currentFailureArrayLength" == ${#failureArray[@]} ] && [ $shouldAttemptPR == true ]; then
      yarn version --patch --no-commit-hooks --no-git-tag-version

      branchName=dependencies-auto-update-$(date +%F)

      printf "Creating branch and PR in git... "
      git checkout -b "$branchName" >/dev/null 2>&1
      git add --all >/dev/null 2>&1
      git commit -m "Update dependencies with dapla-js-project" >/dev/null 2>&1
      git push -u origin "$branchName" >/dev/null 2>&1

      urlToPR=$(gh pr create --fill --no-maintainer-edit --reviewer mmj-ssb,SjurSutterudSagen | tail -1)
      linksToPRArray+=("$urlToPR")
      green "OK"
    fi

    printf "\n"
    cd ..
  fi

done <repos.txt

if [ ${#failureArray[@]} != 0 ]; then
  echo "List of failures during dependency updating:"
  for i in "${failureArray[@]}"; do
    red "$i"
  done
  printf "\n"
fi

if [ ${#linksToPRArray[@]} != 0 ]; then
  echo "Links to the generated Pull Requests:"
  for i in "${linksToPRArray[@]}"; do
    echo "$i"
  done
fi
