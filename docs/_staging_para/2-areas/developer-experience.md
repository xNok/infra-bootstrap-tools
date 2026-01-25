---
type: area
description: Tools, workflows, and practices to improve developer productivity and onboarding experience
related_projects:
  - ibt-nix-refactor
  - changeset-release-mgmt
related_resources:
  - nix
  - bash
  - pre-commit
  - vscode
  - gitpod
---

# Developer Experience

## Overview

Developer Experience focuses on making it easy and enjoyable for developers to work with the infra-bootstrap-tools repository. This includes environment setup, tooling, documentation, and workflows that reduce friction and increase productivity.

## Scope

This area covers:
- **Environment Setup**: Quick, reproducible development environments
- **CLI Tools**: Unified command-line interfaces (ibt)
- **Documentation**: Clear, comprehensive guides and references
- **Automation**: Pre-commit hooks, linting, formatting
- **IDE Integration**: VSCode extensions and configurations
- **Onboarding**: Getting new contributors productive quickly

## Key Technologies

### Environment Management
- **Nix**: Reproducible development environments
- **Bash Scripts**: Setup and automation scripts
- **Docker**: Containerized tooling
- **Gitpod**: Cloud-based development environments

### Development Tools
- **VSCode**: Primary IDE with extensions
- **Pre-commit**: Git hooks for quality checks
- **Ansible Lint**: Playbook validation
- **Yamllint**: YAML validation
- **Boilerplate**: Code generation

### CI/CD Integration
- **GitHub Actions**: Automated testing and publishing
- **Changesets**: Release management
- **CodeQL**: Security scanning

## Core Responsibilities

### Environment Management
1. **Setup Automation**: One-command environment setup
2. **Tool Installation**: Automated dependency installation
3. **Version Management**: Consistent tool versions
4. **Isolation**: Avoid conflicts with system tools
5. **Documentation**: Clear setup instructions

### CLI Development
1. **Command Design**: Intuitive command structure
2. **Tab Completion**: Shell completion for productivity
3. **Help Systems**: Built-in documentation
4. **Error Messages**: Helpful error messages
5. **Testing**: Comprehensive test coverage

### Documentation
1. **Getting Started**: Step-by-step guides
2. **Reference Docs**: Detailed API/tool documentation
3. **Tutorials**: Hands-on learning materials
4. **Troubleshooting**: Common issues and solutions
5. **Examples**: Real-world usage examples

### Code Quality
1. **Linting**: Automated code quality checks
2. **Formatting**: Consistent code style
3. **Testing**: Automated test suites
4. **Review**: Code review guidelines
5. **Security**: Automated security scanning

## Current Projects Using This Area

1. **IBT CLI Tool** - Core developer interface
2. **Changeset Release Management** - Release workflow
3. All projects benefit from improved DX

## Standards and Patterns

### CLI Command Structure
```bash
# Standard ibt command pattern
ibt <subcommand> [options...]

# Examples
ibt setup ansible
ibt stacks run prefect
ibt tools dasb --version
```

### Shell Completion Pattern
```bash
# Dynamic completion via --list-options
script.sh --list-options
# Returns:
# option1
# option2
# option3

# Used by completion function
complete -F _script_completion script
```

### Nix Environment Pattern
```nix
{
  buildInputs = [ tool1 tool2 tool3 ];
  
  shellHook = ''
    # Setup tasks on environment entry
    echo "Setting up environment..."
    # Activate venv, install deps, etc.
  '';
}
```

### Pre-commit Configuration
```yaml
# Standard pre-commit hooks
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
  - repo: https://github.com/ansible/ansible-lint
    rev: v6.14.0
    hooks:
      - id: ansible-lint
```

## Tools and Resources

### Development Tools
- **ibt CLI**: Unified command interface
- **VSCode**: Recommended IDE
- **Git**: Version control
- **Docker**: Containerized tools
- **Make**: Build automation

### Quality Tools
- **pre-commit**: Git hook framework
- **ansible-lint**: Ansible playbook linting
- **yamllint**: YAML file validation
- **shellcheck**: Bash script linting (future)
- **black**: Python code formatting

### Documentation Tools
- **Hugo**: Static site generator
- **Markdown**: Documentation format
- **Mermaid**: Diagram generation
- **PlantUML**: Architecture diagrams

## Documentation Resources

