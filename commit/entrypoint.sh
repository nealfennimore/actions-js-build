#!/bin/sh
## This GitHub Action for git commits any changed files and pushes 
## those changes back to the origin repository.
##
## Required environment variable:
## - $GITHUB_TOKEN: The token to use for authentication with GitHub 
## to commit and push changes back to the origin repository.
##
## Optional environment variables:
## - $WD_PATH: Working directory to CD into before checking for changes
## - $PUSH_BRANCH: Remote branch to push changes to

if [ "$DEBUG" == "false" ]
then
  # Carry on, but do quit on errors
  set -e
else
  # Verbose debugging
  set -exuo pipefail
  export LOG_LEVEL=debug
fi

# If WD_PATH is defined, then cd to it
if [ ! -z "$WD_PATH" ]
then
  echo "Changing dir to $WD_PATH"
  cd $WD_PATH
fi

# Set up .netrc file with GitHub credentials
git_setup ( ) {
  cat <<- EOF > $HOME/.netrc
		machine github.com
		login $GITHUB_ACTOR
		password $GITHUB_TOKEN

		machine api.github.com
		login $GITHUB_ACTOR
		password $GITHUB_TOKEN
EOF
  chmod 600 $HOME/.netrc

  # Git requires our "name" and email address -- use GitHub handle
  git config user.email "$GITHUB_ACTOR@users.noreply.github.com"
  git config user.name "$GITHUB_ACTOR"
  
  # Push to the current branch if PUSH_BRANCH hasn't been overriden
  : ${PUSH_BRANCH:=`echo "$GITHUB_REF" | awk -F / '{ print $3 }' `}
}

# This section only runs if there have been file changes
echo "Checking for uncommitted changes in the git working tree."
if ! git diff --quiet || test $( git ls-files -o --exclude-standard | wc -l ) -gt 0
then 
  git_setup
  git checkout $PUSH_BRANCH
  git add .
  git commit -m "Regenerate build artifacts."
  git push --set-upstream origin $PUSH_BRANCH
else 
  echo "Working tree clean. Nothing to commit."
fi
