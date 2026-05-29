"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.USER_POOL_ID = exports.cognitoClient = void 0;
const client_cognito_identity_provider_1 = require("@aws-sdk/client-cognito-identity-provider");
exports.cognitoClient = new client_cognito_identity_provider_1.CognitoIdentityProviderClient({});
exports.USER_POOL_ID = process.env.USER_POOL_ID;
//# sourceMappingURL=cognito-client.js.map