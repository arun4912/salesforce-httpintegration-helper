#!/bin/bash
# Deploy salesforce-integration-helper to GitHub
# Run: ./deploy-to-github.sh

set -e
cd "$(dirname "$0")"

echo "Initializing git..."
git init

echo "Adding files..."
git add .

echo "Committing..."
git commit -m "IntegrationHelper, IntegrationUtility, and Custom Metadata Types" || true

echo "Setting remote..."
git remote add origin https://github.com/arun4912/salesforce-integration-helper.git 2>/dev/null || \
  git remote set-url origin https://github.com/arun4912/salesforce-integration-helper.git

echo "Pushing to GitHub..."
git branch -M main
git push -u origin main

echo "Done! Deployed to https://github.com/arun4912/salesforce-integration-helper"
