# Website Content Guidelines

This document provides guidelines for creating and organizing content for the Infra Bootstrap Tools website.

## Table of Contents
- [Content Structure Overview](#content-structure-overview)
- [Blog Content Guidelines](#blog-content-guidelines)
- [Content Readiness Checklist](#content-readiness-checklist)
- [Recommended Content to Write](#recommended-content-to-write)

---

## Content Structure Overview

The website has two main content sections:

1. **Documentation** (`website/content/en/docs/`) - Technical guides and reference material
2. **Blog** (`website/content/en/blog/`) - Articles, tutorials, and updates

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

### Priority 2: Enhanced Content

Once the minimum content is complete, consider:

- **Video tutorials** (embed YouTube)
- **Interactive diagrams** (using Mermaid in markdown)
- **Code repositories** (link to GitHub examples)
- **Community contributions** (guest posts)
- **Series articles** (multi-part tutorials)

---

## Writing Tips

### For Blog Posts
- Start with a compelling hook
- Use short paragraphs (3-4 sentences max)
- Include visual breaks (images, code blocks, lists)
- End with a call-to-action or next steps
- Preview before publishing

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
- Minimum content requirements are met (5+ blog posts)
- All content is original and high-quality
- No placeholder text or broken links remain
- Site has been tested across devices
- SEO basics are implemented (meta descriptions, proper headings, etc.)

**Estimated total time to reach release-ready state: 25-35 hours of writing**

Start with Priority 1 blog posts. Quality over quantity—it's better to have 5 excellent posts than 10 mediocre ones.
