#!/usr/bin/env bash
# Bash wrapper for automatic version bumping and release APK building
set -e

dart run tool/bump_and_build.dart "$@"
