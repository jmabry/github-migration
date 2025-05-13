# Git Repository Sync

A powerful tool for synchronizing Git repositories between Azure DevOps and GitHub.

## Overview

This tool provides a streamlined workflow for keeping repositories in sync across different Git providers. It's particularly designed for migrating or maintaining mirrors between Azure DevOps and GitHub repositories.

## Features

- Configure remotes with a single command
- Fetch all branches from the source repository
- Sync individual branches or all branches at once
- Force push to ensure destination matches source exactly
- Clear error handling with descriptive messages
- Step-by-step process with verification at each stage

## Prerequisites

- Git installed and configured on your system
- Access to both Azure DevOps and GitHub repositories
- SSH keys configured (recommended) or credentials for both services

## Installation

1. Clone or download this repository
2. Place the `Makefile` in your Git repository folder
3. Edit the configuration variables in the Makefile to match your repositories

```makefile
# EDIT THESE VARIABLES TO MATCH YOUR REPOSITORIES
AZURE_URL ?= git@ssh.dev.azure.com:v3/organization/project/repository
GITHUB_URL ?= git@github.com:username/repository.git
AZURE_REMOTE ?= azure
GITHUB_REMOTE ?= github
DEFAULT_BRANCH ?= main
```

## Usage

### Getting Started

View all available commands:

```bash
make help
```

### Step-by-Step Process

1. **Set up remotes**:
   ```bash
   make setup-remotes
   ```

2. **Verify remotes are configured correctly**:
   ```bash
   make verify-remotes
   ```

3. **Fetch all branches from Azure DevOps**:
   ```bash
   make fetch-azure
   ```

4. **List available branches for sync**:
   ```bash
   make list-branches
   ```

5. **Sync a specific branch**:
   ```bash
   make sync-branch BRANCH=main
   ```

6. **Sync all branches**:
   ```bash
   make sync-all
   ```

### Quick Complete Sync

To perform the entire sync process in one command:

```bash
make full-sync
```

### Multiple Repository Sync

This tool includes a shell script for running sync operations across multiple repositories at once:

1. **Configure the script**:
   Edit the `run-git-sync.sh` file to set your base repository directory and list the repositories you want to process:

   ```bash
   # Base directory for repositories
   REPO_BASE_DIR="/Users/jmabry/repos"

   # Define repositories to process - names relative to REPO_BASE_DIR
   REPOSITORIES=(
     "AP.Platforms.AICore.API"
     "AP.Platforms.AICore.IAC"
     "AP.Platforms.AIGateway.IAC"
     # Add more repositories as needed
   )
   ```

2. **Run the script with a command**:
   ```bash
   ./run-git-sync.sh <command>
   ```

   Where `<command>` is any valid make command from the git-sync.mk makefile:
   - `setup-remotes`: Configure remotes for all repositories
   - `verify-remotes`: Check remote configuration for all repositories 
   - `full-sync`: Perform complete sync for all repositories
   - `help`: Show available commands

3. **Examples**:
   ```bash
   # Set up remotes for all repositories
   ./run-git-sync.sh setup-remotes
   
   # Perform a full sync across all repositories
   ./run-git-sync.sh full-sync
   
   # Show help for all repositories
   ./run-git-sync.sh help
   ```

The script provides progress information and error handling for each repository in the list.

## Important Notes

- This tool uses **force push** to ensure the destination exactly matches the source. This will overwrite any changes in the destination repository.
- Always verify you're pushing to the correct repository before running sync commands.
- If you have protected branches, you may need to temporarily disable branch protection.

## Example Use Cases

1. **Migrating from Azure DevOps to GitHub**:
   Set Azure as source and GitHub as destination to migrate all branches.

2. **Maintaining a mirror**:
   Regularly run `make sync-all` to keep your GitHub repository in sync with Azure DevOps.

3. **Feature branch development**:
   Sync specific feature branches using `make sync-branch BRANCH=feature/my-feature`.

## Troubleshooting

- **Remote not found**: Ensure URLs are correct in the Makefile
- **Permission denied**: Check your SSH keys or credentials
- **Branch not found**: Run `make list-branches` to see available branches
- **Push rejected**: Ensure destination repository allows force pushing

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.