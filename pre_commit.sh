#!/bin/bash
set -e

# Run tests
flutter test

# Run linter
flutter analyze
