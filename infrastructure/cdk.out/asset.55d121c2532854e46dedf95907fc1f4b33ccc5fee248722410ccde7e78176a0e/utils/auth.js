"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getUserId = getUserId;
function getUserId(event) {
    return event.requestContext.authorizer?.claims?.sub || null;
}
//# sourceMappingURL=auth.js.map