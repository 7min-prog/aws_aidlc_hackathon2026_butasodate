"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleLogin = void 0;
const client_cognito_identity_provider_1 = require("@aws-sdk/client-cognito-identity-provider");
const cognito_client_1 = require("../utils/cognito-client");
const dynamo_client_1 = require("../utils/dynamo-client");
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const response_1 = require("../utils/response");
const handleLogin = async (event) => {
    const { email, password } = JSON.parse(event.body || '{}');
    if (!email || !password) {
        return (0, response_1.errorResponse)(400, 'email and password are required');
    }
    try {
        const result = await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.InitiateAuthCommand({
            ClientId: cognito_client_1.CLIENT_ID,
            AuthFlow: 'USER_PASSWORD_AUTH',
            AuthParameters: {
                USERNAME: email,
                PASSWORD: password,
            },
        }));
        const tokens = result.AuthenticationResult;
        if (!tokens) {
            return (0, response_1.errorResponse)(500, 'Authentication failed');
        }
        // Update lastLoginAt
        const sub = extractSub(tokens.IdToken);
        if (sub) {
            await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.UpdateCommand({
                TableName: dynamo_client_1.USERS_TABLE,
                Key: { userId: sub },
                UpdateExpression: 'SET lastLoginAt = :now',
                ExpressionAttributeValues: { ':now': new Date().toISOString() },
            }));
        }
        return (0, response_1.successResponse)(200, {
            accessToken: tokens.AccessToken,
            refreshToken: tokens.RefreshToken,
            idToken: tokens.IdToken,
            expiresIn: tokens.ExpiresIn,
        });
    }
    catch (error) {
        if (error.name === 'NotAuthorizedException' || error.name === 'UserNotFoundException') {
            return (0, response_1.errorResponse)(401, 'Invalid email or password');
        }
        if (error.name === 'UserNotConfirmedException') {
            return (0, response_1.errorResponse)(403, 'Email not confirmed');
        }
        console.error('Login error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handleLogin = handleLogin;
function extractSub(idToken) {
    try {
        const payload = JSON.parse(Buffer.from(idToken.split('.')[1], 'base64').toString());
        return payload.sub || null;
    }
    catch {
        return null;
    }
}
