#!/bin/sh

# Define colors
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
LIGHT_BLUE="\e[94m"
WHITE="\e[97m"
RESET="\e[0m"

# Function to display usage
usage() {
  echo "${BOLD}Usage:${RESET}"
  echo "  $(basename "$0" .sh) [collaborator_username...]"
  echo
  echo "${BOLD}Description:${RESET}"
  echo "  This script interacts with a GitHub repository" 
  echo "  associated with the current local Git repository."
  echo
  echo "  It allows you to remove collaborators from the repository."
  echo
  echo "${BOLD}Options:${RESET}"
  echo "  [collaborator_username]  GitHub username(s) of the collaborators to remove."
  echo "                           Multiple usernames can be provided, separated by spaces."
  echo
  echo "  --help                   Display this help message."
  echo
  echo "  If no usernames are provided, the script will"
  echo "  prompt you to specify at least one."
  exit 0
}

# Check if GitHub CLI is installed
if ! gh --version >/dev/null 2>&1; then
  echo "gh is not installed."
  exit 1
fi

# Check if --help is the first argument
[ "$1" = "--help" ] && usage

# Check if it is a git repo
is_a_git_repo=$(git rev-parse --is-inside-work-tree 2>/dev/null)

# Check if it has a remote
has_remote=$(git remote -v)

# check if the collaborator is a GitHub user
is_a_github_user() {
  username="$1"

  # Check if username is empty
  if [ -z "$username" ]; then
    return 1
  fi

  # Build the API URL
  url="https://api.github.com/users/$username"

  # Use wget to capture the response (redirecting output to a variable)
  # wget by default outputs content, so we use the -q (quiet) option to suppress it
  # -O- option specifies that the downloaded content should be written
  # to standard output (stdout) instead of a file.
  response=$(wget -qO- --no-check-certificate "$url")

  # Check if there is no output
  # meaning it is not found
  if [ -z "$response" ]; then
    # Not Found
    return 1
  else
    # Found
    return 0
  fi
}

# ghadel functions
if [ "$is_a_git_repo" = "true" ]; then
  if [ "$has_remote" ]; then
    if [ $# -eq 0 ]; then
      echo "${BOLD} ■■▶ Specify the username of the collaborator to remove !";
    elif [ $# -gt 0 ]; then
      current_user=$(awk '/user:/ {print $2; exit}' ~/.config/gh/hosts.yml)
      repo_url=$(git config --get remote.origin.url)
      repo_owner=$(echo "$repo_url" | awk -F '[/:]' '{print $(NF-1)}')
      repo_name="$(echo "$repo_url" | awk -F '/' '{print $NF}' | sed 's/.git$//')"

      # check if we are not the owner of the repo
      if [ "$repo_owner" != "$current_user" ]; then
        echo "${BOLD} ■■▶ Sorry, you are not the owner of this repo !";
      else
        # Retrieve the list of collaborators
        collaborators=$(gh api "repos/$current_user/$repo_name/collaborators" --jq '.[].login')
        invitations=$(gh api "repos/$current_user/$repo_name/invitations" --jq '.[].invitee.login')

        # Loop through each collaborator username provided as an argument
        for collaborator in "$@"; do
          # Check if the collaborator exists in the list of collaborators
          if echo "$collaborators" | grep -q "$collaborator" ||
            echo "$invitations" | grep -q "$collaborator"; then
            printf "${BOLD} Removing ${LIGHT_BLUE}$collaborator ${WHITE}from ${LIGHT_BLUE}$repo_name${WHITE} "
            # Check for pending invitations
            invitation_id=$(gh api "repos/$current_user/$repo_name/invitations" --jq ".[] | select(.invitee.login==\"$collaborator\") | .id")

            if [ -n "$invitation_id" ]; then
              # Delete the pending invitation
              gh api --method=DELETE "repos/$current_user/$repo_name/invitations/$invitation_id" >/dev/null 2>&1
              printf " ${BOLD}(invitation deleted) "
            fi

            # Remove collaborator using gh api
            gh api --method=DELETE "repos/$current_user/$repo_name/collaborators/$collaborator" >/dev/null 2>&1
            echo "${BOLD}${GREEN} ${WHITE}"
          else
            echo "${BOLD}${LIGHT_BLUE}$collaborator ${WHITE}is not a ${LIGHT_BLUE}collaborator ${RED}✘ ${WHITE}"
          fi
        done
      fi
    fi
  else
    echo "${BOLD} ■■▶ This repo has no remote on Github !";
  fi
else
  echo "${BOLD} ■■▶ This won't work, you are not in a git repo !";
fi