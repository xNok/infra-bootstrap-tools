# main - CI Policies

Policies enforcing CI/CD conventions and best practices.

## main.deny - Prevent Multiline Inline Scripts

Denies any run step that contains a newline, suggesting it is a multiline inline script. All multi-line scripts should be extracted to dedicated files.

## main.deny - No Inline Scripts

Denies any inline multi-line scripts across all jobs and steps. Scripts must be moved to bin/ci and run as a single line command.
