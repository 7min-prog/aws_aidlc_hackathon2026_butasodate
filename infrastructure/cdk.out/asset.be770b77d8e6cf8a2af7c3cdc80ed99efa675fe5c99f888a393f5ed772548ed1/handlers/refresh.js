"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleRefresh = void 0;
const client_cognito_identity_provider_1 = require("@aws-sdk/client-cognito-identity-provider");
const cognito_client_1 = require("../utils/cognito-client");
const response_1 = require("../utils/response");
const handleRefresh = async (event) => {
    const { refreshToken } = JSON.parse(event.body || '{}');
    if (!refreshToken) {
        return (0, response_1.errorResponse)(400, 'refreshToken is required');
    }
    try {
        const result = await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.InitiateAuthCommand({
            ClientId: cognito_client_1.CLIENT_ID,
            AuthFlow: 'REFRESH_TOKEN_AUTH',
            AuthParameters: {
                REFRESH_TOKEN: refreshToken,
            },
        }));
        const tokens = result.AuthenticationResult;
        if (!tokens) {
            return (0, response_1.errorResponse)(500, 'Token refresh failed');
        }
        return (0, response_1.successResponse)(200, {
            accessToken: tokens.AccessToken,
            idToken: tokens.IdToken,
            expiresIn: tokens.ExpiresIn,
        });
    }
    catch (error) {
        if (error.name === 'NotAuthorizedException') {
            return (0, response_1.errorResponse)(401, 'Refresh token expired, please login again');
        }
        console.error('Refresh error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handleRefresh = handleRefresh;
