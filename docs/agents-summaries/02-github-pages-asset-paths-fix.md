# 02 - Fix GitHub Pages static asset paths for subdirectory deployment

Date: 2025-11-20

Author: GitHub Copilot Agent

Role: Developer

Related docs: N/A

## Summary
Fixed broken static assets (CSS, JS, favicon) on the Hugo-based website when deployed to GitHub Pages at `xnok.github.io/infra-bootstrap-tools/`. The issue was caused by `relativeURLs: true` in Hugo config, which generated incorrect relative paths that duplicated the subdirectory path.

## Motivation
Static assets were not loading when the site was deployed to GitHub Pages as a project page (subdirectory deployment). The problem statement indicated that all static assets were not working as expected due to incorrect path generation.

## Files changed

`website/hugo.yaml` — Removed `relativeURLs: true` and set `baseURL` to `https://xnok.github.io/infra-bootstrap-tools/`

`website/static/manifest.json` — Updated favicon paths from `/favicon/...` to `/infra-bootstrap-tools/favicon/...`

`website/static/sw.js` — Updated all asset paths from relative `./` to absolute `/infra-bootstrap-tools/...`

## Commands run (for verification / reproduce)

```bash
# Install Hugo
wget https://github.com/gohugoio/hugo/releases/download/v0.147.3/hugo_extended_0.147.3_linux-amd64.deb
sudo dpkg -i hugo_extended_0.147.3_linux-amd64.deb

# Navigate to website directory
cd /home/runner/work/infra-bootstrap-tools/infra-bootstrap-tools/website

# Test build with GitHub Pages baseURL
hugo --gc --minify --baseURL "https://xnok.github.io/infra-bootstrap-tools/"

# Verify generated URLs
grep -o "href=[^ >]*\|src=[^ >]*" public/index.html | head -20

# Test build with default baseURL from config
hugo --gc --minify
```

## Verification
- Built the site with Hugo and verified that all URLs generate correctly as `/infra-bootstrap-tools/...` instead of `./infra-bootstrap-tools/...`
- Checked multiple pages (index.html, blog, docs) to ensure consistent URL generation
- Verified manifest.json and service worker (sw.js) contain correct paths
- Confirmed the GitHub Actions workflow will work correctly with the updated configuration

## Side effects / Notes
- The baseURL is now hardcoded in the config, but the GitHub Actions workflow still passes `--baseURL` during build which will override it
- Service worker asset paths are updated, which may require browser cache clearing for existing users (once deployed)
- The solution follows Hugo's recommended approach for subdirectory deployments on GitHub Pages

## Next steps
- Monitor the deployment after merge to confirm assets load correctly in production
- Consider if we need to make the config more flexible for local development (though current setup should work fine)

---

*Root cause: Hugo's `relativeURLs: true` generates paths like `./infra-bootstrap-tools/` which resolve to `/infra-bootstrap-tools/infra-bootstrap-tools/` when the site base is already `/infra-bootstrap-tools/`.*
