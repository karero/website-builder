.PHONY: install install-codex package check smoke

install:   ## symlink every skill into ~/.claude/skills/ (Claude Code)
	@bash scripts/install.sh

install-codex:   ## symlink every skill into ~/.agents/skills/ (OpenAI Codex)
	@bash scripts/install-codex.sh

package: check   ## build dist/website-builder.zip for handoff (runs check first)
	@bash scripts/package.sh

check:     ## fail if any personal name / contact info / credential is in the suite
	@bash scripts/check_clean.sh

smoke: package   ## shippability check: make check + build zip + verify zip contents
	@echo "smoke OK — suite is clean and the handoff zip is complete"
