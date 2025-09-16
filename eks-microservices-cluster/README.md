# EKS Microservices Cluster

## Overview
This project deploys a **production-ready Kubernetes cluster** on AWS using **Amazon Elastic Kubernetes Service (EKS)**.  
It demonstrates how to build a **scalable microservices architecture** using modern DevOps best practices, container orchestration, and AWS-managed services.

The project includes:
- **Infrastructure provisioning** with EKS and AWS networking.
- **Microservices deployment** using Kubernetes manifests.
- **Ingress routing** via AWS Application Load Balancer (ALB).
- **Cluster autoscaling** for dynamic workload scaling.

---

## Architecture
![Architecture Diagram](docs/Kubernetes_Cluster_Architecture.png)

**Workflow:**
1. **User Traffic** enters through an Application Load Balancer (ALB).
2. The ALB routes requests to Kubernetes **Ingress controllers**.
3. **EKS Control Plane** manages the cluster (AWS-managed).
4. **Worker Nodes** run containerized microservices on Amazon EC2 or Fargate.
5. **CloudWatch** and **AWS IAM** provide monitoring and security.

---

## AWS Services Used
- **Amazon EKS** – Managed Kubernetes control plane.
- **Amazon EC2** – Worker nodes running containerized workloads.
- **Amazon VPC** – Isolated, secure networking environment.
- **Elastic Load Balancer (ALB)** – External routing to services.
- **AWS IAM** – Role-based access control for Kubernetes and AWS services.
- **Amazon CloudWatch** – Logs and metrics for monitoring cluster health.
- **Amazon ECR** – Private container image repository.

---

## Tools Used
- **kubectl** – Kubernetes CLI for managing resources.
- **eksctl** – Simplifies EKS cluster creation and management.
- **Docker** – Containerization of microservices.
- **Helm (optional)** – Kubernetes package manager for complex deployments.
- **Terraform (optional)** – Infrastructure as Code alternative to `eksctl`.

---

## Folder Structure
eks-microservices-cluster/
│
├── k8s-manifests/ # Kubernetes manifests for microservices
│ ├── deployments/
│ │ └── app-deployment.yaml
│ ├── services/
│ │ └── app-service.yaml
│ └── ingress/
│ └── ingress.yaml
│
├── scripts/ # Helper scripts for setup and cleanup
│ └── cleanup.sh
│
├── docs/
│ └── architecture.png # Architecture diagram
│
└── README.md

---

## Deployment Instructions

### **1. Clone the Repository**
```bash
git clone https://github.com/deanwbusch-prog/eks-microservices-cluster.git
cd eks-microservices-cluster

2. Configure AWS CLI
Make sure your AWS CLI is set up for us-west-1:
aws configure
Enter:
AWS Access Key ID: Your key
AWS Secret Access Key: Your secret
Default region name: us-west-1
Default output format: json

3. Create the EKS Cluster
Using eksctl (recommended):
eksctl create cluster \
  --name eks-microservices \
  --region us-west-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3
This will:
Provision the control plane (AWS-managed).
Create a node group of EC2 worker nodes.
Set up networking and IAM roles automatically.

4. Update kubeconfig
Link your local kubectl to the new cluster:
aws eks update-kubeconfig --region us-west-1 --name eks-microservices

5. Verify Cluster
Check cluster connectivity:
kubectl get nodes
You should see all worker nodes in Ready status.

6. Deploy Microservices
Apply your Kubernetes manifests:
kubectl apply -f k8s-manifests/deployments/
kubectl apply -f k8s-manifests/services/
kubectl apply -f k8s-manifests/ingress/

7. Verify Resources
kubectl get pods
kubectl get services
kubectl get ingress

8. Test Access
Once the ALB is provisioned, AWS will display a DNS name.
Access it in your browser:
http://<ALB-DNS-Name>

9. Cleanup Resources
When finished, clean up to avoid AWS charges:
eksctl delete cluster --name eks-microservices --region us-west-1
Or manually delete:
kubectl delete -f k8s-manifests/
Security Considerations
Use IAM least privilege for all cluster roles.

Enable VPC CNI plugin for secure pod networking.
Use Secrets Manager or Kubernetes secrets for sensitive data.
Enable CloudWatch logs for cluster auditing.
Consider network policies for pod-to-pod security.

Future Enhancements
Add Helm charts for easier deployment management.
Integrate CI/CD pipeline with GitHub Actions.
Enable Fargate for serverless Kubernetes workloads.
Add Prometheus and Grafana for monitoring and visualization.
Implement HPA (Horizontal Pod Autoscaler) for dynamic scaling.

License
This project is licensed under the MIT License.
