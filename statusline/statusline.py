#!/usr/bin/env python3
"""Configurable statusline for Claude Code. Reads session JSON from stdin, outputs formatted status bar."""

import json
import os
import sys
import glob
import time
import hashlib
import tempfile
from datetime import datetime, timezone

from statusline.helpers import get_system_color_scheme

CACHE_PREFIX = "claude_statusline_cache_"
CLAUDE_DIR = os.path.join(os.path.expanduser("~"), ".claude")
CONFIG_PATH = os.path.join(CLAUDE_DIR, "statusline", "config.json")

COLOR_SCHEME = get_system_color_scheme()