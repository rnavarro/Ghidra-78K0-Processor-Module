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

.PHONY: all clean check

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
