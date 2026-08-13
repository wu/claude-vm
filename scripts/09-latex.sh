#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get install -y \
  latexmk \
  texlive-fonts-extra \
  texlive-latex-base \
  texlive-latex-extra \
  texlive-latex-recommended
