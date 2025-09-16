// ===== Serverless To-Do App Frontend Configuration =====
// Update these values with the actual resource IDs/URLs from your AWS setup.

const config = {
  // Cognito
  cognito: {
    REGION: "us-west-1", // your region
    USER_POOL_ID: "us-west-1_XXXXXXXXX",       // from Cognito User Pool
    APP_CLIENT_ID: "XXXXXXXXXXXXXXXXXXXXXXXXXX", // from Cognito App Client
    IDENTITY_POOL_ID: "us-west-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" // from Identity Pool
  },

  // API Gateway
  api: {
    REGION: "us-west-1",
    BASE_URL: "https://xxxxxxx.execute-api.us-west-1.amazonaws.com/prod" // API Gateway invoke URL
  },

  // S3 / CloudFront (frontend hosting)
  frontend: {
    S3_BUCKET: "serverless-todo-app-frontend-us-west-1",  // optional reference
    CLOUDFRONT_URL: "https://dxxxxx.cloudfront.net"       // CloudFront distribution domain
  }
};

// Expose globally
window._config = config;
