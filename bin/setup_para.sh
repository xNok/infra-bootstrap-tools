#!/bin/bash
set -e

# Base directory for staging
STAGING_DIR="docs/_staging_para"
WEBSITE_DIR="website"

echo "Creating Staging PARA Structure in $STAGING_DIR..."

# 1-projects
mkdir -p "$STAGING_DIR/1-projects"
touch "$STAGING_DIR/1-projects/.gitkeep"

# 2-areas
mkdir -p "$STAGING_DIR/2-areas/infra"
touch "$STAGING_DIR/2-areas/infra/.gitkeep"
mkdir -p "$STAGING_DIR/2-areas/dev"
touch "$STAGING_DIR/2-areas/dev/.gitkeep"
mkdir -p "$STAGING_DIR/2-areas/sec"
touch "$STAGING_DIR/2-areas/sec/.gitkeep"

# 3-resources
mkdir -p "$STAGING_DIR/3-resources/caddy"
touch "$STAGING_DIR/3-resources/caddy/.gitkeep"
mkdir -p "$STAGING_DIR/3-resources/portainer"
touch "$STAGING_DIR/3-resources/portainer/.gitkeep"

# 4-archives
mkdir -p "$STAGING_DIR/4-archives"
touch "$STAGING_DIR/4-archives/.gitkeep"

echo "Creating Website Structure in $WEBSITE_DIR..."

# website/docs
mkdir -p "$WEBSITE_DIR/docs/guides"
touch "$WEBSITE_DIR/docs/guides/.gitkeep"
mkdir -p "$WEBSITE_DIR/docs/references"
touch "$WEBSITE_DIR/docs/references/.gitkeep"

# website/blog
mkdir -p "$WEBSITE_DIR/blog"
touch "$WEBSITE_DIR/blog/.gitkeep"

echo "Cleaning up legacy directories..."

# Delete docs/agents-summaries if it exists
if [ -d "docs/agents-summaries" ]; then
    rm -rf "docs/agents-summaries"
    echo "Removed docs/agents-summaries"
fi

echo "PARA setup complete."
