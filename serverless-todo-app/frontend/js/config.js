// ===== Serverless To-Do App Frontend Configuration =====
// Update these values with the actual resource IDs/URLs from your AWS setup.

const config = {
  // ✅ Cognito
  cognito: {
    REGION: "us-east-2", // your region
    USER_POOL_ID: "us-east-2_6Y9E3tgYX",       // from Cognito User Pool
    APP_CLIENT_ID: "4bk1bttj1jb0eepn9smouo08am", // from Cognito App Client
  },

  // ✅ API Gateway
  api: {
    REGION: "us-east-2",
    BASE_URL: "https://740ygy9xtk.execute-api.us-east-2.amazonaws.com" // API Gateway invoke URL
  },

  // ✅ S3 / CloudFront (frontend hosting)
  frontend: {
    S3_BUCKET: "serverless-todo-app-frontend-us-east-2",  // optional reference
    CLOUDFRONT_URL: "https://dxxxxx.cloudfront.net"       // CloudFront distribution domain
  }
};

// Expose globally
window._config = config;
