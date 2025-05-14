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
#   sync-all              - Push all branches from Azure to GitHub
#   sync-branch           - Sync a specific branch (use: make sync-branch BRANCH=main)
#   verify-commits        - Verify last commit matches between Azure and GitHub
#   full-sync             - Perform complete sync process (all steps)
#   set-origin-to-github  - Change the origin remote to point to GitHub
#
# CONFIGURATION:
#   Edit the variables at the top of this Makefile to match your repositories.
# =============================================================================

# Base URLs and paths - will be combined with REPO_NAME to form full URLs
AZURE_BASE_URL ?= git@ssh.dev.azure.com:v3/alixpartners-dev/AP.Platforms.AICore
GITHUB_BASE_URL ?= git@github.com:Alix-Platforms

# Repository name - to be provided when running make
REPO_NAME ?= 

# Build full URLs from base URLs and repository name
AZURE_URL := $(if $(REPO_NAME),$(AZURE_BASE_URL)/$(REPO_NAME),$(AZURE_BASE_URL)/$(notdir $(CURDIR)))
GITHUB_URL := $(if $(REPO_NAME),$(GITHUB_BASE_URL)/$(REPO_NAME).git,$(GITHUB_BASE_URL)/$(notdir $(CURDIR)).git)

# Remote names
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
	@echo "  make sync-all         - Push all branches from Azure to GitHub"
	@echo "  make sync-branch      - Sync specific branch (use: make sync-branch BRANCH=main)"
	@echo "  make verify-commits   - Verify last commit matches between Azure and GitHub"
	@echo "  make full-sync        - Perform complete sync process (all steps)"
	@echo "  make set-origin-to-github - Change the origin remote to point to GitHub"
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
	git push $(GITHUB_REMOTE) "refs/remotes/$(AZURE_REMOTE)/$(BRANCH):refs/heads/$(BRANCH)"
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
		echo "Pushing $$BRANCH to $(GITHUB_REMOTE)..."; \
		git push $(GITHUB_REMOTE) "refs/remotes/$(AZURE_REMOTE)/$$BRANCH:refs/heads/$$BRANCH"; \
	done
	@echo "✅ All branches from $(AZURE_REMOTE) have been pushed to $(GITHUB_REMOTE)"

# Verify commits match between remotes
.PHONY: verify-commits
verify-commits: verify-remotes
	@echo "Fetching latest from both remotes..."
	git fetch $(AZURE_REMOTE) --prune
	git fetch $(GITHUB_REMOTE) --prune
	@echo "Checking commit synchronization between remotes..."
	@BRANCHES=$$(git branch -r | grep "$(AZURE_REMOTE)/" | grep -v "HEAD" | sed "s/$(AZURE_REMOTE)\///"); \
	MISMATCH=0; \
	MATCH=0; \
	for BRANCH in $$BRANCHES; do \
		if git branch -r | grep -q "$(GITHUB_REMOTE)/$$BRANCH"; then \
			AZURE_COMMIT=$$(git rev-parse $(AZURE_REMOTE)/$$BRANCH); \
			GITHUB_COMMIT=$$(git rev-parse $(GITHUB_REMOTE)/$$BRANCH); \
			if [ "$$AZURE_COMMIT" = "$$GITHUB_COMMIT" ]; then \
				echo "✅ Branch $$BRANCH: Commits match ($$AZURE_COMMIT)"; \
				MATCH=$$((MATCH+1)); \
			else \
				echo "❌ Branch $$BRANCH: Commits differ"; \
				echo "   Azure:  $$AZURE_COMMIT"; \
				echo "   GitHub: $$GITHUB_COMMIT"; \
				MISMATCH=$$((MISMATCH+1)); \
			fi; \
		else \
			echo "⚠️ Branch $$BRANCH: Not found in GitHub"; \
			MISMATCH=$$((MISMATCH+1)); \
		fi; \
	done; \
	echo "Summary: $$MATCH branches in sync, $$MISMATCH branches out of sync or missing"; \
	if [ $$MISMATCH -gt 0 ]; then exit 1; fi

# Full sync process
.PHONY: full-sync
full-sync: setup-remotes fetch-azure sync-all verify-commits
	@echo "✅ Full sync completed successfully"

# Set origin remote to GitHub
.PHONY: set-origin-to-github
set-origin-to-github: verify-remotes
	@echo "Changing origin remote to point to GitHub..."
	@if git remote | grep -q "^origin$$"; then \
		echo "Updating existing origin remote..."; \
		git remote set-url origin $(GITHUB_URL); \
	else \
		echo "Creating new origin remote..."; \
		git remote add origin $(GITHUB_URL); \
	fi
	@echo "✅ Origin remote now points to GitHub"
	@git remote -v | grep origin
