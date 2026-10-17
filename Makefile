# Builds the 78K0 SLEIGH language without a Ghidra source tree.
#
# `data/buildLanguage.xml` is the Ant build that ships with Ghidra processor
# modules. It imports ../.antProperties.xml, which the GhidraDev Eclipse plugin
# generates. That file does not exist in a standalone checkout of this repo, so
# the Ant build cannot run here. This Makefile is the standalone equivalent.
#
# GHIDRA defaults to the install this was developed against. Override it to
# build against a different one:
#
#   make GHIDRA=/path/to/ghidra_12.1.x_PUBLIC

GHIDRA ?= $(HOME)/opt/ghidra_12.1.4_PUBLIC
SLEIGH  := $(GHIDRA)/support/sleigh
LANGDIR := 78K0/data/languages

# Options come from data/sleighArgs.txt, one per line, comments and blank
# lines dropped. Keeping a single source of truth for the flags matters:
# -l turns pattern conflicts into hard errors rather than warnings, and a build
# that silently skips it will not report them.
SLEIGH_ARGS := $(shell sed -e 's/\#.*//' -e '/^[[:space:]]*$$/d' 78K0/data/sleighArgs.txt | tr '\n' ' ')

.PHONY: all clean check install deploy

all:
	cd $(LANGDIR) && $(SLEIGH) $(SLEIGH_ARGS) 78K0.slaspec

# The warnings that are expected and benign, so a new one stands out.
check: all
	@echo "---"
	@echo "Expect 8 warnings: 2 lines about NOP constructors (CY and PSW_Ref"
	@echo "display tables plus the NOP instruction itself) and 6 unreferenced"
	@echo "tables (rel8, rel8_1623, rel8_2431, saddr32low, saddr32high, sfr32)."
	@echo "Any other output is a regression."

clean:
	rm -f $(LANGDIR)/78K0.sla

# Deploy into a Ghidra install. This repo keeps the module one directory down,
# following the layout this project has always used, so a plain `git clone`
# into Ghidra/Processors/78K0 would land the data one level too deep. This
# target pulls and then copies instead.
#
# --delete makes the install an exact copy, so a file deleted here also
# disappears there. build.gradle is excluded because it only applies inside a
# Ghidra source tree and does nothing in an install.
#
# The install is a deployment target, not a checkout. Do not edit it in place:
# changes there are lost on the next install and will not show up in git.
deploy: install

# Pull only when this branch actually tracks a remote. A local-only branch has
# no upstream, and `git pull` there fails with a message about tracking
# information that reads like a repo problem rather than a branch one.
# Uncommitted changes are left alone: deploying a tree you have not committed
# means the install cannot be reproduced from git, which defeats the point.
install:
	@if ! git diff --quiet || ! git diff --cached --quiet; then \
		echo "Working tree has uncommitted changes. Commit them first," >&2; \
		echo "so the install stays reproducible from git." >&2; \
		exit 1; \
	fi
	@if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then \
		echo "git pull --ff-only"; \
		git pull --ff-only || exit 1; \
	else \
		echo "Branch has no upstream, skipping pull."; \
	fi
	rsync -a --delete \
		--exclude build.gradle \
		$(CURDIR)/78K0/ $(GHIDRA)/Ghidra/Processors/78K0/
	@echo "---"
	@echo "Deployed to $(GHIDRA)/Ghidra/Processors/78K0"
	@echo "Restart Ghidra for the language to be reloaded."

# Confirm the install matches this repo. Run after installing, and after any
# Ghidra upgrade, since the module is hand-installed rather than shipped.
verify:
	@diff -rq \
		--exclude build.gradle \
		$(CURDIR)/78K0/ $(GHIDRA)/Ghidra/Processors/78K0/ \
		&& echo "install matches repo"
