#!/usr/bin/env bash

function green() {
  printf '\e[32m%s\e[0m' "$1"
}

function red() {
  printf '\e[31m%s\e[0m' "$1"
}

failureArray=()

while read -r repo; do
  if [[ $repo != cra* ]]; then
    cd "${repo}" || exit
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
            yarn add --exact "$dependency"@"$latest"
          else
            yarn add "$dependency"@^"$latest"
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
      yarn upgrade
    fi

    if [ $shouldAttemptPR == true ]; then
      echo "Attempting to run yarn coverage"
      CI=true yarn coverage || failureArray+=("$repo: yarn coverage failed.")
      echo "Attempting to run yarn build"
      CI=true yarn build || failureArray+=("$repo: yarn build failed.")

      if [ -d "lib/" ]; then
        echo "Attempting to run yarn package"
        CI=true yarn package || failureArray+=("$repo: yarn package failed.")
      fi
    fi

    if [ "$currentFailureArrayLength" == ${#failureArray[@]} ] && [ $shouldAttemptPR == true ]; then
      echo "Creating branch and PR in git"
      yarn version --patch --no-commit-hooks --no-git-tag-version
      git checkout -b dependencies-auto-update
      git add --all
      git commit -m "Update dependencies with dapla-js-project"
      git push -u origin dependencies-auto-update
      #      git request-pull origin/master dependencies-auto-update
      #      TODO Create PR on github
    else
      echo "Should NOT create PR"
    fi

    printf "\n"
    cd ..
  fi

done <repos.txt

if [ ${#failureArray[@]} != 0 ]; then
  echo "Something failed"
  for i in "${failureArray[@]}"; do
    red "$i"
  done
fi
