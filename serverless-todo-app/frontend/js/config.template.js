/*!
 * config.template.js
 * Checked-in template. At deploy time, copy/transform to config.js with your real values.
 */

window.APP_CONFIG = {
  cognito: {
    // Required by auth.js
    region: "${REGION}",                 // e.g. "us-east-2"
    userPoolId: "${USER_POOL_ID}",       // e.g. "us-east-2_6Y9E3tgYX"
    userPoolClientId: "${SPA_CLIENT_ID}" // SPA client id (the token 'aud')
  },

  // Required by api.js (flat key used in your code)
  apiBaseUrl: "${API_BASE_URL}"          // e.g. "https://740ygy9xtk.execute-api.us-east-2.amazonaws.com"
};

// ---- Optional legacy shape (_config) for any older scripts ----
window._config = window._config || {
  cognito: {
    REGION: "${REGION}",
    USER_POOL_ID: "${USER_POOL_ID}",
    APP_CLIENT_ID: "${SPA_CLIENT_ID}"
  },
  api: {
    REGION: "${REGION}",
    BASE_URL: "${API_BASE_URL}"
  }
};
