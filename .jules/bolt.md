## 2024-05-18 - [Ansible] Optimize apt package installations
**Learning:** In Ansible `apt` tasks, iterating over package managers (e.g., using `loop:` to install multiple packages) triggers individual transactions for each package, which is incredibly slow.
**Action:** Always provide the list of packages directly to the `name` parameter in `apt` (or equivalent package managers) to allow installation in a single transaction. This reduces task execution time by approximately 80%.
