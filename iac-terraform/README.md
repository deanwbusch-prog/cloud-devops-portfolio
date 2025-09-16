# Infrastructure as Code (IaC) with Terraform

## Overview
This project demonstrates how to **provision AWS resources using Terraform** in a secure, scalable, and automated way.  
It showcases how Infrastructure as Code (IaC) enables repeatable deployments and consistent cloud environments, which are essential skills for modern DevOps and cloud engineers.

This project uses Terraform to create core AWS infrastructure including:
- Virtual Private Cloud (VPC)
- Subnets
- Security Groups
- EC2 instances
- S3 buckets
- IAM roles and policies

By managing everything as code, this setup can be quickly deployed, destroyed, or modified through version-controlled Terraform files.

---

## Architecture
![Architecture Diagram](docs/Infrastructure-as-Code_Architecture.png)

**Workflow:**
1. Developer writes Terraform code and commits it to GitHub.
2. Terraform CLI initializes and plans infrastructure changes.
3. Terraform applies the plan and provisions resources on AWS.
4. AWS services are created and managed automatically.

---

## AWS Services Managed
- **Amazon VPC** – Creates private, secure networking for AWS resources.
- **Amazon EC2** – Launches compute instances inside the VPC.
- **Amazon S3** – Stores state files, logs, and static assets.
- **AWS IAM** – Manages secure permissions and roles for services.
- **Amazon CloudWatch** – Monitors deployed resources.
- **Security Groups** – Controls inbound and outbound traffic.

---

## Tools Used
- **Terraform** – Multi-cloud infrastructure provisioning.
- **AWS CLI** – Interacting with AWS services directly.
- **GitHub** – Version control for Terraform configurations.
- **Visual Studio Code (VS Code)** – Code editing and project management.

---

## Folder Structure
iac-terraform/
│
├── main.tf # Main Terraform configuration
├── variables.tf # Input variables
├── outputs.tf # Output values after deployment
├── provider.tf # AWS provider configuration
├── modules/ # Reusable Terraform modules
│ ├── vpc/
│ │ ├── main.tf
│ │ ├── variables.tf
│ │ └── outputs.tf
│ └── ec2/
│ ├── main.tf
│ ├── variables.tf
│ └── outputs.tf
├── docs/
│ └── architecture.png # Architecture diagram
└── README.md

---

## Deployment Instructions

### **1. Clone the Repository**
```bash
git clone https://github.com/deanwbusch-prog/iac-terraform.git
cd iac-terraform

2. Configure AWS CLI
Make sure your AWS CLI is set up for the us-west-1 region:
aws configure
AWS Access Key ID: Your AWS Access Key
AWS Secret Access Key: Your AWS Secret Key
Default region name: us-west-1
Default output format: json

3. Initialize Terraform
Initialize the project to download required Terraform providers and modules.
terraform init

4. Validate Configuration
Ensure that the Terraform code is valid and there are no syntax errors.
terraform validate

5. Plan Infrastructure
Review the resources that Terraform will create.
terraform plan

6. Apply Infrastructure
Provision the AWS resources defined in the configuration.
terraform apply
Type yes when prompted to confirm the deployment.

7. Verify Resources in AWS
Go to the AWS Console and check:
VPC: Confirm VPC and subnets are created.
EC2: Verify instances are running.
S3: Ensure bucket is present.
IAM: Check that roles and policies are configured correctly.

8. Destroy Infrastructure
When finished testing, clean up all AWS resources:
terraform destroy
Security Considerations
IAM least privilege – Only minimal permissions granted to Terraform.
Terraform state file – Stored securely in S3 (remote backend recommended).
Version control – GitHub tracks changes to prevent misconfigurations.
Environment separation – Use separate workspaces for dev, test, and production.

Future Enhancements
Add remote backend with S3 and DynamoDB for secure state management.
Implement CI/CD pipeline using GitHub Actions or AWS CodePipeline.
Add CloudFormation templates for comparison.
Deploy multi-region architectures for high availability.
Integrate monitoring and alerts using CloudWatch metrics and alarms.

License
This project is licensed under the MIT License.
