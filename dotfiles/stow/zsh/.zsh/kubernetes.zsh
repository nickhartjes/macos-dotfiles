# Kubernetes log helpers
klogs() {
  kubectl logs -f "$@"
}

kexec() {
  kubectl exec -it "$@" -- /bin/sh
}

# Switch namespace quickly
kns() {
  kubectl config set-context --current --namespace="$1"
}
