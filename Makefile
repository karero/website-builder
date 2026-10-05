.PHONY: install install-codex package check test smoke whats-new refresh

install:   ## symlink every skill into ~/.claude/skills/ (Claude Code)
	@bash scripts/install.sh

install-codex:   ## symlink every skill into ~/.agents/skills/ (OpenAI Codex)
	@bash scripts/install-codex.sh

whats-new: ## skill changes since a project was scaffolded: make whats-new PROJECT=<dir> (no PROJECT = recent suite changes)
	@bash scripts/whats-new.sh $(if $(PROJECT),"$(PROJECT)")

refresh:   ## re-copy a project's stale bundled skills + re-stamp (overwrites local edits): make refresh PROJECT=<dir>
	@bash scripts/whats-new.sh --refresh $(if $(PROJECT),"$(PROJECT)")

package: check   ## build dist/website-builder.zip for handoff (runs check first)
	@bash scripts/package.sh

check:     ## run every suite guard: no personal data or credentials, every script locating itself CDPATH-safely, no pipe into an early-exit consumer (head, grep -q, …) under pipefail, no concrete model in independent-review, every astro template file bucketed, skill descriptions within budget, no failed reviewer hidden, independent-review's validator, prompt-sync and claims-sweep self-checks green, no installer clobbering a pinned skill, the handoff zip's leak check catching a large leak, the site pre-push hook gating and blocking the right pushes and being wired only at a repo's root by a line that holds no shell syntax, the site's verify script reinstalling only on a changed package.json or lockfile and stopping at the first red step, the private-name check running in a worktree too (each script's header says what it checks; the installer and hook tests need git, the hook test's wiring cases node and npm too, the verify test node, the claims-sweep test git and python3)
	@bash scripts/check_clean.sh
	@bash scripts/check_cdpath_safe.sh
	@bash scripts/check_pipefail_pipes.sh
	@bash scripts/check_model_agnostic.sh
	@bash scripts/check_template_coverage.sh
	@bash scripts/check_skill_budgets.sh
	@bash skills/independent-review/scripts/test_failed_tier_report.sh
	@bash skills/independent-review/scripts/test_looks_like_review.sh
	@bash skills/independent-review/scripts/check_prompt_sync.sh
	@bash skills/independent-review/scripts/test_sweep_claims.sh
	@bash scripts/test_install_pin.sh
	@bash scripts/test_package_leak.sh
	@bash scripts/test_pre_push_hook.sh
	@bash scripts/test_verify.sh
	@bash scripts/test_clean_denylist.sh

PYTHON ?= python3
test:      ## run the search-console-insights tests (tracker + AI check; needs `requests`; stub servers, no real API calls). Not part of check/package, which must run on a stock python3
	@$(PYTHON) -m unittest discover -s skills/search-console-insights/scripts/tests

smoke: package   ## shippability check: make check + build zip + verify zip contents
	@echo "smoke OK — suite is clean and the handoff zip is complete"
