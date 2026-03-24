kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:__REGISTRY_PORT__"]
      endpoint = ["http://__REGISTRY_NAME__:5000"]
nodes:
  - role: control-plane
