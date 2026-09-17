#!/bin/bash
# SessionStart hook: installs a working LaTeX toolchain for this repo's
# moderncv-based CVs (banking style, photo, fontawesome icons, Swedish babel).
#
# Only runs in Claude Code on the web's remote containers, since local
# machines usually already have LaTeX (or the user manages it themselves).
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

set -euo pipefail

# Idempotency / fast path: if moderncv.cls and lmodern.sty already resolve,
# the toolchain from a previous run in this container is still present.
if command -v kpsewhich >/dev/null 2>&1 \
  && kpsewhich moderncv.cls >/dev/null 2>&1 \
  && kpsewhich lmodern.sty >/dev/null 2>&1 \
  && command -v latexmk >/dev/null 2>&1 \
  && command -v pdftoppm >/dev/null 2>&1; then
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

# texlive-fonts-extra is required because moderncv's `banking` style loads
# moderncviconsawesome.sty, which needs fontawesome5.sty -- that package
# lives in texlive-fonts-extra, not in the base/recommended sets.
#
# `lmodern` (the actual .sty package) is required separately from the
# `fonts-lmodern` package: fonts-lmodern only ships the OpenType font files,
# while lmodern.sty (needed by \usepackage{lmodern} in these CVs) comes from
# the `lmodern` package itself.
apt-get install -y -qq --no-install-recommends \
  texlive-latex-base \
  texlive-latex-extra \
  texlive-fonts-recommended \
  texlive-fonts-extra \
  texlive-lang-european \
  lmodern \
  latexmk \
  poppler-utils
