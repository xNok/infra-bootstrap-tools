# 01 - Website Enhancement: Blog and GitHub Pages Compatibility

Date: 2025-11-09
Updated: 2025-11-19

Author: GitHub Copilot AI Assistant

Role: Developer

Related docs: `.github/copilot-instructions.md`, `website/README.md`

## Summary
Enhanced the project website with a blog section and fixed theme compatibility with GitHub Pages by implementing relative URLs throughout the site.

## Motivation
The website needed several improvements:
1. URLs were not compatible with GitHub Pages subpaths (only worked with custom domains)
2. No blog section for sharing articles and updates
3. Theme was missing social media meta tags

## Files changed

### Theme Overrides (Relative URLs)
- `website/layouts/index.html` - Home page with relative URLs and blog section
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
- ✅ Home page displays hero section and blog cards
- ✅ Blog list page shows all articles with tags and dates
- ✅ Navigation works across all sections
- ✅ Responsive design works on mobile and tablet
- ✅ Dark/light mode toggle functions correctly

### Screenshots
- Home page: https://github.com/user-attachments/assets/dc5e54a7-39d7-4a65-9309-3a54b400f55d
- Blog page: https://github.com/user-attachments/assets/a7ccd7bc-a424-46e8-8476-039101e95894

## Side effects / Notes

### Layout Overrides
- Created layout overrides in `website/layouts/` instead of modifying the theme submodule
- This approach allows theme updates without losing customizations
- Hugo's lookup order prioritizes project layouts over theme layouts

### Placeholder Content
- Sample blog posts should be replaced with real content
- Content guidelines provided in `website/CONTENT_GUIDELINES.md`

### Missing Layouts
- Hugo warns about missing taxonomy, section, and term layouts
- These are not used by the site currently and can be ignored
- Can be added later if taxonomies/tags become needed

### Scope Reduction (2025-11-19)
- Gallery section removed to reduce PR scope
- Gallery functionality can be implemented in the E25DX theme directly
- Focus on blog and GitHub Pages compatibility for this PR

## Next steps

1. Replace sample blog posts with real content
2. Consider adding RSS feed for blog posts
3. Add pagination for blog if content grows
4. Test deployment on GitHub Pages
5. Consider adding search functionality
6. Gallery functionality to be added in theme updates

## Technical Decisions

### Relative URLs
- Changed from `.Permalink` to `.RelPermalink` for all internal links
- Changed from `$resource.Permalink` to `$resource.RelPermalink` for assets
- This ensures compatibility with both custom domains and GitHub Pages subpaths

### Layout Structure
- Blog uses similar layout to docs but with simpler navigation
- Navigation menu for easy access between docs and blog

### CSS Organization
- Separated concerns: home-extended.css, blog-extended.css
- Reused theme variables for consistency (--padding, --color, etc.)
- Maintained responsive design principles from original theme

### Content Structure
- Followed Hugo's convention: section/_index.md for section landing pages
- Used frontmatter for metadata (title, date, tags, images)
- Kept content simple and focused on Infrastructure as Code topics
