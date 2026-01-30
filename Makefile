# {{{
## Use override: 'make sync MSG="hi"' sets MSG="hi".
## If MSG is not provided on the command line, it defaults to the value below.
#MSG ?= Automated push via Makefile
#
## Define color variables for easier use
#GREEN   := \033[0;32m
#YELLOW  := \033[0;33m
#RED     := \033[0;31m
#NC      := \033[0m # No Color (resets terminal color)
#
#sync: ## Push changes to git repo (use 'make sync MSG="..."' for custom message)
#	@echo "$(YELLOW)--- Starting Git Synchronization ---$(NC)"
#	@set -e; \
#		echo "$(GREEN)Pulling remote changes...$(NC)"; \
#		git pull origin master; \
#		echo "$(GREEN)Staging all changes...$(NC)"; \
#		git add .; \
#		echo "$(GREEN)Committing changes with message: $(MSG)...$(NC)"; \
#		git commit -m "$(MSG)" || true; \
#		echo "$(GREEN)Pushing all committed changes...$(NC)"; \
#		git push origin master
#	@echo "$(YELLOW)--- Synchronization Complete ---$(NC)"
# }}}

gallery: ## Generate thumbnails and populate README
	./make_gallery.sh

sync: gallery ## Pull remote changes, then push the auto-committed gallery
	@echo "$(YELLOW)--- Starting Git Synchronization ---$(NC)"
	@set -e; \
		echo "$(GREEN)Pulling remote changes...$(NC)"; \
		git pull origin master; \
		echo "$(GREEN)Pushing all committed changes...$(NC)"; \
		git push origin master
	@echo "$(YELLOW)--- Synchronization Complete ---$(NC)"

.DEFAULT_GOAL := help
.PHONY: sync

help: ## Prints out Make help
	@echo "Usage: make <command>"
	@echo ""
	@echo "Commands:"
	@#grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST)
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'

# vim: set fdm=marker fmr={{{,}}}:

