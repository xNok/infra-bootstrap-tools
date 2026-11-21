# kubernetes-apps

## 0.2.4

### Patch Changes

- 7d70484: Add OpenCode Go provider (`OPENCODE_API_KEY`) and Google Generative AI (`GOOGLE_GENERATIVE_AI_API_KEY`) credentials to tenant agent templates.
- 42069b7: Migrate KubeOpenCode fleet and tenant agent templates to the Single Router Key pattern (`OPENCODE_API_KEY` only) routed through OpenCode AI Gateway, removing direct Google API secrets from Kubernetes.

## 0.2.3

### Patch Changes

- a27cc6f: add kubeopencode-agent runtime ServiceAccount and scoped RBAC to ResourceSet factory, and configure tenant namespace Pod Security Standard enforcement to baseline

## 0.2.2

### Patch Changes

- ed0f857: feat(tenants): wire live GitHub App bot identity and fix AgentTemplate extraEnv schema

## 0.2.1

### Patch Changes

- 9b08d8c: Update `palette-agent` model default from `anthropic/claude-3-7-sonnet` to `google/gemini-flash-lite-latest`.

## 0.2.0

### Minor Changes

- bf4713d: Introduce shared `kubernetes-apps` catalogue including KubeOpenCode platform controller and Palette UX & Accessibility Agent.
