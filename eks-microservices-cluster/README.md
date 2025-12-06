# EKS Microservices on AWS

A complete, production-ready Kubernetes microservices cluster deployed on AWS EKS. This project demonstrates cloud-native DevOps practices, containerization, orchestration, autoscaling, and load balancing on AWS.

## 🎯 Project Overview

This project deploys a simple but realistic microservices architecture:
- **Frontend**: NGINX static site served on port 80
- **Backend**: Node.js Express API on port 3000
- **Infrastructure**: AWS EKS cluster with managed node groups, private ECR registry, ALB Ingress, and HPA autoscaling

The frontend service calls the backend via Kubernetes DNS networking, and both are exposed to the internet through an AWS Application Load Balancer.

**Architecture:** Internet → ALB → Frontend (NGINX) → Backend (Node.js) ← ECR (image registry)

---

## 🏗️ Architecture

![Architecture Diagram](docs/Kubernete_Cluster_Architecture.png)

```
Internet
   ↓
AWS Application Load Balancer (ALB)
   ↓
EKS Cluster (us-east-2)
├── Namespace: app
│   ├── Frontend Deployment (2 replicas, NGINX)
│   │   ├── Pod: frontend-xxx
│   │   └── Pod: frontend-yyy
│   ├── Backend Deployment (2-6 replicas with HPA, Node.js)
│   │   ├── Pod: backend-aaa
│   │   ├── Pod: backend-bbb
│   │   └── ... (scales up to 6)
│   ├── Service: frontend (ClusterIP, port 80)
│   ├── Service: backend (ClusterIP, port 3000)
│   ├── Ingress: app-ingress (triggers ALB)
│   └── HPA: backend-hpa (CPU > 50% triggers scaling)
├── Add-ons
│   ├── EBS CSI Driver (persistent volumes)
│   ├── Metrics Server (CPU/memory monitoring)
│   └── AWS Load Balancer Controller (Ingress → ALB)
└── Worker Nodes (3x t3.medium EC2 instances)

AWS ECR (Elastic Container Registry)
├── backend:latest, backend:v1, ...
└── frontend:latest, frontend:v3, ...
```

