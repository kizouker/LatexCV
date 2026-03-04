# Makefile for LuaLaTeX (moderncv) CV builds
# Usage:
#   make            # build (auto-picks main .tex if MAIN not set)
#   make MAIN=foo.tex
#   make clean
#   make watch      # needs latexmk
#   make open       # macOS: opens the PDF

SHELL := /bin/bash

# Pick main tex:
# - If you set MAIN=..., we use that.
# - Otherwise we use the first *.tex in the current directory.
MAIN ?= $(firstword $(wildcard *.tex))
BASENAME := $(basename $(MAIN))
PDF := $(BASENAME).pdf

# Tools
LATEXMK ?= latexmk
LUALATEX ?= lualatex

# LuaLaTeX flags
LATEXFLAGS := -interaction=nonstopmode -halt-on-error -file-line-error

# latexmk flags (LuaLaTeX)
LATEXMKFLAGS := -lualatex -interaction=nonstopmode -halt-on-error -file-line-error

.PHONY: help all build clean distclean watch open info

all: build

help:
	@echo "Targets:"
	@echo "  make [MAIN=yourfile.tex]   Build PDF with LuaLaTeX/latexmk if available"
	@echo "  make watch                Auto-rebuild on changes (requires latexmk)"
	@echo "  make open                 Open resulting PDF (macOS uses 'open')"
	@echo "  make clean                Remove aux files"
	@echo "  make distclean            Clean + remove PDF"
	@echo ""
	@echo "Detected MAIN: $(MAIN)"
	@echo "Output PDF:    $(PDF)"

info:
	@echo "MAIN=$(MAIN)"
	@echo "PDF=$(PDF)"
	@echo "BASENAME=$(BASENAME)"

build:
	@if [ ! -f "$(MAIN)" ]; then \
		echo "ERROR: No .tex file found in current dir, or MAIN is wrong."; \
		echo "Try: make MAIN=YourFile.tex"; \
		exit 1; \
	fi
	@if command -v "$(LATEXMK)" >/dev/null 2>&1; then \
		echo "==> Building with latexmk (LuaLaTeX): $(MAIN)"; \
		"$(LATEXMK)" $(LATEXMKFLAGS) "$(MAIN)"; \
	else \
		echo "==> latexmk not found; building with lualatex x2: $(MAIN)"; \
		"$(LUALATEX)" $(LATEXFLAGS) "$(MAIN)"; \
		"$(LUALATEX)" $(LATEXFLAGS) "$(MAIN)"; \
	fi

watch:
	@if command -v "$(LATEXMK)" >/dev/null 2>&1; then \
		echo "==> Watching (latexmk -pvc) : $(MAIN)"; \
		"$(LATEXMK)" -pvc -lualatex $(LATEXMKFLAGS) "$(MAIN)"; \
	else \
		echo "ERROR: watch requires latexmk. Install it (Mac: MacTeX includes it)."; \
		exit 1; \
	fi

open: build
	@if [ -f "$(PDF)" ]; then \
		echo "==> Opening: $(PDF)"; \
		open "$(PDF)" 2>/dev/null || xdg-open "$(PDF)" 2>/dev/null || echo "Open manually: $(PDF)"; \
	else \
		echo "ERROR: PDF not found: $(PDF)"; \
		exit 1; \
	fi

clean:
	@echo "==> Cleaning aux files for $(BASENAME).*"
	@rm -f "$(BASENAME)".{aux,log,out,toc,lof,lot,fls,fdb_latexmk,xdv,bbl,blg,bcf,run.xml,synctex.gz} 2>/dev/null || true

distclean: clean
	@echo "==> Removing PDF: $(PDF)"
	@rm -f "$(PDF)" 2>/dev/null || true
