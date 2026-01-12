#!/bin/bash
set -euo pipefail

NAMESPACE="monitoring"
RELEASE_NAME="prometheus"
GRAFANA_HOST="${GRAFANA_HOST:-grafana.local}"

# Check prerequisites
check_command() {
  command -v "$1" &>/dev/null
}

# Install k3s
install_k3s() {
  echo "Installing k3s..."
  curl -sfL https://get.k3s.io | sh -
  mkdir -p ~/.kube
  sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
  sudo chown $(id -u):$(id -g) ~/.kube/config
  export KUBECONFIG=~/.kube/config
}

# Install kubectl
install_kubectl() {
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
}

# Install helm
install_helm() {
  echo "Installing helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

# Check and install dependencies
check_command k3s || install_k3s
check_command kubectl || install_kubectl
check_command helm || install_helm

# Verify cluster connection
if ! kubectl cluster-info &>/dev/null; then
  echo "Error: Cannot connect to Kubernetes cluster."
  exit 1
fi

echo "All prerequisites met."

# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace
kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack
helm upgrade --install ${RELEASE_NAME} prometheus-community/kube-prometheus-stack \
  --namespace ${NAMESPACE} \
  --wait

# Create Grafana Ingress with Traefik
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/frontend-entry-points: http,https
    traefik.ingress.kubernetes.io/redirect-entry-point: https
    traefik.ingress.kubernetes.io/redirect-permanent: "true"
  name: grafana-ingress
  namespace: ${NAMESPACE}
spec:
  rules:
  - host: ${GRAFANA_HOST}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${RELEASE_NAME}-grafana
            port:
              number: 80
  tls:
  - hosts:
    - ${GRAFANA_HOST}
    secretName: wildcard-tls-cert
EOF

# Wait for pods
kubectl wait --for=condition=Ready pods --all -n ${NAMESPACE} --timeout=300s || true

# Get Grafana password
GRAFANA_PASSWORD=$(kubectl get secret --namespace ${NAMESPACE} ${RELEASE_NAME}-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo ""
echo "=== Installation Complete ==="
kubectl get pod -o wide -n ${NAMESPACE}
echo ""
echo "Grafana URL: https://${GRAFANA_HOST}"
echo "User: admin"
echo "Password: ${GRAFANA_PASSWORD}"