See `EKS-Architecture.drawio` for a visual diagram (import into [draw.io](https://draw.io)).

---

## 📋 Prerequisites

### Local Setup
- **Windows 11** with WSL 2 enabled
- **AWS Account** with appropriate IAM permissions
- **AWS CLI** configured with SSO profile
- **kubectl** (Kubernetes CLI)
- **eksctl** (EKS cluster management)
- **Docker Desktop** (local image builds)
- **Helm** (Kubernetes package manager)

### AWS Setup
- AWS account in **us-east-2** region (adjust as needed)
- AWS SSO profile configured: `eks-microservices`
- Permissions: EKS, EC2, IAM, ECR, VPC, ALB, AutoScaling, EBS

---

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/eks-microservices.git
cd eks-microservices
```

### 2. Authenticate to AWS
```powershell
aws sso login --profile eks-microservices
# A browser opens; authenticate with your SSO provider
```

### 3. Build & Push Container Images to ECR
```powershell
# Create ECR repositories (one-time setup)
aws ecr create-repository --repository-name backend --region us-east-2 --profile eks-microservices
aws ecr create-repository --repository-name frontend --region us-east-2 --profile eks-microservices

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-2 --profile eks-microservices `
  | docker login --username AWS --password-stdin 617291204273.dkr.ecr.us-east-2.amazonaws.com

# Build backend image
cd docker/backend
docker build -t backend:latest .
docker tag backend:latest 617291204273.dkr.ecr.us-east-2.amazonaws.com/backend:latest
docker push 617291204273.dkr.ecr.us-east-2.amazonaws.com/backend:latest

# Build frontend image
cd ../frontend
docker build -t frontend:latest .
docker tag frontend:latest 617291204273.dkr.ecr.us-east-2.amazonaws.com/frontend:v3
docker push 617291204273.dkr.ecr.us-east-2.amazonaws.com/frontend:v3
```

### 4. Create EKS Cluster
```powershell
eksctl create cluster -f k8s-manifests/cluster-config.yaml --profile eks-microservices
# Takes ~15 minutes. Creates VPC, nodes, security groups, IAM roles.
```

### 5. Install Kubernetes Add-ons

**EBS CSI Driver** (persistent storage):
```bash
eksctl create addon --cluster eks-microservices --name aws-ebs-csi-driver --region us-east-2 --profile eks-microservices
```

**Metrics Server** (CPU/memory monitoring):
```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm install metrics-server metrics-server/metrics-server -n kube-system
```

**AWS Load Balancer Controller** (Ingress → ALB):
```bash
# Create IAM role (IRSA: IAM Roles for Service Accounts)
eksctl create iamserviceaccount \
  --cluster=eks-microservices \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --region us-east-2 \
  --profile eks-microservices \
  --approve

# Install controller via Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 6. Deploy Application
```powershell
# Create app namespace
kubectl create namespace app

# Deploy backend
kubectl apply -f k8s-manifests/deployments/backend-deployment.yaml
kubectl apply -f k8s-manifests/services/backend-service.yaml

# Deploy frontend
kubectl apply -f k8s-manifests/deployments/frontend-deployment.yaml
kubectl apply -f k8s-manifests/services/frontend-service.yaml

# Create Ingress (triggers ALB creation)
kubectl apply -f k8s-manifests/ingress/app-ingress.yaml
```

### 7. Access Application
```bash
# Get ALB DNS name
kubectl get ingress -n app
# Example output:
# NAME          CLASS   HOSTS   ADDRESS                                             PORTS   AGE
# app-ingress   alb     *       k8s-app-appingre-2d7464bd2a-1082385559.us-east-2.elb.amazonaws.com   80      2m

# Open in browser
open http://k8s-app-appingre-2d7464bd2a-1082385559.us-east-2.elb.amazonaws.com
```

Click "Ping Backend" button; it should display: `{"message":"Hello from backend on EKS"}`

---

## 📊 Enable Autoscaling (HPA)

Create a Horizontal Pod Autoscaler for the backend:

```powershell
kubectl apply -f k8s-manifests/hpa/backend-hpa.yaml
```

Monitor scaling:
```bash
kubectl get hpa -n app --watch
kubectl top pods -n app  # Monitor CPU usage
```

### Load Test
Generate traffic to trigger scaling:
```bash
# Install hey (HTTP load tool)
choco install hey

# Run load test against frontend
hey -n 10000 -c 100 http://<ALB-DNS>/

# In another terminal, watch scaling
kubectl get pods -n app --watch
kubectl get hpa -n app --watch
```

You should see backend replicas scale from 2 → 3 → 4 → 5 → 6 as CPU usage increases.

---

## 📁 Project Structure

```
eks-microservices/
├── docker/
│   ├── backend/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── server.js
│   └── frontend/
│       ├── Dockerfile
│       └── index.html
├── k8s-manifests/
│   ├── cluster-config.yaml
│   ├── deployments/
│   │   ├── backend-deployment.yaml
│   │   └── frontend-deployment.yaml
│   ├── services/
│   │   ├── backend-service.yaml
│   │   └── frontend-service.yaml
│   ├── ingress/
│   │   └── app-ingress.yaml
│   └── hpa/
│       └── backend-hpa.yaml
├── EKS-Study-Guide.md
├── EKS-Architecture.drawio
└── README.md (this file)
```

---

## 🔧 Key Commands

### Cluster Management
```bash
# View cluster info
kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide

# View resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# View all resources
kubectl get all -n app
```

### Pod Management
```bash
# List pods
kubectl get pods -n app
kubectl get pods -n app -o wide

# View pod logs
kubectl logs -n app <pod-name>
kubectl logs -n app <pod-name> --tail=50 -f  # Follow logs

# Exec into pod
kubectl exec -n app <pod-name> -- sh
kubectl exec -n app <pod-name> -- cat /usr/share/nginx/html/index.html  # Frontend HTML

# Describe pod
kubectl describe pod -n app <pod-name>
```

### Service & Ingress
```bash
# List services
kubectl get svc -n app
kubectl describe svc backend -n app

# List ingress
kubectl get ingress -n app
kubectl describe ingress app-ingress -n app

# Test service connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -n app -- wget -O- http://backend:3000/api/message
```

### Deployment Management
```bash
# Rollout status
kubectl rollout status deploy/backend -n app
kubectl rollout restart deploy/frontend -n app

# View deployment history
kubectl rollout history deploy/backend -n app

# Rollback deployment
kubectl rollout undo deploy/backend -n app
```

### Debugging
```bash
# Get deployment events
kubectl describe deploy backend -n app

# Check HPA status
kubectl get hpa -n app
kubectl describe hpa backend-hpa -n app

# View resource quotas
kubectl describe quota -n app

# Check API server connectivity
kubectl api-resources
```

---

## 🧹 Cleanup

### Delete Kubernetes Resources
```bash
# Delete all resources in app namespace
kubectl delete namespace app

# Or delete individual resources
kubectl delete deploy backend frontend -n app
kubectl delete svc backend frontend -n app
kubectl delete ingress app-ingress -n app
kubectl delete hpa backend-hpa -n app
```

### Delete EKS Cluster
```bash
# Warning: This deletes the entire cluster, nodes, and associated AWS resources
eksctl delete cluster --name eks-microservices --region us-east-2 --profile eks-microservices
# Takes ~10 minutes
```

### Delete ECR Repositories
```bash
aws ecr delete-repository --repository-name backend --region us-east-2 --profile eks-microservices --force
aws ecr delete-repository --repository-name frontend --region us-east-2 --profile eks-microservices --force
```

---

## 💡 Key Concepts & Learning

### Kubernetes Objects

| Object | Purpose |
|--------|---------|
| **Pod** | Smallest unit; wrapper for container(s). Ephemeral. |
| **Deployment** | Manages Pods; ensures replicas stay running. |
| **Service** | Stable network endpoint; routes traffic to Pods. |
| **Ingress** | Routes external HTTP/HTTPS traffic to Services. |
| **Namespace** | Logical cluster isolation. |
| **HPA** | Horizontal Pod Autoscaler; scales Pods based on metrics. |
| **ConfigMap** | Key-value config data. |
| **Secret** | Key-value secrets (encrypted). |

### AWS Integration

| Component | Purpose |
|-----------|---------|
| **EKS** | Managed Kubernetes control plane. |
| **ECR** | Private container image registry. |
| **ALB** | Application Load Balancer; routes traffic from internet. |
| **IAM** | Identity & access management; RBAC for pods. |
| **VPC** | Virtual private cloud; networking. |
| **EC2** | Worker node instances. |
| **EBS** | Block storage for persistent volumes. |

### Networking Flow

```
Internet Request
   ↓ (port 80)
AWS ALB (receives request)
   ↓
ALB Controller watches Ingress, routes to Service
   ↓
Frontend Service (ClusterIP)
   ↓ (kube-proxy load balances)
Frontend Pods (NGINX)
   ↓
Pod calls Backend via DNS: backend.app.svc.cluster.local:3000
   ↓
Backend Service (ClusterIP)
   ↓
Backend Pods (Node.js)
   ↓
Response sent back through the chain
```

### Autoscaling with HPA

1. **Metrics Server** collects CPU/memory from nodes and Pods.
2. **HPA** queries metrics every 15 seconds.
3. If average CPU > 50%, HPA scales Replicas up (add Pods).
4. If average CPU < 50%, HPA scales Replicas down (remove Pods).
5. Min replicas: 2, Max replicas: 6 (configurable).

---

## 🔒 Security Considerations

- **IAM**: Uses IRSA (IAM Roles for Service Accounts) so Pods assume AWS roles without storing keys.
- **Private ECR**: Images stored in private registry; only authenticated cluster can pull.
- **Network Policy**: Can add Kubernetes NetworkPolicy to restrict Pod-to-Pod traffic (not in this basic project).
- **TLS**: In production, use HTTPS (ACM certificate + TLS Ingress).
- **Secrets**: Never commit AWS credentials or secrets to Git. Use AWS Secrets Manager or `kubectl create secret`.

---

## 📖 Further Reading

### Included Documentation
- **EKS-Study-Guide.md**: Ultra-detailed explanation of every concept and step.
- **EKS-Architecture.drawio**: Architecture diagram (import into draw.io).

### Official Resources
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [eksctl Documentation](https://eksctl.io/)
- [Helm Documentation](https://helm.sh/docs/)

### Recommended Learning
- **Kubernetes Fundamentals**: Pods, Deployments, Services, Ingress.
- **AWS Core Services**: IAM, VPC, EC2, ECS, EKS.
- **Container Best Practices**: Multi-stage builds, minimal base images, health checks.
- **DevOps**: Infrastructure as Code (IaC), CI/CD pipelines, monitoring.

---

## 🐛 Troubleshooting

### Frontend shows NGINX 404
- **Cause**: Frontend HTML outdated or image tag mismatch.
- **Solution**: Rebuild frontend image, push new tag, update Deployment, wait for rollout, hard-refresh browser.

### Pods stuck in "Pending"
- **Cause**: Not enough CPU/memory on nodes, or nodes not ready.
- **Solution**: Check node status (`kubectl get nodes`), add more nodes, or reduce Pod resource requests.

### Cannot connect to backend from frontend
- **Cause**: DNS not resolving, Service not created, or firewall blocking.
- **Solution**: Verify Service exists (`kubectl get svc`), test DNS (`kubectl exec ... nslookup backend`), check Deployment logs.

### HPA not scaling
- **Cause**: Metrics Server not running, or load not high enough.
- **Solution**: Check Metrics Server (`kubectl get pods -n kube-system`), verify load generation, check HPA status (`kubectl describe hpa`).

### ALB Ingress not getting DNS
- **Cause**: ALB Controller not running, or Ingress annotations incorrect.
- **Solution**: Check ALB Controller (`kubectl get pods -n kube-system`), verify Ingress YAML, wait 2–3 minutes.

---

## 📝 Notes

- **Region**: Project uses `us-east-2`. Adjust `cluster-config.yaml` and AWS CLI commands for other regions.
- **Account ID**: Replace `617291204273` with your AWS account ID throughout.
- **Cost**: t3.medium instances (~$0.04/hour each) + ALB (~$16/month) + data transfer. Estimated **$50–100/month** for this project running continuously.
- **Autoscaling**: Backend HPA scales to 6 replicas max; adjust in `backend-hpa.yaml` if needed.

---

## 👤 Author

Built as a comprehensive cloud-native DevOps portfolio project demonstrating:
- Kubernetes cluster setup and management
- Container image creation and registry (ECR) integration
- AWS infrastructure (IAM, VPC, ALB, EC2, EBS)
- Microservices architecture and networking
- Autoscaling and monitoring
- Infrastructure as Code (YAML manifests)

---

## 📄 License

This project is open-source and available for educational and portfolio purposes.

---

## 🙌 Acknowledgments

- AWS documentation and best practices
- Kubernetes community and CNCF
- eksctl for simplifying EKS cluster provisioning
- Helm for Kubernetes package management

---

**Last Updated:** December 2025
