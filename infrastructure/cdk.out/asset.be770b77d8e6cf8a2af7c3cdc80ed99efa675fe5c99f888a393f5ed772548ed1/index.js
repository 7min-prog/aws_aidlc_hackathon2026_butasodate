"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const signup_1 = require("./handlers/signup");
const login_1 = require("./handlers/login");
const logout_1 = require("./handlers/logout");
const refresh_1 = require("./handlers/refresh");
const profile_1 = require("./handlers/profile");
const account_1 = require("./handlers/account");
const response_1 = require("./utils/response");
const handler = async (event) => {
    const { httpMethod, path } = event;
    const route = `${httpMethod} ${path}`;
    try {
        switch (route) {
            case 'POST /auth/signup':
                return (0, signup_1.handleSignup)(event);
            case 'POST /auth/confirm':
                return (0, signup_1.handleConfirm)(event);
            case 'POST /auth/resend-code':
                return (0, signup_1.handleResendCode)(event);
            case 'POST /auth/login':
                return (0, login_1.handleLogin)(event);
            case 'POST /auth/logout':
                return (0, logout_1.handleLogout)(event);
            case 'POST /auth/refresh':
                return (0, refresh_1.handleRefresh)(event);
            case 'GET /users/me':
                return (0, profile_1.handleGetProfile)(event);
            case 'POST /users/profile':
                return (0, profile_1.handleCreateProfile)(event);
            case 'PUT /users/profile':
                return (0, profile_1.handleUpdateProfile)(event);
            case 'DELETE /account':
                return (0, account_1.handleDeleteAccount)(event);
            default:
                return (0, response_1.errorResponse)(404, 'Not Found');
        }
    }
    catch (error) {
        console.error('Unhandled error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handler = handler;
