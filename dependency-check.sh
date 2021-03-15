#!/usr/bin/env bash

stringSpacingFirst='\033[120D\033[31C'
stringSpacingSecond='\033[120D\033[47C'
stringSpacingThird='\033[120D\033[64C'
stringSpacingFourth='\033[120D\033[89C'

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
COLOR_END='\e[0m'

function showDetailedDependencyOutput() {
  color=$GREEN

  case $updateType in
  major)
    color=$RED
    ;;

  minor | patch)
    color=$YELLOW
    ;;
  esac

  stringStart="$repo: $stringSpacingFirst Current: $current $stringSpacingSecond Latest: $latest $stringSpacingThird Type of update: "
  coloredVersion="$color$updateType$COLOR_END"
  stringEnd="$stringSpacingFourth Dependency: $dependency"

  printf '%b%b%b\n' "$stringStart" "$coloredVersion" "$stringEnd"
}

function showBasicDependencyOutput() {
  printf '%s: %b %s Major %b%s Minor %b%s Patches\n' "$repo" "$stringSpacingFirst" "$currentRepoMajorUpdates" "$stringSpacingSecond" "$currentRepoMinorUpdates" "$stringSpacingThird" "$currentRepoPatchUpdates"
}

function showCraTemplateOutput() {
  printf '%s: %b%b Nothing to check, this is a cra-template%b\n' "$repo" "$stringSpacingFirst" "$YELLOW" "$COLOR_END"
}

failureArray=()

printf "\nChecking for outdated dependencies in all repos in repos.txt\n\n"

read -r -p "Do you want a detailed result? (y/n) " showDetailedResult </dev/tty
read -r -p "Should devDependencies also be checked? (y/n) " shouldCheckDevDeps </dev/tty

if [ "$showDetailedResult" == 'y' ]; then
  echo "Showing detailed information about the outdated dependencies"
else
  echo "Showing basic information about outdated dependencies"
fi

if [ "$shouldCheckDevDeps" == 'y' ]; then
  echo "Checking devDependencies also"
else
  echo "Skipping devDependencies"
fi

while read -r repo; do
  if [ -d "${repo}" ]; then
    if [[ $repo == cra* ]]; then
      showCraTemplateOutput "$repo"
    else
      cd "${repo}" || continue

      currentRepoMajorUpdates=0
      currentRepoMinorUpdates=0
      currentRepoPatchUpdates=0
      outdatedDependencies=$(yarn outdated --json)

      if [ "$outdatedDependencies" != '' ]; then
        dependencies=$(yarn outdated --json | jq -s . | jq -c '.[1].data.body' | jq -c '.[]')

        for i in $dependencies; do
          updateType=''

          dependency=$(jq '.[0]' <<<"$i" | sed -e 's/^"//' -e 's/"$//')
          current=$(jq '.[1]' <<<"$i" | sed -e 's/^"//' -e 's/"$//')
          latest=$(jq '.[3]' <<<"$i" | sed -e 's/^"//' -e 's/"$//')
          depType=$(jq '.[4]' <<<"$i" | sed -e 's/^"//' -e 's/"$//')

          currentVersionString=("${current//./ }")
          latestVersionString=("${latest//./ }")
          currentVersionArray=($currentVersionString)
          latestVersionArray=($latestVersionString)

          currentMajor=${currentVersionArray[0]}
          currentMinor=${currentVersionArray[1]}
          currentPatch=${currentVersionArray[2]}
          latestMajor=${latestVersionArray[0]}
          latestMinor=${latestVersionArray[1]}
          latestPatch=${latestVersionArray[2]}

          if [ "$currentMajor" == "$latestMajor" ]; then
            if [ "$currentMinor" == "$latestMinor" ]; then
              if [ "$currentPatch" != "$latestPatch" ]; then
                if [ "$depType" == 'dependencies' ] || [[ $depType == 'devDependencies' && $shouldCheckDevDeps == 'y' ]]; then
                  ((currentRepoPatchUpdates += 1))

                  if [ "$showDetailedResult" == 'y' ]; then
                    updateType='patch'

                    showDetailedDependencyOutput "$repo" "$current" "$latest" "$updateType" "$dependency"
                  fi
                fi
              fi
            else
              if [ "$depType" == 'dependencies' ] || [[ $depType == 'devDependencies' && $shouldCheckDevDeps == 'y' ]]; then
                ((currentRepoMinorUpdates += 1))

                if [ "$showDetailedResult" == 'y' ]; then
                  updateType='minor'

                  showDetailedDependencyOutput "$repo" "$current" "$latest" "$updateType" "$dependency"
                fi
              fi
            fi
          else
            if [ "$depType" == 'dependencies' ] || [[ $depType == 'devDependencies' && $shouldCheckDevDeps == 'y' ]]; then
              ((currentRepoMajorUpdates += 1))

              if [ "$showDetailedResult" == 'y' ]; then
                updateType='major'

                showDetailedDependencyOutput "$repo" "$current" "$latest" "$updateType" "$dependency"
              fi
            fi
          fi
        done
      else
        printf '%b%s dependencies are up-to-date.%b\n' "$GREEN" "$repo" "$COLOR_END"
      fi
      if [ "$showDetailedResult" == 'n' ]; then
        showBasicDependencyOutput "$repo" "$currentRepoMajorUpdates" "$currentRepoMinorUpdates" "$currentRepoPatchUpdates"
      fi
      cd ..
    fi
  else
    failureArray=("Could not find ${repo} folder.")
  fi
done <repos.txt

if [ ${#failureArray[@]} != 0 ]; then
  printf '\n%bList of failures when checking dependencies:%b\n' "$RED" "$COLOR_END"

  for i in "${failureArray[@]}"; do
    printf '%b%s%b\n' "$RED" "$i" "$COLOR_END"
  done

  printf "\n"
fi
