import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { InitiateAuthCommand } from '@aws-sdk/client-cognito-identity-provider';
import { cognitoClient, CLIENT_ID } from '../utils/cognito-client';
import { dynamoClient, USERS_TABLE } from '../utils/dynamo-client';
import { UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { successResponse, errorResponse } from '../utils/response';

export const handleLogin = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const { email, password } = JSON.parse(event.body || '{}');

  if (!email || !password) {
    return errorResponse(400, 'email and password are required');
  }

  try {
    const result = await cognitoClient.send(new InitiateAuthCommand({
      ClientId: CLIENT_ID,
      AuthFlow: 'USER_PASSWORD_AUTH',
      AuthParameters: {
        USERNAME: email,
        PASSWORD: password,
      },
    }));

    const tokens = result.AuthenticationResult;
    if (!tokens) {
      return errorResponse(500, 'Authentication failed');
    }

    // Update lastLoginAt
    const sub = extractSub(tokens.IdToken!);
    if (sub) {
      await dynamoClient.send(new UpdateCommand({
        TableName: USERS_TABLE,
        Key: { userId: sub },
        UpdateExpression: 'SET lastLoginAt = :now',
        ExpressionAttributeValues: { ':now': new Date().toISOString() },
      }));
    }

    return successResponse(200, {
      accessToken: tokens.AccessToken,
      refreshToken: tokens.RefreshToken,
      idToken: tokens.IdToken,
      expiresIn: tokens.ExpiresIn,
    });
  } catch (error: any) {
    if (error.name === 'NotAuthorizedException' || error.name === 'UserNotFoundException') {
      return errorResponse(401, 'Invalid email or password');
    }
    if (error.name === 'UserNotConfirmedException') {
      return errorResponse(403, 'Email not confirmed');
    }
    console.error('Login error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};

function extractSub(idToken: string): string | null {
  try {
    const payload = JSON.parse(Buffer.from(idToken.split('.')[1], 'base64').toString());
    return payload.sub || null;
  } catch {
    return null;
  }
}
