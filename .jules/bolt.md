## 2024-05-18 - [Ansible] Optimize apt package installations
**Learning:** In Ansible `apt` tasks, iterating over package managers (e.g., using `loop:` to install multiple packages) triggers individual transactions for each package, which is incredibly slow.
**Action:** Always provide the list of packages directly to the `name` parameter in `apt` (or equivalent package managers) to allow installation in a single transaction. This reduces task execution time by approximately 80%.

## 2024-05-19 - [Prefect] Avoid blocking the event loop
**Learning:** Initializing MCP toolset in Prefect workflows using `FastMCPToolset` performs synchronous I/O. If called synchronously inside an `async def` Prefect task/flow, it will block the event loop and hurt concurrency.
**Action:** Wrap synchronous I/O operations inside `asyncio.to_thread()` and await them when inside async functions in Prefect workflows.
