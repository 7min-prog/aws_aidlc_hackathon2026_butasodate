"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getUserId = getUserId;
function getUserId(event) {
    const claims = event.requestContext.authorizer?.claims;
    if (!claims?.sub)
        throw new Error('Unauthorized');
    return claims.sub;
}
//# sourceMappingURL=auth.js.map