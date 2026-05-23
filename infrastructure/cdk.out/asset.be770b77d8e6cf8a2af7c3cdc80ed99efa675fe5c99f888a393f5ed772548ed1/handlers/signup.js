"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleResendCode = exports.handleConfirm = exports.handleSignup = void 0;
const client_cognito_identity_provider_1 = require("@aws-sdk/client-cognito-identity-provider");
const cognito_client_1 = require("../utils/cognito-client");
const response_1 = require("../utils/response");
const handleSignup = async (event) => {
    const { email, password } = JSON.parse(event.body || '{}');
    if (!email || !password) {
        return (0, response_1.errorResponse)(400, 'email and password are required');
    }
    try {
        await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.SignUpCommand({
            ClientId: cognito_client_1.CLIENT_ID,
            Username: email,
            Password: password,
            UserAttributes: [{ Name: 'email', Value: email }],
        }));
        return (0, response_1.successResponse)(201, { message: 'Confirmation code sent to email' });
    }
    catch (error) {
        if (error.name === 'UsernameExistsException') {
            return (0, response_1.errorResponse)(409, 'This email is already registered');
        }
        if (error.name === 'InvalidPasswordException') {
            return (0, response_1.errorResponse)(400, 'Password does not meet requirements');
        }
        console.error('Signup error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handleSignup = handleSignup;
const handleConfirm = async (event) => {
    const { email, code } = JSON.parse(event.body || '{}');
    if (!email || !code) {
        return (0, response_1.errorResponse)(400, 'email and code are required');
    }
    try {
        await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.ConfirmSignUpCommand({
            ClientId: cognito_client_1.CLIENT_ID,
            Username: email,
            ConfirmationCode: code,
        }));
        return (0, response_1.successResponse)(200, { message: 'Email confirmed successfully' });
    }
    catch (error) {
        if (error.name === 'CodeMismatchException') {
            return (0, response_1.errorResponse)(400, 'Invalid confirmation code');
        }
        if (error.name === 'ExpiredCodeException') {
            return (0, response_1.errorResponse)(400, 'Confirmation code has expired');
        }
        console.error('Confirm error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handleConfirm = handleConfirm;
const handleResendCode = async (event) => {
    const { email } = JSON.parse(event.body || '{}');
    if (!email) {
        return (0, response_1.errorResponse)(400, 'email is required');
    }
    try {
        await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.ResendConfirmationCodeCommand({
            ClientId: cognito_client_1.CLIENT_ID,
            Username: email,
        }));
        return (0, response_1.successResponse)(200, { message: 'Confirmation code resent' });
    }
    catch (error) {
        console.error('Resend code error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handleResendCode = handleResendCode;
