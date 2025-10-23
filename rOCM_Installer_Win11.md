# 🛠 rOCM Windows 11 Installer Project

## Overview
Build a complete installer or script-based setup to enable AMD ROCm on Windows 11. This project targets average users who want a one-click or guided install experience—bridging the gap AMD hasn’t solved.

## Goals
- Detect compatible AMD hardware and Windows version
- Install required drivers, dependencies, and environment variables
- Validate ROCm runtime and toolchain installation
- Provide a GUI or CLI wrapper for guided install

## Core Features
- ✅ Hardware and OS compatibility check
- ✅ Driver and dependency installation
- ✅ Environment setup (PATH, HIP, etc.)
- ✅ ROCm runtime validation
- ✅ Logging and error reporting

## Stretch Goals
- 🔄 Auto-resolve common conflicts (e.g., driver mismatches, WSL2 issues)
- 🧩 Modular install options (PyTorch ROCm, HIP SDK, dev tools)
- 🧼 Rollback and uninstall support
- 🔐 Signed installer for trust and distribution

## Architecture