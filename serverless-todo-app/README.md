# Serverless To-Do App (Manual Build)

A fully serverless web application that you’ll provision **manually** (no SAM/CDK) to demonstrate hands-on mastery of AWS fundamentals: Cognito, API Gateway (HTTP API + JWT), Lambda (Node.js 18), DynamoDB, S3 (static), CloudFront (OAI), IAM, and CloudWatch.

## Architecture
![Architecture Diagram](docs/Serverless_Application_Architecture.png)

**Flow**
1) Cognito authenticates users and issues JWTs  
2) API Gateway (HTTP API) verifies JWTs via Cognito authorizer  
3) Lambda implements CRUD  
4) DynamoDB stores tasks (`PK: userId`, `SK: taskId`)  
5) S3 + CloudFront (OAI) serves frontend securely

## Tech
Cognito • API Gateway • Lambda • DynamoDB • S3 • CloudFront • IAM • CloudWatch

## Manual Setup (high level)
1. **Cognito**: Create User Pool + App Client (no secret).  
2. **DynamoDB**: Create table `serverless-todo-app-tasks` (userId, taskId).  
3. **IAM**: Create Lambda execution role (basic logs + table CRUD on this table only).  
4. **Lambda**: Create function from `backend/functions/handler.js`, env `TABLE_NAME`.  
5. **API Gateway (HTTP API)**: Create API, add **JWT authorizer** (User Pool + Client ID), add routes:  
   - POST `/tasks` → Lambda  
   - GET `/tasks` → Lambda  
   - PUT `/tasks/{taskId}` → Lambda  
   - DELETE `/tasks/{taskId}` → Lambda  
6. **S3 + CloudFront**: Create **private** bucket for frontend; create CloudFront distribution with **OAI** and S3 as origin; default root `index.html`.  
7. **Frontend config**: Copy `frontend/js/config.template.js` → `config.js` and fill in **UserPoolId**, **UserPoolClientId**, **apiBaseUrl**.  
8. **Monitoring**: Verify CloudWatch logs; create alarms for API 5XX and Lambda errors.  
9. **Diagram**: Use **AWS Perspective** to scan and export PNG to `docs/`.

## Run
Open the **CloudFront domain** → Sign up → Confirm → Log in → CRUD tasks.

## Security
- JWT-protected API (Cognito authorizer)  
- Lambda IAM is **least-privilege** to only this table  
- S3 is private; CloudFront OAI is the only reader

## License
MIT
