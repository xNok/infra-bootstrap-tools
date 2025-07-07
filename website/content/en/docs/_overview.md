---
title: Overview
url: "docs/overview"
aliases:
- "/docs"
---

I started Infra-Bootstrap-tools back when I was first diving into DevOps. It was essentially my personal lab, where I tested tools and ran experiments for my master's research from 2016 to 2018. Although the tech world has moved on, I've continued to tinker with it, striving to improve the code.

While everyone is enthusiastic about Kubernetes and similar technologies, I've found Docker Swarm and Portainer to be ideal for a small, easily managed lab. It might not be the most fashionable choice anymore, but I genuinely believe it's a solid option for setting up a home lab or a small deployment. I've stayed with it because it simply works and is easy to configure. This project is about providing a practical tool for those who want a reliable and straightforward setup. By reliable, I mean I can completely wipe the setup when not actively using it and be confident that I can have everything up and running again in a matter of minutes the next time I need it

Throughout this journey, I am striving to document as much as I can to introduce the tools and techniques I have used, and to provide pointers on how to achieve similar outcomes. I will also be demystifying some general concepts about infrastructure as code.

## Documentation Sections

To help you understand the different parts of this project, the documentation is organized into the following sections:

### Core Concepts & Components

*   **[Understanding Ansible Concepts]({{< ref "./b1.ansible_concepts.md" >}})**: Learn about the fundamental Ansible concepts (Playbooks, Roles, Tasks, etc.) used in this project.
*   **[Spinning up infrastructure with Ansible and Terraform]({{< ref "./b2.terraform_ansible.md" >}})**: How infrastructure is provisioned on DigitalOcean using Terraform and Ansible combined.
*   **[Docker Swarm Setup Roles]({{< ref "./b3.docker_swarm.md" >}})**: Details on the Ansible roles that configure the Docker Swarm cluster.

### Applications

*   **[Caddy Web Server]({{< ref "./a1.caddy.md" >}})**: Deep dive into how Caddy is used for reverse proxying and authentication.
*   **[Portainer Management UI]({{< ref "./a2.portainer.md" >}})**: Learn about Portainer for managing the Docker Swarm environment.
