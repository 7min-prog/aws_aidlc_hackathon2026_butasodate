"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.success = success;
exports.created = created;
exports.error = error;
function success(body) {
    return { statusCode: 200, headers: corsHeaders(), body: JSON.stringify(body) };
}
function created(body) {
    return { statusCode: 201, headers: corsHeaders(), body: JSON.stringify(body) };
}
function error(statusCode, message) {
    return { statusCode, headers: corsHeaders(), body: JSON.stringify({ error: message }) };
}
function corsHeaders() {
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    };
}
//# sourceMappingURL=response.js.map