# ─── Kubernetes helpers ──────────────────────────────────
function klogs -d "Follow pod logs"
    kubectl logs -f $argv
end

function kexec -d "Exec into a pod"
    kubectl exec -it $argv -- /bin/sh
end

function kns -d "Switch namespace"
    kubectl config set-context --current --namespace=$argv[1]
end