### Internal Documentation
- [Main README](../../README.md)
- [IBT Specification](../../bin/bash/IBT_SPEC.md)
- [Bash Scripts README](../../bin/bash/README.md)
- [AGENTS.md](../../AGENTS.md) - Agent guidelines
- [RELEASE.md](../../RELEASE.md) - Release process

### External Resources
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Pre-commit](https://pre-commit.com/)
- [VSCode](https://code.visualstudio.com/docs)
- [Gitpod](https://www.gitpod.io/docs)

## Best Practices

### Environment Setup
1. **Single Command**: `nix develop` or `ibt setup`
2. **Reproducible**: Same environment for everyone
3. **Fast**: Use caching where possible
4. **Documented**: Clear instructions
5. **Flexible**: Support multiple setup methods

### CLI Design
1. **Consistency**: Predictable command structure
2. **Discoverability**: Good help text and completion
3. **Feedback**: Clear progress and error messages
4. **Testing**: Automated CLI tests
5. **Documentation**: Man pages or equivalents

### Documentation Writing
1. **User-Focused**: Write for the audience
2. **Examples**: Show, don't just tell
3. **Structure**: Use clear headings and sections
4. **Completeness**: Cover all common scenarios
5. **Maintenance**: Keep docs up to date

### Code Quality
1. **Automation**: Use pre-commit hooks
2. **Consistency**: Follow style guides
3. **Reviews**: Peer review all changes
4. **Testing**: Write tests for new features
5. **Security**: Scan for vulnerabilities

## Common Challenges

### Challenge: Complex Setup Process
**Solution**: Nix provides one-command reproducible setup

### Challenge: Tool Version Conflicts
**Solution**: Isolated environments prevent conflicts

### Challenge: Inconsistent Code Style
**Solution**: Automated formatters and linters

### Challenge: Poor Documentation
**Solution**: Documentation as code in version control

### Challenge: Slow Onboarding
**Solution**: Clear getting started guide and examples

## Onboarding Workflow

### Day 1: Environment Setup
```bash
# Clone repository
git clone https://github.com/xNok/infra-bootstrap-tools.git
cd infra-bootstrap-tools

# Setup environment (choose one)
nix develop                    # Nix Flakes (recommended)
source ./bin/bash/ibt.sh      # Bash scripts
# Or use Gitpod for cloud-based setup
```

### Day 1: First Commands
```bash
# Explore the CLI
ibt --help
ibt setup --list-options

# Install tools
ibt setup pre-commit ansible

# List available stacks
ibt stacks list

# Run a local stack
ibt stacks run n8n local
```

### Week 1: Contributing
1. **Read Contributing Guidelines**: Understand the workflow
2. **Make First Change**: Start with documentation
3. **Run Pre-commit**: See code quality tools in action
4. **Create Changeset**: Learn release process
5. **Open PR**: Get feedback on first contribution

## IDE Configuration

### VSCode Recommended Extensions
```json
{
  "recommendations": [
    "redhat.ansible",
    "redhat.vscode-yaml",
    "ms-python.python",
    "ms-azuretools.vscode-docker",
    "jnoortheen.nix-ide",
    "esbenp.prettier-vscode"
  ]
}
```

### VSCode Settings
```json
{
  "editor.formatOnSave": true,
  "editor.rulers": [80, 120],
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml"
  },
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  }
}
```

## Metrics and KPIs

### Onboarding Metrics
- Time to first contribution
- Setup success rate
- Number of onboarding issues reported
- Documentation feedback

### Productivity Metrics
- Average PR cycle time
- Number of CI failures due to formatting
- Tool usage statistics
- Developer satisfaction scores

### Quality Metrics
- Code coverage
- Linting violation trends
- Security vulnerability counts
- Documentation completeness

## Future Improvements

### Short Term
1. Complete Nix migration
2. Add more pre-commit hooks
3. Improve CLI test coverage
4. Create video tutorials
5. Add contributing guidelines

### Medium Term
1. IDE integration packages
2. Development containers (devcontainer)
3. Better error messages
4. Interactive tutorials
5. Automated environment health checks

### Long Term
1. AI-powered code suggestions
2. Automated dependency updates
3. Performance profiling tools
4. Advanced debugging tools
5. Custom VSCode extension

## Related Areas

- **Infrastructure Orchestration**: Uses developer tools
- **AI Workflow Automation**: Benefits from good DX
- **Release Management**: Workflow automation
- **Security & Identity**: Secrets management