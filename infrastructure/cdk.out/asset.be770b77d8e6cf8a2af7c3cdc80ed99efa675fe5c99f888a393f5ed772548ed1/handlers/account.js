"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleDeleteAccount = void 0;
const dynamo_client_1 = require("../utils/dynamo-client");
const cognito_client_1 = require("../utils/cognito-client");
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const client_cognito_identity_provider_1 = require("@aws-sdk/client-cognito-identity-provider");
const response_1 = require("../utils/response");
const handleDeleteAccount = async (event) => {
    const userId = event.requestContext.authorizer?.claims?.sub;
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const username = event.requestContext.authorizer?.claims?.['cognito:username'] || userId;
    try {
        await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.DeleteCommand({
            TableName: dynamo_client_1.USERS_TABLE,
            Key: { userId },
        }));
        await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.AdminDeleteUserCommand({
            UserPoolId: cognito_client_1.USER_POOL_ID,
            Username: username,
        }));
        return (0, response_1.successResponse)(200, { message: 'Account deleted' });
    }
    catch (error) {
        console.error('DeleteAccount error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handleDeleteAccount = handleDeleteAccount;
