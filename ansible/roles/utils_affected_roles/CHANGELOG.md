# ansible-role-utils-affected-roles

## 0.0.3

### Patch Changes

- af6e8d6: Fix boolean type coercion in `when` conditions by adding explicit `| bool` filter, ensuring the role behaves correctly regardless of whether variables are passed as strings or native booleans.

## 0.0.2

### Patch Changes

- 356cd1f: Optimize Docker apt package installation and fix CI linting errors in k3s and utils roles.
