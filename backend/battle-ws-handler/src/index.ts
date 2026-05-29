import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { handleConnect, handleDisconnect } from './handlers/connection';
import { handleRequestMatch, handleCancelMatch } from './handlers/matchmaking';
import { handleRespondInvite, handleSetReady } from './handlers/battle-prep';
import { handleSelectAction } from './handlers/turn';
import { errorResponse, successResponse } from './utils/response';

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const routeKey = event.requestContext.routeKey;
  const connectionId = event.requestContext.connectionId!;

  try {
    switch (routeKey) {
      case '$connect':
        return handleConnect(event);
      case '$disconnect':
        return handleDisconnect(connectionId);
      case '$default': {
        const body = JSON.parse(event.body || '{}');
        const action = body.action;

        switch (action) {
          case 'requestMatch':
            return handleRequestMatch(connectionId, body.data);
          case 'cancelMatch':
            return handleCancelMatch(connectionId);
          case 'respondInvite':
            return handleRespondInvite(connectionId, body.data);
          case 'setReady':
            return handleSetReady(connectionId, body.data);
          case 'selectAction':
            return handleSelectAction(connectionId, body.data);
          default:
            return errorResponse(400, `Unknown action: ${action}`);
        }
      }
      default:
        return errorResponse(400, `Unknown route: ${routeKey}`);
    }
  } catch (error) {
    console.error('Unhandled error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};
