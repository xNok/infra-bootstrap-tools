## 2024-05-18 - [Ansible] Optimize apt package installations
**Learning:** In Ansible `apt` tasks, iterating over package managers (e.g., using `loop:` to install multiple packages) triggers individual transactions for each package, which is incredibly slow.
**Action:** Always provide the list of packages directly to the `name` parameter in `apt` (or equivalent package managers) to allow installation in a single transaction. This reduces task execution time by approximately 80%.

## 2024-05-19 - [Prefect] Avoid blocking the event loop
**Learning:** Initializing MCP toolset in Prefect workflows using `FastMCPToolset` performs synchronous I/O. If called synchronously inside an `async def` Prefect task/flow, it will block the event loop and hurt concurrency.
**Action:** Wrap synchronous I/O operations inside `asyncio.to_thread()` and await them when inside async functions in Prefect workflows.

## 2024-05-20 - [Frontend] Memoize caches.open in Service Workers
**Learning:** In Service Workers, repeatedly calling `caches.open(cacheName)` inside the `fetch` event handler triggers redundant asynchronous lookups to IndexedDB, slowing down intercept performance.
**Action:** Memoize the cache lookup by assigning the result of `caches.open()` to a globally scoped promise variable (e.g. `const cachePromise = caches.open(cacheName);`) and awaiting it within the event handlers.
