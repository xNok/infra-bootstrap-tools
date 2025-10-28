# IBT Command Specification

## Overview

`ibt` (Infra Bootstrap Tools) is a unified command-line interface for managing infrastructure bootstrap tools. It provides a consistent interface for wrapping various tools and offering bash completion.

## Core Principles

1. **Tool Wrapping**: ibt focuses on wrapping existing tools and providing a consistent interface
2. **Dynamic Completion**: Completion data should be fetched from the actual scripts, not hardcoded
3. **Extensibility**: New subcommands should be easy to add without modifying multiple files
4. **DRY (Don't Repeat Yourself)**: Shared functionality should be extracted into reusable utilities

## Command Structure

```
ibt <subcommand> [options...]
```

### Subcommands

- `setup` - Install required tools and dependencies
- `stacks` - Manage and run infrastructure stacks  
- `tools` - Use Docker-based aliases for infrastructure tools

## Subcommand Interface Contract

Each subcommand script MUST implement:

1. **Options Listing**: When called with `--list-options`, the script must output its available options, one per line
2. **Help**: Support `-h`, `--help`, or `help` to show usage information
3. **Completion Function**: Provide a completion function named `_<subcommand>_completion`

### Example Implementation

```bash
#!/usr/bin/env bash

# Provide options list for completion
if [[ "$1" == "--list-options" ]]; then
  echo "option1"
  echo "option2"
  echo "option3"
  exit 0
fi

# Rest of script implementation...
```

## Completion System

### Architecture

The completion system follows a hierarchical structure:

1. **ibt-completion.sh**: Main completion handler for the `ibt` command
   - Completes subcommand names (setup, stacks, tools)
   - Delegates to subcommand-specific completion functions

2. **<subcommand>-completion.sh**: Subcommand-specific completion
   - Fetches options dynamically from the subcommand script using `--list-options`
   - Uses shared utility functions to avoid duplication

### Shared Utilities

`bin/bash/completion-utils.sh` provides:
- `_ibt_generic_completion()`: Generic completion function that works with any script supporting `--list-options`
- Common completion helper functions

## Extension Guidelines

To add a new subcommand:

1. Create `<subcommand>.sh` script that:
   - Implements `--list-options` flag
   - Provides help text
   - Implements the subcommand logic

2. Create `<subcommand>-completion.sh` that:
   - Sources `completion-utils.sh`
   - Defines `_<subcommand>_completion` using `_ibt_generic_completion`

3. Update `ibt.sh`:
   - Add case branch for new subcommand
   - Update main completion to delegate to new subcommand

4. Update documentation in README.md

## Design Rationale

This specification ensures:
- **Maintainability**: Changes to options only require updating one place
- **Consistency**: All subcommands follow the same patterns
- **Testability**: Each component can be tested independently
- **Clarity**: Clear contracts between components
