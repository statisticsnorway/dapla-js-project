#!/usr/bin/env bash

failureArray=()
linksToPRArray=()
libArray=()
repoChoice=()
mainBranchInRepos='master'

function green() {
  printf '\e[32m%s\e[0m\n' "$1"
}

function red() {
  printf '\e[31m%s\e[0m\n' "$1"
}

function buildRepoArrayWithExceptions() {
  while read -r repo; do
    if [[ $repo != cra* ]] && [[ $repo != dapla-js-utilities ]] && [[ $repo != dapla-workbench ]]; then
      repoChoice+=("$repo")
    fi
  done <repos.txt
}

PS3='Which repos do you want to upgrade? '
options=("dapla-js-utilities" "All (except js-utilities and workbench)" "dapla-workbench")
select opt in "${options[@]}"; do
  case $opt in
  "dapla-js-utilities")
    printf "Updating %s\n\n" "$opt"
    repoChoice+=("dapla-js-utilities")
    ;;
  "All (except js-utilities and workbench)")
    printf "Updating %s\n\n" "$opt"
    buildRepoArrayWithExceptions
    ;;
  "dapla-workbench")
    printf "Updating %s\n\n" "$opt"
    repoChoice+=("dapla-workbench")
    ;;
  *) echo "Invalid option $REPLY" && exit ;;
  esac
  break
done

read -r -p "Do you want to skip major versions (y/n)? " skipMajor </dev/tty
printf "Please do not use git-stash while the script is running\n\n"

for repo in "${repoChoice[@]}"; do
  cd "${repo}" || continue

  echo "Updating dependencies in $repo"

  branchName=dependencies-auto-update-$(date +%F)

  git ls-remote --exit-code --heads origin "${branchName}" &>/dev/null 2>&1
  branchCheckErrorCode=$?

  printf "Checking for recent autocreated branch in remote repository... "

  if [ "$branchCheckErrorCode" == 2 ]; then #2 means branch not found
    green "OK"

    originalBranch=$(git branch --show-current)

    hasUncommittedChanges=false
    hasUncommittedChangesOutput=$(git status --porcelain) #check for uncommitted changes, but not ignored files

    if [ "$hasUncommittedChangesOutput" != '' ]; then
      printf 'Stashing uncommitted changes on branch %s... ' "$mainBranchInRepos"

      stashMessage="git-stash for $repo $branchName"

      git stash push --include-untracked --message "$stashMessage" >/dev/null 2>&1

      hasUncommittedChanges=true

      green "OK"
    fi

    if [ "$originalBranch" != $mainBranchInRepos ]; then
      echo "Setting branch to $mainBranchInRepos"

      git checkout $mainBranchInRepos >/dev/null 2>&1
    fi

    printf "Pulling latest changes... "

    git pull >/dev/null 2>&1

    green "OK"

    shouldUpgrade=false
    shouldAttemptPR=false
    shouldAttemptPR=true
    currentFailureArrayLength=${#failureArray[@]}
    outdatedDependencies=$(yarn outdated --json)

    if [ "$outdatedDependencies" != '' ]; then
      dependencies=$(yarn outdated --json | jq -s . | jq -c '.[1].data.body' | jq -c '.[]')

      for i in $dependencies; do
        dependency=$(jq '.[0]' <<<"$i" | sed -e 's/^"//' -e 's/"$//')
        current=$(jq '.[1]' <<<"$i" | sed -e 's/^"//' -e 's/"$//')
        latest=$(jq '.[3]' <<<"$i" | sed -e 's/^"//' -e 's/"$//')
        currentMajor=${current%%.*}
        latestMajor=${latest%%.*}

        if [[ $skipMajor == "n" ]] && [[ $currentMajor != "$latestMajor" ]]; then
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
            red "Update not wanted. Skipping $dependency"
          fi
        else
          shouldUpgrade=true
          shouldAttemptPR=true
        fi
      done
    else
      green "Nothing to update"
    fi

    if [ $shouldUpgrade == true ]; then
      echo "Attempting to run yarn upgrade"
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

        libArray+=("$repo")
      fi
    fi

    if [ "$currentFailureArrayLength" == ${#failureArray[@]} ] && [ $shouldAttemptPR == true ]; then

      yarn version --patch --no-commit-hooks --no-git-tag-version

      printf "Creating branch and PR in git... "
      git checkout -b "$branchName" >/dev/null 2>&1
      git add --all >/dev/null 2>&1
      git commit -m "Update dependencies with dapla-js-project" >/dev/null 2>&1
      git push -u origin "$branchName" >/dev/null 2>&1

      urlToPR=$(gh pr create --fill --no-maintainer-edit --reviewer mmj-ssb,SjurSutterudSagen | tail -1)
      linksToPRArray+=("$urlToPR")

      green "OK"

      git checkout "$mainBranchInRepos" >/dev/null 2>&1

      echo "Deleting autocreated branch for the update from the local machine"
      git branch -D "$branchName" >/dev/null 2>&1

      if [ "$originalBranch" != $mainBranchInRepos ]; then
        echo "Setting $repo back to $originalBranch"

        git checkout "$originalBranch" >/dev/null 2>&1
      fi

      if [ $hasUncommittedChanges == true ]; then
        printf 'Reapplying stashed changes to branch %s... ' "$mainBranchInRepos"

        git stash pop >/dev/null 2>&1

        green "OK"
      fi
    fi
  else
    failureArray+=("$repo: Autocreated branch already exists - $branchName")

    red "Failed"
  fi
  printf "\n"

  cd ..
done

if [ ${#linksToPRArray[@]} != 0 ]; then
  echo "Links to the generated Pull Requests:"

  for i in "${linksToPRArray[@]}"; do
    echo "$i"
  done
fi

if [ ${#libArray[@]} != 0 ]; then
  echo "Remember to publish these libraries on npm:"

  for i in "${libArray[@]}"; do
    red "$i"
  done

  printf "\n"
fi

if [ ${#failureArray[@]} != 0 ]; then
  echo "List of failures during dependency updating:"

  for i in "${failureArray[@]}"; do
    red "$i"
  done

  printf "\n"
fi
