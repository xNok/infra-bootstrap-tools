# Website Content Guidelines

This document provides guidelines for creating and organizing content for the Infra Bootstrap Tools website.

## Table of Contents
- [Content Structure Overview](#content-structure-overview)
- [Blog Content Guidelines](#blog-content-guidelines)
- [Gallery Content Guidelines](#gallery-content-guidelines)
- [Content Readiness Checklist](#content-readiness-checklist)
- [Recommended Content to Write](#recommended-content-to-write)

---

## Content Structure Overview

The website has three main content sections:

1. **Documentation** (`website/content/en/docs/`) - Technical guides and reference material
2. **Blog** (`website/content/en/blog/`) - Articles, tutorials, and updates
3. **Gallery** (`website/content/en/gallery/`) - Visual showcase of projects and implementations

---

## Blog Content Guidelines

### Purpose
The blog section is for sharing knowledge, experiences, and updates about infrastructure automation, DevOps practices, and homelab projects.

### File Location
`website/content/en/blog/[post-slug].md`

### Frontmatter Template
```yaml
---
title: "Your Article Title"
date: YYYY-MM-DD
author: xNok
summary: A concise 1-2 sentence summary that appears in blog cards
featured_image: /images/blog/your-image.jpg (optional)
tags:
  - Tag1
  - Tag2
  - Tag3
---
```

### Content Structure
1. **Title**: Clear, descriptive, and SEO-friendly
2. **Introduction**: Hook the reader in the first paragraph
3. **Main Content**: Use headings (##, ###) for structure
4. **Code Examples**: Use fenced code blocks with language specification
5. **Conclusion**: Summarize key points and next steps

### Best Practices
- **Length**: 800-2000 words for comprehensive articles
- **Tone**: Educational, practical, and conversational
- **Images**: Use descriptive alt text for accessibility
- **Links**: Link to relevant docs or external resources
- **Tags**: Use 3-5 relevant tags per post
- **Summary**: Write compelling summaries that encourage clicks

### Content Types

#### Tutorial Posts
- Step-by-step instructions
- Prerequisites clearly stated
- Expected outcomes described
- Code examples with explanations
- Troubleshooting tips

**Example topics:**
- "Setting Up a Docker Swarm Cluster from Scratch"
- "Automating Infrastructure with Ansible Playbooks"
- "Implementing Zero-Trust Security in Your Homelab"

#### Concept Posts
- Explain technical concepts
- Compare different approaches
- Discuss pros and cons
- Provide real-world examples

**Example topics:**
- "Understanding Infrastructure as Code: A Practical Guide"
- "Container Orchestration: Docker Swarm vs Kubernetes"
- "GitOps Principles for Infrastructure Management"

#### Project Updates
- Share milestones and achievements
- Document challenges and solutions
- Lessons learned
- Future plans

**Example topics:**
- "My Homelab Journey: Year in Review"
- "Migrating from VMs to Containers: Lessons Learned"
- "Building a Production-Ready Homelab Stack"

### SEO Considerations
- Use descriptive URLs (slug matches title)
- Include target keywords naturally
- Write compelling meta descriptions (summaries)
- Use proper heading hierarchy
- Add internal links to docs and other posts

---

## Gallery Content Guidelines

### Purpose
The gallery showcases completed projects, configurations, and implementations with visual appeal. It's meant to inspire and demonstrate practical applications of the concepts covered in docs and blog posts.

### File Location
`website/content/en/gallery/[project-slug].md`

### Frontmatter Template
```yaml
---
title: "Project Name"
date: YYYY-MM-DD
description: A clear, concise description of what the project is
featured_image: /images/gallery/your-image.jpg (or external URL)
tags:
  - Technology1
  - Technology2
  - Category
---
```

### Content Structure
1. **Overview**: Brief description of the project
2. **Architecture/Stack**: What technologies were used
3. **Key Features**: Bullet points of main features
4. **Implementation Details**: How it was built (optional)
5. **Results/Outcome**: What was achieved

### Best Practices
- **Images**: High-quality, relevant images are essential
  - Minimum size: 1200x675px (16:9 ratio)
  - Format: JPG or WebP for photos, PNG for diagrams
  - Optimize for web (compress to <500KB)
- **Description**: Clear and compelling, 15-25 words
- **Tags**: Use technology names and categories
- **Content**: Keep it concise (300-600 words)

### Image Sources
Until you have your own project images, you can use:

1. **Unsplash** (free, no attribution required)
   - Search for relevant infrastructure/tech images
   - Use `https://images.unsplash.com/photo-[ID]?w=1200&q=80`

2. **Your Screenshots**
   - Take screenshots of your actual infrastructure
   - Use tools like Grafana, Portainer, etc. to show your setup
   - Blur/redact sensitive information

3. **Architecture Diagrams**
   - Create diagrams with tools like:
     - Draw.io / Diagrams.net (free)
     - Excalidraw (free, online)
     - Lucidchart (free tier)
   - Export as PNG with transparent background

### Pinterest Integration (Future)
The gallery is designed to support Pinterest integration. When implementing:
- Add Pinterest save button to gallery items
- Optimize images for Pinterest (2:3 ratio ideal)
- Add rich pins metadata
- Create boards for different categories

### Content Types

#### Infrastructure Projects
**Example: "Docker Swarm Production Cluster"**
- Cluster architecture
- Services deployed
- High availability setup
- Monitoring and logging

#### Automation Implementations
**Example: "Ansible Configuration Management"**
- Playbook structure
- Roles and tasks
- Inventory organization
- Secrets management

#### Network Setups
**Example: "Segmented Home Network"**
- VLAN configuration
- Firewall rules
- Security zones
- Network diagram

#### Monitoring/Observability
**Example: "Full Stack Monitoring with Prometheus & Grafana"**
- Metrics collected
- Dashboards created
- Alert configuration
- Integration points

---

## Content Readiness Checklist

Before considering the website ready for release, ensure:

### Blog Section (Minimum Requirements)
- [ ] At least 5 published articles
- [ ] Topics cover core infrastructure concepts
- [ ] At least one tutorial-style post
- [ ] At least one concept-explanation post
- [ ] All posts have proper tags and summaries
- [ ] Images used have proper attribution (if required)
- [ ] All code examples are tested and working
- [ ] Internal links to docs are added where relevant

### Gallery Section (Minimum Requirements)
- [ ] At least 8 project entries
- [ ] All entries have featured images
- [ ] Mix of different project types
- [ ] Clear, compelling descriptions
- [ ] Proper tags for categorization
- [ ] At least 3 entries have your own screenshots/diagrams
- [ ] Content is organized by relevance/date

### Quality Standards
- [ ] No placeholder text (Lorem ipsum, etc.)
- [ ] No broken links
- [ ] All images load correctly
- [ ] Mobile-responsive on all pages
- [ ] No spelling or grammar errors
- [ ] Consistent tone and style
- [ ] Proper frontmatter on all content

### Technical Requirements
- [ ] Build passes without errors
- [ ] All relative URLs work correctly
- [ ] Site works with GitHub Pages baseURL
- [ ] Navigation functions properly
- [ ] Dark/light mode toggle works
- [ ] All CSS/JS assets load

---

## Recommended Content to Write

### Priority 1: Blog Posts (Write These First)

1. **"Getting Started with Infra Bootstrap Tools"** (Tutorial)
   - Introduction to the project
   - Prerequisites and setup
   - First steps with the tools
   - Expected outcomes
   - _Estimated time: 4-6 hours_

2. **"Infrastructure as Code Best Practices"** (Concept)
   - Core IaC principles
   - Version control strategies
   - Testing approaches
   - Documentation standards
   - _Estimated time: 3-4 hours_

3. **"Building a Self-Hosted Homelab: Complete Guide"** (Tutorial)
   - Hardware requirements
   - OS selection and setup
   - Essential services to deploy
   - Monitoring and maintenance
   - _Estimated time: 6-8 hours_

4. **"Docker Swarm vs Kubernetes for Homelabs"** (Concept)
   - Feature comparison
   - Learning curve analysis
   - Resource requirements
   - Use case recommendations
   - _Estimated time: 3-4 hours_

5. **"Securing Your Self-Hosted Infrastructure"** (Tutorial)
   - Network segmentation
   - SSL/TLS setup with Caddy
   - Firewall configuration
   - Secrets management
   - _Estimated time: 4-5 hours_

6. **"Ansible for Infrastructure Automation"** (Tutorial)
   - Ansible basics
   - Writing playbooks
   - Managing inventory
   - Best practices
   - _Estimated time: 5-6 hours_

### Priority 2: Gallery Projects (Add These Next)

1. **"Production Docker Swarm Cluster"**
   - Take screenshots of Portainer
   - Document your actual setup
   - Show service deployment
   - _Estimated time: 2-3 hours_

2. **"Home Network Architecture"**
   - Create a network diagram
   - Document VLAN setup
   - Show firewall rules
   - _Estimated time: 3-4 hours_

3. **"Monitoring Dashboard Collection"**
   - Screenshot Grafana dashboards
   - Document metrics collected
   - Explain alerting setup
   - _Estimated time: 2-3 hours_

4. **"Ansible Playbook Repository"**
   - Show directory structure
   - Highlight key playbooks
   - Explain organization
   - _Estimated time: 2 hours_

5. **"Caddy Reverse Proxy Configuration"**
   - Show Caddyfile examples
   - Document SSL automation
   - Explain routing setup
   - _Estimated time: 2 hours_

6. **"Backup and Disaster Recovery Setup"**
   - Document backup strategy
   - Show automation scripts
   - Explain recovery process
   - _Estimated time: 3-4 hours_

7. **"CI/CD Pipeline for Infrastructure"**
   - Show GitHub Actions workflow
   - Explain testing strategy
   - Document deployment process
   - _Estimated time: 3-4 hours_

8. **"Terraform Multi-Cloud Setup"**
   - Create architecture diagram
   - Show Terraform modules
   - Document provider configuration
   - _Estimated time: 3-4 hours_

### Priority 3: Enhanced Content

Once the minimum content is complete, consider:

- **Video tutorials** (embed YouTube)
- **Interactive diagrams** (using Mermaid in markdown)
- **Code repositories** (link to GitHub examples)
- **Community contributions** (guest posts)

---

## Writing Tips

### For Blog Posts
- Start with a compelling hook
- Use short paragraphs (3-4 sentences max)
- Include visual breaks (images, code blocks, lists)
- End with a call-to-action or next steps
- Preview before publishing

### For Gallery Items
- Lead with the most impressive visual
- Focus on what makes the project unique
- Keep technical jargon minimal in descriptions
- Let the images tell the story
- Link to related blog posts for details

### General
- Write in active voice
- Use "you" to address readers
- Be specific with examples
- Break complex topics into steps
- Proofread before committing

---

## Content Maintenance

### Regular Updates
- Review and update older posts quarterly
- Fix broken links monthly
- Update screenshots when UI changes
- Add new tags as topics evolve

### User Feedback
- Monitor comments/issues on GitHub
- Address technical inaccuracies promptly
- Incorporate user suggestions
- Create content based on common questions

---

## Getting Help

If you need assistance with content:
1. Check existing docs in `/website/content/en/docs/`
2. Review the theme documentation
3. Look at sample posts in `/website/content/en/blog/`
4. Test locally with `hugo server`
5. Create an issue for feedback

---

## Conclusion

This website is ready for release when:
- Minimum content requirements are met (5+ blog posts, 8+ gallery items)
- All content is original and high-quality
- No placeholder text or broken links remain
- Site has been tested across devices
- SEO basics are implemented (meta descriptions, proper headings, etc.)

**Estimated total time to reach release-ready state: 40-50 hours of writing**

Start with Priority 1 blog posts, then move to Priority 2 gallery projects. Quality over quantity—it's better to have 5 excellent posts than 10 mediocre ones.
