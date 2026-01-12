# Install Monitoring on Kubernetes via Script

A bash script that automatically installs a complete monitoring stack on Kubernetes using k3s, Prometheus, and Grafana.

## Overview

This script sets up:
- **k3s** - Lightweight Kubernetes distribution
- **Prometheus** - Monitoring and alerting system
- **Grafana** - Visualization dashboard
- **Traefik** - Ingress controller for external access

## Prerequisites

- Linux system (script installs Linux binaries)
- sudo privileges for installation
- Internet connection for downloading dependencies

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/1-thegreenprogrammer/Install-monitoring-on-Kubernetes-via-script-bash.git
cd Install-monitoring-on-Kubernetes-via-script-bash
```

2. Run the installation script:
```bash
chmod +x install.bash
./install.bash
```

3. Access Grafana:
- URL: `https://grafana.local` (or your custom `GRAFANA_HOST`)
- Username: `admin`
- Password: Displayed at the end of installation

## Configuration

### Environment Variables

- `GRAFANA_HOST` - Custom hostname for Grafana (default: `grafana.local`)

Example:
```bash
export GRAFANA_HOST=monitoring.mydomain.com
./install.bash
```

### Default Settings

- **Namespace**: `monitoring`
- **Helm Release**: `prometheus`
- **Timeout**: 300 seconds for pod readiness

## What Gets Installed

### Dependencies
- k3s (if not found)
- kubectl (if not found)
- helm (if not found)

### Kubernetes Components
- kube-prometheus-stack Helm chart
- Grafana with Traefik ingress
- Prometheus monitoring
- AlertManager
- Node Exporter

### Network Configuration
- Traefik ingress controller
- HTTPS redirection
- TLS support (requires `wildcard-tls-cert` secret)

## Post-Installation

After installation completes, the script will display:
- Pod status in the monitoring namespace
- Grafana URL
- Admin credentials

### Verify Installation
```bash
kubectl get pods -n monitoring
kubectl get ingress -n monitoring
```

### Access Services
- **Grafana**: `https://<GRAFANA_HOST>`
- **Prometheus**: Via port-forward: `kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090`

## Troubleshooting

### Common Issues

1. **Cluster Connection Error**
   - Ensure k3s is running: `sudo systemctl status k3s`
   - Check kubeconfig: `export KUBECONFIG=~/.kube/config`

2. **Pods Not Ready**
   - Check pod status: `kubectl get pods -n monitoring`
   - View logs: `kubectl logs -n monitoring <pod-name>`

3. **Grafana Access Issues**
   - Verify ingress: `kubectl get ingress -n monitoring`
   - Check DNS resolution for `GRAFANA_HOST`
   - Add entry to `/etc/hosts` if needed: `127.0.0.1 grafana.local`

### Cleanup
```bash
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
sudo k3s-uninstall.sh
```

## Architecture

```
Internet
    ↓
Traefik Ingress
    ↓
Grafana Service
    ↓
Prometheus Stack
    ↓
Kubernetes Cluster (k3s)
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source. Please check the license file for details.

## Support

For issues and questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section above
