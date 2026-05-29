"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const connection_1 = require("./handlers/connection");
const matchmaking_1 = require("./handlers/matchmaking");
const battle_prep_1 = require("./handlers/battle-prep");
const turn_1 = require("./handlers/turn");
const response_1 = require("./utils/response");
const handler = async (event) => {
    const routeKey = event.requestContext.routeKey;
    const connectionId = event.requestContext.connectionId;
    try {
        switch (routeKey) {
            case '$connect':
                return (0, connection_1.handleConnect)(event);
            case '$disconnect':
                return (0, connection_1.handleDisconnect)(connectionId);
            case '$default': {
                const body = JSON.parse(event.body || '{}');
                const action = body.action;
                switch (action) {
                    case 'requestMatch':
                        return (0, matchmaking_1.handleRequestMatch)(connectionId, body.data);
                    case 'cancelMatch':
                        return (0, matchmaking_1.handleCancelMatch)(connectionId);
                    case 'respondInvite':
                        return (0, battle_prep_1.handleRespondInvite)(connectionId, body.data);
                    case 'setReady':
                        return (0, battle_prep_1.handleSetReady)(connectionId, body.data);
                    case 'selectAction':
                        return (0, turn_1.handleSelectAction)(connectionId, body.data);
                    default:
                        return (0, response_1.errorResponse)(400, `Unknown action: ${action}`);
                }
            }
            default:
                return (0, response_1.errorResponse)(400, `Unknown route: ${routeKey}`);
        }
    }
    catch (error) {
        console.error('Unhandled error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handler = handler;
