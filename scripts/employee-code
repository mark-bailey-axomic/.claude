#!/bin/bash
# Get employee code from GitHub username (e.g. John Doe → jdo)

set -e

name=$(gh api user --jq '.name')

if [[ -z "$name" ]]; then
  echo "Error: Could not get GitHub user name" >&2
  exit 1
fi

# Parse: first letter of first name + first 2 letters of surname (lowercase)
first=$(echo "$name" | awk '{print tolower(substr($1,1,1))}')
last=$(echo "$name" | awk '{print tolower(substr($NF,1,2))}')

echo "${first}${last}"
