#!/bin/bash
# filepath: /Users/jmabry/repos/github-migration/run-git-sync.sh

#==============================================================================
# REPOSITORY SYNC MANAGER
#==============================================================================
#
# This script helps run the git-sync.mk makefile across multiple repositories.
# Define the repositories in the REPOSITORIES array below.
#
# USAGE:
#   ./run-git-sync.sh [command]
#
# ARGUMENTS:
#   command - The make command to run (default: help)
#             Examples: setup-remotes, verify-remotes, full-sync, etc.
#
#==============================================================================

set -e  # Exit on error

# Path to the git-sync.mk makefile
MAKEFILE_PATH="$(dirname "$(realpath "$0")")/git-sync.mk"

# Base directory for repositories
REPO_BASE_DIR="/Users/jmabry/repos"

# Define repositories to process - names relative to REPO_BASE_DIR
# These should match the repository folder name 
REPOSITORIES=(
  "AP.Platforms.AIGateway.APIOps"
  "AP.Platforms.AIGateway.IAC"
  "roster-mapping-poc"
  # Add more repositories as needed
)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the command to run (default to help)
COMMAND=${1:-help}

# Print header
echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}    Repository Sync Manager - Multiple Repositories${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo -e "Using makefile: ${GREEN}${MAKEFILE_PATH}${NC}"
echo -e "Repository base directory: ${GREEN}${REPO_BASE_DIR}${NC}"
echo -e "Operation to perform: ${GREEN}${COMMAND}${NC}"
echo -e "Number of repositories: ${GREEN}${#REPOSITORIES[@]}${NC}"
echo

# Check if makefile exists
if [ ! -f "$MAKEFILE_PATH" ]; then
  echo -e "${RED}Error: Makefile not found at ${MAKEFILE_PATH}${NC}"
  exit 1
fi

# Process each repository
for repo_name in "${REPOSITORIES[@]}"; do
  # Construct full repository path
  repo="${REPO_BASE_DIR}/${repo_name}"
  
  echo -e "${YELLOW}----------------------------------------------------${NC}"
  echo -e "${YELLOW}Processing repository: ${GREEN}${repo}${NC}"
  echo -e "${YELLOW}----------------------------------------------------${NC}"
  echo -e "Repository name: ${GREEN}${repo_name}${NC}"
  
  # Check if directory exists
  if [ ! -d "$repo" ]; then
    echo -e "${RED}Error: Repository directory not found: ${repo}${NC}"
    echo
    continue
  fi
  
  # Change to repository directory
  echo "Changing to directory: $repo"
  cd "$repo"
  
  # Run the makefile command with the repository name
  echo -e "Running: ${GREEN}make -f ${MAKEFILE_PATH} ${COMMAND} REPO_NAME=${repo_name}${NC}"
  echo
  
  if make -f "$MAKEFILE_PATH" "$COMMAND" REPO_NAME="${repo_name}"; then
    echo -e "${GREEN}Successfully completed ${COMMAND} for ${repo}${NC}"
  else
    echo -e "${RED}Failed to run ${COMMAND} for ${repo}${NC}"
  fi
  
  echo
done

echo -e "${YELLOW}=====================================================${NC}"
echo -e "${GREEN}All repositories processed${NC}"
echo -e "${YELLOW}=====================================================${NC}"