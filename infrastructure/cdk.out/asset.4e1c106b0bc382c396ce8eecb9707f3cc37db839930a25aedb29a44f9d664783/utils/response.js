"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorResponse = exports.successResponse = void 0;
const CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
};
const successResponse = (statusCode, body) => ({
    statusCode,
    headers: CORS_HEADERS,
    body: JSON.stringify(body),
});
exports.successResponse = successResponse;
const errorResponse = (statusCode, message) => ({
    statusCode,
    headers: CORS_HEADERS,
    body: JSON.stringify({ error: message }),
});
exports.errorResponse = errorResponse;
