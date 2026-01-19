#!/bin/bash

# Deployment script for n8n Heroku with cache clearing
# This ensures a fresh build without Docker layer caching

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== n8n Heroku Deployment Script ===${NC}"
echo ""

# Check if app name is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide your Heroku app name${NC}"
    echo "Usage: ./deploy.sh YOUR-APP-NAME"
    exit 1
fi

APP_NAME=$1

echo -e "${YELLOW}Deploying to app: ${APP_NAME}${NC}"
echo ""

# Step 1: Check if heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo -e "${RED}Error: Heroku CLI is not installed${NC}"
    echo "Install it from: https://devcenter.heroku.com/articles/heroku-cli"
    exit 1
fi

# Step 2: Check if heroku-builds plugin is installed
echo -e "${YELLOW}[1/7] Checking heroku-builds plugin...${NC}"
if ! heroku plugins | grep -q "heroku-builds"; then
    echo "Installing heroku-builds plugin..."
    heroku plugins:install heroku-builds
else
    echo "✓ heroku-builds plugin already installed"
fi

# Step 3: Check git status
echo -e "${YELLOW}[2/7] Checking git status...${NC}"
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}Warning: You have uncommitted changes${NC}"
    read -p "Do you want to commit them now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "Update n8n configuration for Form Trigger support"
    else
        echo "Proceeding with uncommitted changes..."
    fi
else
    echo "✓ Git working directory is clean"
fi

# Step 4: Clear Heroku build cache
echo -e "${YELLOW}[3/7] Clearing Heroku build cache...${NC}"
heroku builds:cache:purge -a $APP_NAME
echo "✓ Build cache cleared"

# Step 5: Update CACHEBUST in Dockerfile
echo -e "${YELLOW}[4/7] Updating CACHEBUST argument...${NC}"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
sed -i.bak "s/ARG CACHEBUST=.*/ARG CACHEBUST=$TIMESTAMP/" Dockerfile
rm -f Dockerfile.bak
echo "✓ CACHEBUST updated to: $TIMESTAMP"

# Step 6: Commit the CACHEBUST change
git add Dockerfile
git commit -m "Update CACHEBUST to $TIMESTAMP" --allow-empty

# Step 7: Deploy to Heroku
echo -e "${YELLOW}[5/7] Deploying to Heroku...${NC}"
git push heroku main

# Step 8: Wait a moment for deployment
echo -e "${YELLOW}[6/7] Waiting for deployment to complete...${NC}"
sleep 5

# Step 9: Restart the dyno
echo -e "${YELLOW}[7/7] Restarting dyno...${NC}"
heroku restart -a $APP_NAME

echo ""
echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "Next steps:"
echo "1. Check logs: heroku logs --tail -a $APP_NAME"
echo "2. Open your app: heroku open -a $APP_NAME"
echo "3. Try creating a NEW workflow and adding the Form Trigger"
echo ""
echo "If the Form Trigger still doesn't work in EXISTING workflows,"
echo "see TROUBLESHOOTING.md for database cleanup steps."
