#!/usr/bin/env bash

stringSpacingRepo='32'
stringSpacingSemVerCurrent='8'
stringSpacingSemVerLatest='11'
stringSpacingSemVerTotal=$((stringSpacingSemVerCurrent + 4 + stringSpacingSemVerLatest)) #Number is the size of the arrow with spaces in the output
stringSpacingType='10'
stringSpacingBasicMajor='9'
stringSpacingBasicMinor='9'

RED=$(printf '\e[31m')
GREEN=$(printf '\e[32m')
YELLOW=$(printf '\e[33m')
CYAN=$(printf '\e[36m')
COLOR_END=$(printf '\e[0m')

shownDetailedHeader=false

function showDetailedDependencyHeader() {
  printf '%-*s' "$stringSpacingRepo" "Repository"
  printf '%-*s' "$stringSpacingSemVerTotal" "Version"
  printf '%-*s' "$stringSpacingType" "Type"
  printf '%s\n' "Dependency"
}

function showDetailedDependencyOutput() {
  color=$GREEN

  case $updateType in
  major)
    color=$RED
    ;;

  minor)
    color=$YELLOW
    ;;

  patch)
    color=$CYAN
    ;;
  esac

  # Fix for printf counting the escaped characters in the color codes
  colorLength=${#color}
  colorEndLength=${#COLOR_END}
  coloredUpdateTypeTotalLength=$((colorLength + colorEndLength + stringSpacingType))

  coloredUpdateType="$color$updateType$COLOR_END"

  printf '%-*s' "$stringSpacingRepo" "$repo"
  printf '%-*s -> %-*s' "$stringSpacingSemVerCurrent" "$current" "$stringSpacingSemVerLatest" "$latest"
  printf '%-*s' "$coloredUpdateTypeTotalLength" "$coloredUpdateType"
  printf '%s\n' "$dependency"
}

function showBasicDependencyOutput() {
  majorString=$currentRepoMajorUpdates' Major'
  minorString=$currentRepoMinorUpdates' Minor'
  patchString=$currentRepoPatchUpdates' Patches'

  printf '%-*s' "$stringSpacingRepo" "$repo"
  printf '%-*s' "$stringSpacingBasicMajor" "$majorString"
  printf '%-*s' "$stringSpacingBasicMinor" "$minorString"
  printf '%s\n' "$patchString"
}

function showNoOutdatedDependenciesOutput() {
  printf '%-*s%sDependencies are up-to-date.%s\n' "$stringSpacingRepo" "$repo" "$GREEN" "$COLOR_END"
}

function showCraTemplateOutput() {
  printf '%-*s%bNothing to check, this is a cra-template%s\n' "$stringSpacingRepo" "$repo" "$YELLOW" "$COLOR_END"
}

failureArray=()

printf "\nChecking for outdated dependencies in all repositories in repos.txt\n\n"

read -r -p "Do you want a detailed result? (y/n) " showDetailedResult </dev/tty
read -r -p "Should devDependencies also be checked? (y/n) " shouldCheckDevDeps </dev/tty

if [ "$showDetailedResult" == 'y' ]; then
  echo "Showing detailed information about outdated dependencies"
else
  echo "Showing basic information about outdated dependencies"
fi

if [ "$shouldCheckDevDeps" == 'y' ]; then
  printf 'Checking devDependencies\n\n'
else
  printf 'Skipping devDependencies\n\n'
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

        if [ "$showDetailedResult" == 'y' ] && [ "$shownDetailedHeader" == false ]; then
          showDetailedDependencyHeader
          shownDetailedHeader=true
        fi

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
        showNoOutdatedDependenciesOutput "$repo"
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
