import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { handleSignup, handleConfirm, handleResendCode } from './handlers/signup';
import { handleLogin } from './handlers/login';
import { handleLogout } from './handlers/logout';
import { handleRefresh } from './handlers/refresh';
import { handleGetProfile, handleCreateProfile, handleUpdateProfile } from './handlers/profile';
import { errorResponse } from './utils/response';

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const { httpMethod, path } = event;
  const route = `${httpMethod} ${path}`;

  try {
    switch (route) {
      case 'POST /auth/signup':
        return handleSignup(event);
      case 'POST /auth/confirm':
        return handleConfirm(event);
      case 'POST /auth/resend-code':
        return handleResendCode(event);
      case 'POST /auth/login':
        return handleLogin(event);
      case 'POST /auth/logout':
        return handleLogout(event);
      case 'POST /auth/refresh':
        return handleRefresh(event);
      case 'GET /users/me':
        return handleGetProfile(event);
      case 'POST /users/profile':
        return handleCreateProfile(event);
      case 'PUT /users/profile':
        return handleUpdateProfile(event);
      default:
        return errorResponse(404, 'Not Found');
    }
  } catch (error) {
    console.error('Unhandled error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};
