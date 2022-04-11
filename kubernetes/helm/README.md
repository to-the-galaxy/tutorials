# Helm

A package manager for kubernetes.

```bash
# List installed charts
helm list
helm list -a --all-namespaces

# Delete chart/release
helm delete <name-of-chart-or-release>
helm delete my-prometheus

# Get values
helm get values <release_name> <flags>
#   -a, --all             dump all (computed) values
#   -h, --help            help for values
#   -o, --output format   prints the output in the specified format. Allowed values: table, json, yaml (default table)
#       --revision int    get the named release with revision
# Examples
helm get values my-longhorn -n longhorn-system -o yaml
helm get values my-longhorn -n longhorn-system --all -o yaml
```