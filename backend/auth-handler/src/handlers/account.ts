import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { dynamoClient, USERS_TABLE } from '../utils/dynamo-client';
import { cognitoClient, USER_POOL_ID } from '../utils/cognito-client';
import { DeleteCommand } from '@aws-sdk/lib-dynamodb';
import { AdminDeleteUserCommand } from '@aws-sdk/client-cognito-identity-provider';
import { successResponse, errorResponse } from '../utils/response';

export const handleDeleteAccount = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const userId = event.requestContext.authorizer?.claims?.sub;
  if (!userId) return errorResponse(401, 'Unauthorized');

  const username = event.requestContext.authorizer?.claims?.['cognito:username'] || userId;

  try {
    await dynamoClient.send(new DeleteCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    }));

    await cognitoClient.send(new AdminDeleteUserCommand({
      UserPoolId: USER_POOL_ID,
      Username: username,
    }));

    return successResponse(200, { message: 'Account deleted' });
  } catch (error) {
    console.error('DeleteAccount error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};
