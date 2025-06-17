---
title: "Boilerplate (Gruntwork)"
slug: boilerplate
weight: 3
---


[Gruntwork Boilerplate](https://github.com/gruntwork-io/boilerplate) is a tool that helps you create and manage reusable templates for your code and configuration. It allows you to define a template once and then generate new files or projects from it by filling in variables.

## Usage in this Project

This project uses Gruntwork Boilerplate to maintain consistency and speed up the creation of new components, particularly for Ansible roles.

*   **Ansible Role Template**: A template for new Ansible roles is located in `.boilerplates/ansible-role/`. This includes a standard directory structure, placeholder files, and common configuration.
*   **Generating New Roles**: You can use the `boilerplate` CLI (installable via `./bin/bash/setup.sh boilerplate`) to generate a new Ansible role from this template.

This helps ensure that all Ansible roles follow a similar structure, making them easier to understand and maintain.
