import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { InitiateAuthCommand } from '@aws-sdk/client-cognito-identity-provider';
import { cognitoClient, CLIENT_ID } from '../utils/cognito-client';
import { successResponse, errorResponse } from '../utils/response';

export const handleRefresh = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const { refreshToken } = JSON.parse(event.body || '{}');

  if (!refreshToken) {
    return errorResponse(400, 'refreshToken is required');
  }

  try {
    const result = await cognitoClient.send(new InitiateAuthCommand({
      ClientId: CLIENT_ID,
      AuthFlow: 'REFRESH_TOKEN_AUTH',
      AuthParameters: {
        REFRESH_TOKEN: refreshToken,
      },
    }));

    const tokens = result.AuthenticationResult;
    if (!tokens) {
      return errorResponse(500, 'Token refresh failed');
    }

    return successResponse(200, {
      accessToken: tokens.AccessToken,
      idToken: tokens.IdToken,
      expiresIn: tokens.ExpiresIn,
    });
  } catch (error: any) {
    if (error.name === 'NotAuthorizedException') {
      return errorResponse(401, 'Refresh token expired, please login again');
    }
    console.error('Refresh error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};
