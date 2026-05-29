"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.USER_POOL_ID = exports.CLIENT_ID = exports.cognitoClient = void 0;
const client_cognito_identity_provider_1 = require("@aws-sdk/client-cognito-identity-provider");
exports.cognitoClient = new client_cognito_identity_provider_1.CognitoIdentityProviderClient({
    region: process.env.AWS_REGION || 'ap-northeast-1',
});
exports.CLIENT_ID = process.env.COGNITO_CLIENT_ID || '';
exports.USER_POOL_ID = process.env.COGNITO_USER_POOL_ID || '';
