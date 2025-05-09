#!/usr/bin/python
import os
from pathlib import Path

source_dir = Path(".config").resolve()
target_base = Path.home() / ".config"

target_base.mkdir(parents=True, exist_ok=True)

for item in source_dir.iterdir():
    if item.is_dir():
        target_link = target_base / item.name
        if target_link.exists() or target_link.is_symlink():
            print(f"Skipping existing: {target_link}")
            continue
        try:
            os.symlink(item, target_link)
            print(f"Linked {item} -> {target_link}")
        except OSError as e:
            print(f"Failed to link {item} -> {target_link}: {e}")
