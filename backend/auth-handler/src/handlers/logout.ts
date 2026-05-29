import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { GlobalSignOutCommand } from '@aws-sdk/client-cognito-identity-provider';
import { cognitoClient } from '../utils/cognito-client';
import { successResponse, errorResponse } from '../utils/response';

export const handleLogout = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const accessToken = event.headers?.Authorization?.replace('Bearer ', '');

  if (!accessToken) {
    return errorResponse(401, 'Access token required');
  }

  try {
    await cognitoClient.send(new GlobalSignOutCommand({
      AccessToken: accessToken,
    }));

    return successResponse(200, { message: 'Logged out successfully' });
  } catch (error: any) {
    console.error('Logout error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};
