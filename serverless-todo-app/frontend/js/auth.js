(function () {
  const { region, userPoolId, userPoolClientId } = window.APP_CONFIG.cognito;

  const poolData = {
    UserPoolId: userPoolId,
    ClientId: userPoolClientId,
  };
  const userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);

  function getSessionAsync(cognitoUser) {
    return new Promise((resolve, reject) => {
      cognitoUser.getSession((err, session) => {
        if (err) return reject(err);
        resolve(session);
      });
    });
  }

  async function login(email, password) {
    const authDetails = new AmazonCognitoIdentity.AuthenticationDetails({
      Username: email,
      Password: password,
    });
    const userData = { Username: email, Pool: userPool };
    const cognitoUser = new AmazonCognitoIdentity.CognitoUser(userData);

    return new Promise((resolve, reject) => {
      cognitoUser.authenticateUser(authDetails, {
        onSuccess: resolve,
        onFailure: reject,
      });
    });
  }

  function signup(email, password) {
    return new Promise((resolve, reject) => {
      userPool.signUp(email, password, [new AmazonCognitoIdentity.CognitoUserAttribute({ Name: 'email', Value: email })], null, (err, res) => {
        if (err) return reject(err);
        resolve(res);
      });
    });
  }

  function confirm(email, code) {
    const userData = { Username: email, Pool: userPool };
    const cognitoUser = new AmazonCognitoIdentity.CognitoUser(userData);
    return new Promise((resolve, reject) => {
      cognitoUser.confirmRegistration(code, true, (err, result) => {
        if (err) return reject(err);
        resolve(result);
      });
    });
  }

  function currentUser() {
    return userPool.getCurrentUser();
  }

  async function getJwt() {
    const cu = currentUser();
    if (!cu) return null;
    const session = await getSessionAsync(cu);
    return session.getIdToken().getJwtToken();
  }

  function logout() {
    const cu = currentUser();
    if (cu) cu.signOut();
  }

  window.Auth = { login, signup, confirm, currentUser, getJwt, logout };
})();
