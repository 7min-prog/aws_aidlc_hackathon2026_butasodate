"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleLogout = void 0;
const client_cognito_identity_provider_1 = require("@aws-sdk/client-cognito-identity-provider");
const cognito_client_1 = require("../utils/cognito-client");
const response_1 = require("../utils/response");
const handleLogout = async (event) => {
    const accessToken = event.headers?.Authorization?.replace('Bearer ', '');
    if (!accessToken) {
        return (0, response_1.errorResponse)(401, 'Access token required');
    }
    try {
        await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.GlobalSignOutCommand({
            AccessToken: accessToken,
        }));
        return (0, response_1.successResponse)(200, { message: 'Logged out successfully' });
    }
    catch (error) {
        console.error('Logout error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handleLogout = handleLogout;
