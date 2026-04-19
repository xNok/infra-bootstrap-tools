---
"ansible-role-utils-affected-roles": patch
---

Fix boolean type coercion in `when` conditions by adding explicit `| bool` filter, ensuring the role behaves correctly regardless of whether variables are passed as strings or native booleans.
