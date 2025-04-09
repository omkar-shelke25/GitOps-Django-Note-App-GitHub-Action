# Patch the service to use LoadBalancer type
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get the external IP (wait and retrieve)
echo "Waiting for external IP to be assigned..."
while true; do
    EXTERNAL_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$EXTERNAL_IP" ]; then
        echo "External IP assigned: $EXTERNAL_IP"
        break
    fi
    echo "Still waiting for external IP..."
    sleep 5
done