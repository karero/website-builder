.PHONY: install install-codex package check test smoke whats-new refresh push-denylist

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

check:     ## run every suite guard: no personal data or credentials, every script locating itself CDPATH-safely, no pipe into an early-exit consumer (head, grep -q, …) under pipefail, no concrete model in independent-review, every astro template file bucketed, skill descriptions within budget, no failed reviewer hidden, independent-review's validator, prompt-sync and claims-sweep self-checks green, its Perl programs within the Perl they declare (needs Perl::MinimumVersion; skipped without it), no installer clobbering a pinned skill, the handoff zip's leak check catching a large leak, the site pre-push hook gating and blocking the right pushes and being wired only at a repo's root by a line that holds no shell syntax, the site's verify script reinstalling only on a changed package.json or lockfile and stopping at the first red step, the private-name check running in a worktree too and CI's masked mode printing no scanned text, the site's Claude Code sync hook reporting news, failures and retries correctly, every text file checking out LF even where Git converts to CRLF (each script's header says what it checks; the installer and hook tests need git, the hook test's wiring cases node and npm too, the verify test node, the claims-sweep test git and python3, the sync-hook test git and node)
	@bash scripts/check_clean.sh
	@bash scripts/check_cdpath_safe.sh
	@bash scripts/check_pipefail_pipes.sh
	@bash scripts/check_model_agnostic.sh
	@bash scripts/check_template_coverage.sh
	@bash scripts/check_skill_budgets.sh
	@bash skills/independent-review/scripts/test_failed_tier_report.sh
	@bash skills/independent-review/scripts/test_looks_like_review.sh
	@bash skills/independent-review/scripts/check_prompt_sync.sh
	@bash skills/independent-review/scripts/check_perl_minimum.sh
	@bash skills/independent-review/scripts/test_sweep_claims.sh
	@bash scripts/test_install_pin.sh
	@bash scripts/test_package_leak.sh
	@bash scripts/test_pre_push_hook.sh
	@bash scripts/test_verify.sh
	@bash scripts/test_clean_denylist.sh
	@bash scripts/test_git_stand_hook.sh
	@bash scripts/check_lf_checkout.sh

PYTHON ?= python3
test:      ## run the search-console-insights tests (tracker + AI check; needs `requests`; stub servers, no real API calls). Not part of check/package, which must run on a stock python3
	@$(PYTHON) -m unittest discover -s skills/search-console-insights/scripts/tests

# A linked worktree has no copy of the gitignored list; use the main checkout's, as check_clean.sh does.
# It refuses a list with no names (CI would fail on it). It sends the list base64-encoded on one
# line, after a marker line the CI step requires; .github/workflows/clean.yml says why.
push-denylist:   ## maintainer only: copy the private-name list (scripts/.clean-denylist, gitignored) into the repo's CLEAN_DENYLIST Actions secret, so CI checks names too. Run it after every change to the list; needs gh
	@f=scripts/.clean-denylist; [ -f "$$f" ] || f="$$(git worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')/scripts/.clean-denylist"; \
	[ -f "$$f" ] || { echo "no scripts/.clean-denylist here or in the main checkout"; exit 1; }; \
	[ -n "$$(tr -d '\r' <"$$f" | grep -vE '^[[:space:]]*(#|$$)')" ] || { echo "$$f lists no names: nothing to send"; exit 1; }; \
	repo="$$(gh repo view --json nameWithOwner -q .nameWithOwner)" && [ -n "$$repo" ] || { echo "gh cannot tell which GitHub repo this is"; exit 1; }; \
	b64="$$({ printf '# CLEAN_DENYLIST v1\n'; tr -d '\r' <"$$f"; } | base64)" || { echo "base64 failed on $$f"; exit 1; }; \
	printf '%s' "$$b64" | tr -d '\n' | gh secret set CLEAN_DENYLIST --repo "$$repo" && echo "CLEAN_DENYLIST set on $$repo from $$f"

smoke: package   ## shippability check: make check + build zip + verify zip contents
	@echo "smoke OK — suite is clean and the handoff zip is complete"
