# =============================================================================
# GIT REPOSITORY SYNC MAKEFILE
# =============================================================================
#
# DESCRIPTION:
#   This Makefile automates syncing Git repositories between Azure DevOps and GitHub.
#   It allows you to perform each step individually or run the complete process.
#
# PREREQUISITES:
#   - Git installed and configured
#   - Access to both Azure DevOps and GitHub repositories
#   - SSH keys configured (recommended) or credentials for both services
#
# USAGE:
#   make <command>
#
# AVAILABLE COMMANDS:
#   help                  - Show this help message
#   setup-remotes         - Configure both Azure and GitHub remotes
#   verify-remotes        - Check that both remotes are properly configured
#   fetch-azure           - Fetch all branches from Azure DevOps
#   list-branches         - List all branches available for syncing
#   sync-all              - Force push all branches from Azure to GitHub
#   sync-branch           - Sync a specific branch (use: make sync-branch BRANCH=main)
#   full-sync             - Perform complete sync process (all steps)
#
# CONFIGURATION:
#   Edit the variables at the top of this Makefile to match your repositories.
# =============================================================================

# EDIT THESE VARIABLES TO MATCH YOUR REPOSITORIES
AZURE_URL ?= git@ssh.dev.azure.com:v3/alixpartners-dev/AP.Platforms.AICore/AP.Platforms.AICore.API 
GITHUB_URL ?= git@github.com:Alix-Platforms/AP.Platforms.AICore.API.git
AZURE_REMOTE ?= azure
GITHUB_REMOTE ?= github
DEFAULT_BRANCH ?= main

# Help command
.PHONY: help
help:
	@echo "Git Repository Sync - Azure DevOps to GitHub"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup-remotes    - Configure both Azure and GitHub remotes"
	@echo "  make verify-remotes   - Check that both remotes are properly configured"
	@echo "  make fetch-azure      - Fetch all branches from Azure DevOps"
	@echo "  make list-branches    - List all branches available for syncing"
	@echo "  make sync-all         - Force push all branches from Azure to GitHub"
	@echo "  make sync-branch      - Sync specific branch (use: make sync-branch BRANCH=main)"
	@echo "  make full-sync        - Perform complete sync process (all steps)"
	@echo ""
	@echo "Current configuration:"
	@echo "  Azure DevOps: $(AZURE_URL) ($(AZURE_REMOTE))"
	@echo "  GitHub:      $(GITHUB_URL) ($(GITHUB_REMOTE))"
	@echo ""
	@echo "Example usage:"
	@echo "  1. Edit AZURE_URL and GITHUB_URL variables in the Makefile"
	@echo "  2. Run 'make setup-remotes' to configure remotes"
	@echo "  3. Run 'make full-sync' to perform complete sync"

# Set up remotes
.PHONY: setup-remotes
setup-remotes:
	@echo "Setting up remotes..."
	-git remote remove $(AZURE_REMOTE) 2>/dev/null || true
	-git remote remove $(GITHUB_REMOTE) 2>/dev/null || true
	git remote add $(AZURE_REMOTE) $(AZURE_URL)
	git remote add $(GITHUB_REMOTE) $(GITHUB_URL)
	@echo "✅ Remotes configured successfully"
	@git remote -v

# Verify remotes
.PHONY: verify-remotes
verify-remotes:
	@echo "Verifying remotes..."
	@if ! git remote | grep -q "^$(AZURE_REMOTE)$$"; then \
		echo "❌ Error: Azure remote '$(AZURE_REMOTE)' is not configured"; \
		exit 1; \
	fi
	@if ! git remote | grep -q "^$(GITHUB_REMOTE)$$"; then \
		echo "❌ Error: GitHub remote '$(GITHUB_REMOTE)' is not configured"; \
		exit 1; \
	fi
	@echo "✅ Both remotes verified"
	@git remote -v

# Fetch from Azure
.PHONY: fetch-azure
fetch-azure: verify-remotes
	@echo "Fetching all branches from $(AZURE_REMOTE)..."
	git fetch $(AZURE_REMOTE) --prune
	@echo "✅ Fetched successfully"

# List branches
.PHONY: list-branches
list-branches: fetch-azure
	@echo "Available branches in $(AZURE_REMOTE):"
	@git branch -r | grep "$(AZURE_REMOTE)/" | grep -v "HEAD" | sed "s/$(AZURE_REMOTE)\///"

# Sync a specific branch
.PHONY: sync-branch
sync-branch: fetch-azure
	@if [ -z "$(BRANCH)" ]; then \
		echo "❌ Error: Branch name not specified"; \
		echo "Usage: make sync-branch BRANCH=branch-name"; \
		exit 1; \
	fi
	@echo "Syncing branch: $(BRANCH)"
	@if ! git branch -r | grep -q "$(AZURE_REMOTE)/$(BRANCH)$$"; then \
		echo "❌ Error: Branch '$(BRANCH)' does not exist in $(AZURE_REMOTE)"; \
		exit 1; \
	fi
	git push --force $(GITHUB_REMOTE) "refs/remotes/$(AZURE_REMOTE)/$(BRANCH):refs/heads/$(BRANCH)"
	@echo "✅ Branch $(BRANCH) synced to $(GITHUB_REMOTE)"

# Sync all branches
.PHONY: sync-all
sync-all: fetch-azure
	@echo "Syncing all branches from $(AZURE_REMOTE) to $(GITHUB_REMOTE)..."
	@BRANCHES=$$(git branch -r | grep "$(AZURE_REMOTE)/" | grep -v "HEAD" | sed "s/$(AZURE_REMOTE)\///"); \
	if [ -z "$$BRANCHES" ]; then \
		echo "❌ No branches found in $(AZURE_REMOTE)"; \
		exit 1; \
	fi; \
	echo "Found $$(echo "$$BRANCHES" | wc -l | xargs) branches to sync"; \
	for BRANCH in $$BRANCHES; do \
		echo "Pushing $$BRANCH to $(GITHUB_REMOTE) (force)..."; \
		git push --force $(GITHUB_REMOTE) "refs/remotes/$(AZURE_REMOTE)/$$BRANCH:refs/heads/$$BRANCH"; \
	done
	@echo "✅ All branches from $(AZURE_REMOTE) have been pushed to $(GITHUB_REMOTE)"

# Full sync process
.PHONY: full-sync
full-sync: setup-remotes fetch-azure sync-all
	@echo "✅ Full sync completed successfully"
