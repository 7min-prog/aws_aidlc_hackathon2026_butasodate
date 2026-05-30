"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorResponse = exports.successResponse = void 0;
const successResponse = (statusCode, body) => ({
    statusCode,
    body: body ? JSON.stringify(body) : '',
});
exports.successResponse = successResponse;
const errorResponse = (statusCode, message) => ({
    statusCode,
    body: JSON.stringify({ error: message }),
});
exports.errorResponse = errorResponse;
