# Use Cases for Testing `stacks_tools_alias.sh`

Below are some practical test cases to validate the script's functionality:

## 1. List all available stacks
```bash
list_stacks
```
Expected: Prints a list of all stack names found in the stacks directory.

## 2. Run a basic stack
```bash
run_stack n8n
```
Expected: Runs the `n8n.yaml` stack file with Docker Compose.

## 3. Run a stack with local override
```bash
run_stack n8n local
```
Expected: Runs the `n8n.local.yaml` file if it exists, otherwise falls back to `n8n.yaml`.

## 4. Run a stack with components
```bash
run_stack n8n worker web
```
Expected: Runs `n8n.yaml`, `n8n.worker.yaml`, and `n8n.web.yaml` (if they exist).

## 5. Run a stack with components and local override
```bash
run_stack n8n worker web local
```
Expected: Prefers `n8n.local.yaml`, `n8n.worker.local.yaml`, and `n8n.web.local.yaml` if they exist, otherwise uses the non-local versions.

## 6. Show help
```bash
help_stacks
```
Expected: Prints usage instructions and examples.

---

For more details, see the README in this folder.
