# Serverless To-Do App

## Overview
This project is a fully serverless web application built on AWS that allows users to securely manage their tasks with full CRUD (Create, Read, Update, Delete) functionality.  

The architecture is designed for **scalability**, **low operational cost**, and **ease of management** by using AWS managed services.  
This app demonstrates cloud-native development skills in serverless design and is ideal for showcasing modern AWS best practices.

---

## Architecture
![Architecture Diagram](docs/Serverless_Application_Architecture.png)

**Workflow**
1. **User Authentication** – Amazon Cognito handles user registration, login, and secure authentication.  
2. **API Routing** – Amazon API Gateway acts as the front door for all HTTP requests.  
3. **Business Logic** – AWS Lambda executes the backend functions for CRUD operations.  
4. **Data Storage** – Amazon DynamoDB stores tasks in a scalable NoSQL database.  
5. **Frontend Hosting** – A static web app hosted on Amazon S3 and distributed globally via Amazon CloudFront.  

---

## AWS Services Used
- **Amazon Cognito** – User sign-up and sign-in with JWT authentication.  
- **Amazon API Gateway** – REST API endpoints.  
- **AWS Lambda** – Compute for backend logic.  
- **Amazon DynamoDB** – NoSQL database for tasks.  
- **Amazon S3** – Static hosting for frontend files.  
- **Amazon CloudFront** – Content delivery network (CDN).  
- **Amazon CloudWatch** – Monitoring, logs, and alarms.  
- **AWS IAM** – Secure role-based permissions.  

---

## Features
- User registration and login with Cognito.  
- CRUD operations on tasks.  
- Fully serverless, pay-as-you-go infrastructure.  
- Scales automatically with no manual server management.  
- Global delivery with low latency.  

---

## Folder Structure
serverless-todo-app/
│
├── backend/
│ ├── functions/ # Lambda functions
│ ├── templates/ # AWS SAM templates
│ └── requirements.txt
│
├── frontend/
│ ├── index.html
│ ├── css/
│ └── js/
│
├── docs/
│ └── Serverless_Application_Architecture.png
│
└── README.md

---

## Deployment Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/deanwbusch-prog/serverless-todo-app.git
cd serverless-todo-app
2. Configure AWS CLI
aws configure
Default region: us-west-1

3. Deploy Backend (SAM)
cd backend
sam build
sam deploy --guided
Record outputs:
API Gateway endpoint URL
Cognito User Pool ID + App Client ID
Identity Pool ID
DynamoDB table name

4. Deploy Frontend
aws s3 mb s3://serverless-todo-app-frontend-us-west-1
aws s3 sync ./frontend s3://serverless-todo-app-frontend-us-west-1 --delete
Block all public access.
Create a CloudFront distribution with S3 as the origin.
Save CloudFront domain name (e.g., https://d1234abcd.cloudfront.net).

5. Configure Frontend
Edit frontend/js/auth.js with your Cognito IDs.
Edit frontend/js/api.js with your API Gateway URL.

Usage
Open CloudFront domain in browser.
Register/login via Cognito.
Add, update, and delete tasks.

Security
Cognito protects API endpoints with JWT tokens.
IAM roles use least-privilege access (Lambda only has DynamoDB read/write).
CloudFront Origin Access Identity (OAI) secures S3 bucket.

Monitoring
CloudWatch Logs: Lambda and API Gateway logs.
CloudWatch Alarms:
API Gateway 5XXError > 5 in 5 minutes.
Lambda Errors > 1 in 5 minutes.
Optional: Enable AWS X-Ray for tracing.

Future Enhancements
Email notifications with SNS.
Task priority & tagging.
CI/CD with CodePipeline.
More detailed dashboards with CloudWatch.

License
This project is licensed under the MIT License.
