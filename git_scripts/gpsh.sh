#!/bin/bash

function gpsh {
	if is_a_git_repo; then
		current_branch=$(git branch | awk '/\*/ {print $2}')

		if has_remote; then
			repo_url=$(git config --get remote.origin.url)
			repo_name="$(echo "$repo_url" | awk -F '/' '{print $NF}' | sed 's/.git$//')"
		else
			repo_name=$(basename "$(git rev-parse --show-toplevel)")
		fi

		# check if it has a remote to push
		if has_remote; then
			git push origin $current_branch
		else
			echo "${BOLD} The repo ${LIGHT_BLUE}$repo_name ${WHITE}has ${RED}no remote"
		fi
	else
		echo "${BOLD} ■■▶ This won't work, you are not in a git repo !"
	fi
}

# Resolve the full path to the script's directory
REAL_PATH="$(dirname "$(readlink -f "$0")")"
PARENT_DIR="$(dirname "$REAL_PATH")"
CATEGORY="git_scripts"

HELPS_DIR="$PARENT_DIR/helps/$CATEGORY"
HELP_FILE="$(basename "$0" .sh)_help.sh"

UTILS_DIR="$PARENT_DIR/utils"

# Import necessary variables and functions
source "$UTILS_DIR/check_connection.sh"
source "$UTILS_DIR/check_remote.sh"
source "$UTILS_DIR/check_git.sh"
source "$UTILS_DIR/setup_git.sh"
source "$UTILS_DIR/check_sudo.sh"
source "$UTILS_DIR/colors.sh"
source "$UTILS_DIR/usage.sh"

# Import help file
source "$HELPS_DIR/$HELP_FILE"

# prompt for sudo
# password if required
allow_sudo

# Setting up git
setup_git

# Usage function to display help
function usage {
  show_help "Usage" "${gpsh_arguments[@]}"
	show_help "Description" "${gpsh_descriptions[@]}"
	show_help "Options" "${gpsh_options[@]}"
	show_help "${gpsh_extras[@]}"
  exit 0
}

# Check if --help is the first argument
[ "$1" = "--help" ] && usage

# Check for internet connectivity to GitHub
check_connection

# Call gpsh function
gpsh