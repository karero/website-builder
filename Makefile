.PHONY: install package check

install:   ## symlink every skill into ~/.claude/skills/
	@bash scripts/install.sh

package: check   ## build dist/website-builder.zip for handoff (runs check first)
	@bash scripts/package.sh

check:     ## fail if any personal name / contact info / credential is in the suite
	@bash scripts/check_clean.sh
