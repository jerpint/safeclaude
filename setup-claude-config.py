#!/usr/bin/env python3
"""Patch ~/.claude.json to skip onboarding and accept trust dialog for the working directory."""

import json
import os
import sys

CONFIG = "/home/node/.claude.json"

data = {}
if os.path.exists(CONFIG):
    with open(CONFIG) as f:
        data = json.load(f)

data["hasCompletedOnboarding"] = True

cwd = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
project = data.setdefault("projects", {}).setdefault(cwd, {})
project["hasTrustDialogAccepted"] = True

with open(CONFIG, "w") as f:
    json.dump(data, f, indent=2)
