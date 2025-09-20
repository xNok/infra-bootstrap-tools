---
title: "Hugo"
weight: 4
---

[Hugo](https://gohugo.io/) is a fast and flexible static site generator written in Go. It takes content written in Markdown and uses templates to generate a complete HTML website.

## Tutorial

Here's a common way to use Hugo for local development:

```bash
# Navigate to the website directory
cd website/

# Start the Hugo development server
hugo server -D
```

This command will build the site and serve it locally, usually at `http://localhost:1313/`. The `-D` flag ensures that draft content is also built.

## Usage in this Project

The documentation website for this project (the site you might be viewing this on if you're reading it online) is built using Hugo.

*   **Content**: All documentation content is located in the `website/content/` directory, primarily in Markdown format.
*   **Themes and Layouts**: The site uses a Hugo theme (located in `website/themes/`) and custom layouts to structure and style the content.
*   **Building and Serving**:
    *   The `./bin/bash/setup.sh hugo` script can install Hugo and start a local development server.
    *   The GitHub Actions workflow in `.github/workflows/website.yml` automatically builds and deploys the website to GitHub Pages.

Hugo's speed and simplicity make it an excellent choice for generating project documentation.
