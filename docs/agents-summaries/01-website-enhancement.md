# 01 - Website Enhancement: Blog, Gallery, and GitHub Pages Compatibility

Date: 2025-11-09

Author: GitHub Copilot AI Assistant

Role: Developer

Related docs: `.github/copilot-instructions.md`, `website/README.md`

## Summary
Enhanced the project website with blog and gallery sections, and fixed theme compatibility with GitHub Pages by implementing relative URLs throughout the site.

## Motivation
The website needed several improvements:
1. URLs were not compatible with GitHub Pages subpaths (only worked with custom domains)
2. No blog section for sharing articles and updates
3. No gallery section for showcasing project visuals
4. Theme was missing social media meta tags

## Files changed

### Theme Overrides (Relative URLs)
- `website/layouts/index.html` - Home page with relative URLs and new sections
- `website/layouts/docs/single.html` - Documentation page with relative URLs
- `website/layouts/partials/opengraph.html` - New Open Graph meta tags
- `website/layouts/partials/twitter_cards.html` - New Twitter card meta tags

### Blog Section
- `website/content/en/blog/_index.md` - Blog section index
- `website/content/en/blog/getting-started-with-iac.md` - Sample blog post
- `website/content/en/blog/homelab-docker-swarm.md` - Sample blog post
- `website/content/en/blog/automating-ssl-caddy.md` - Sample blog post
- `website/layouts/blog/list.html` - Blog list page layout
- `website/layouts/blog/single.html` - Blog single post layout
- `website/assets/css/blog-extended.css` - Blog styling

### Gallery Section
- `website/content/en/gallery/_index.md` - Gallery section index
- `website/content/en/gallery/docker-swarm-cluster.md` - Sample gallery item
- `website/content/en/gallery/ansible-automation.md` - Sample gallery item
- `website/content/en/gallery/caddy-proxy.md` - Sample gallery item
- `website/content/en/gallery/monitoring-stack.md` - Sample gallery item
- `website/content/en/gallery/home-network.md` - Sample gallery item
- `website/content/en/gallery/terraform-infra.md` - Sample gallery item
- `website/layouts/gallery/list.html` - Gallery list page layout
- `website/layouts/gallery/single.html` - Gallery single item layout
- `website/assets/css/gallery-extended.css` - Gallery styling

### Shared Styling
- `website/assets/css/home-extended.css` - Extended home page styling for new sections

## Commands run (for verification / reproduce)

```bash
# Install Hugo
cd /tmp
wget https://github.com/gohugoio/hugo/releases/download/v0.139.4/hugo_extended_0.139.4_linux-amd64.tar.gz
tar -xzf hugo_extended_0.139.4_linux-amd64.tar.gz
sudo mv hugo /usr/local/bin/

# Clone theme submodule
cd website/themes
git clone https://github.com/xNok/E25DX.git e25dx

# Build with root baseURL
cd website
hugo --baseURL="/"

# Build with GitHub Pages baseURL
hugo --baseURL="https://xnok.github.io/infra-bootstrap-tools/"

# Start development server
hugo server --bind=0.0.0.0 --port=1313 --baseURL="http://localhost:1313"
```

## Verification

### Build Tests
- ✅ Site builds successfully with root baseURL
- ✅ Site builds successfully with GitHub Pages baseURL
- ✅ All URLs are relative and include base path correctly
- ✅ No build errors or warnings (except expected layout warnings for unused taxonomies)

### Visual Tests
- ✅ Home page displays hero section, blog cards, and gallery mosaic
- ✅ Blog list page shows all articles with tags and dates
- ✅ Gallery list page shows all projects in grid layout
- ✅ Navigation works across all sections
- ✅ Responsive design works on mobile and tablet
- ✅ Dark/light mode toggle functions correctly

### Screenshots
- Home page: https://github.com/user-attachments/assets/dc5e54a7-39d7-4a65-9309-3a54b400f55d
- Blog page: https://github.com/user-attachments/assets/a7ccd7bc-a424-46e8-8476-039101e95894
- Gallery page: https://github.com/user-attachments/assets/10c8aea1-e504-480e-a462-6e5b04e23bbd

## Side effects / Notes

### Layout Overrides
- Created layout overrides in `website/layouts/` instead of modifying the theme submodule
- This approach allows theme updates without losing customizations
- Hugo's lookup order prioritizes project layouts over theme layouts

### Placeholder Content
- Used Unsplash images as placeholders for gallery items
- Sample blog posts and gallery items should be replaced with real content
- Images are loaded from CDN (may be blocked by ad blockers in dev)

### Missing Layouts
- Hugo warns about missing taxonomy, section, and term layouts
- These are not used by the site currently and can be ignored
- Can be added later if taxonomies/tags become needed

## Next steps

1. Replace sample blog posts with real content
2. Replace gallery items with actual project images
3. Add Pinterest integration for gallery images (as mentioned in requirements)
4. Consider adding RSS feed for blog posts
5. Add pagination for blog and gallery if content grows
6. Test deployment on GitHub Pages
7. Consider adding search functionality

## Technical Decisions

### Relative URLs
- Changed from `.Permalink` to `.RelPermalink` for all internal links
- Changed from `$resource.Permalink` to `$resource.RelPermalink` for assets
- This ensures compatibility with both custom domains and GitHub Pages subpaths

### Layout Structure
- Blog uses similar layout to docs but with simpler navigation
- Gallery uses card-based grid layout with mosaic effect on home page
- Both sections include navigation menu for easy access

### CSS Organization
- Separated concerns: home-extended.css, blog-extended.css, gallery-extended.css
- Reused theme variables for consistency (--padding, --color, etc.)
- Maintained responsive design principles from original theme

### Content Structure
- Followed Hugo's convention: section/_index.md for section landing pages
- Used frontmatter for metadata (title, date, tags, images)
- Kept content simple and focused on Infrastructure as Code topics
