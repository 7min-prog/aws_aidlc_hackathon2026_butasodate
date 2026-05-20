import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { SignUpCommand, ConfirmSignUpCommand, ResendConfirmationCodeCommand } from '@aws-sdk/client-cognito-identity-provider';
import { cognitoClient, CLIENT_ID } from '../utils/cognito-client';
import { successResponse, errorResponse } from '../utils/response';

export const handleSignup = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const { email, password } = JSON.parse(event.body || '{}');

  if (!email || !password) {
    return errorResponse(400, 'email and password are required');
  }

  try {
    await cognitoClient.send(new SignUpCommand({
      ClientId: CLIENT_ID,
      Username: email,
      Password: password,
      UserAttributes: [{ Name: 'email', Value: email }],
    }));

    return successResponse(201, { message: 'Confirmation code sent to email' });
  } catch (error: any) {
    if (error.name === 'UsernameExistsException') {
      return errorResponse(409, 'This email is already registered');
    }
    if (error.name === 'InvalidPasswordException') {
      return errorResponse(400, 'Password does not meet requirements');
    }
    console.error('Signup error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};

export const handleConfirm = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const { email, code } = JSON.parse(event.body || '{}');

  if (!email || !code) {
    return errorResponse(400, 'email and code are required');
  }

  try {
    await cognitoClient.send(new ConfirmSignUpCommand({
      ClientId: CLIENT_ID,
      Username: email,
      ConfirmationCode: code,
    }));

    return successResponse(200, { message: 'Email confirmed successfully' });
  } catch (error: any) {
    if (error.name === 'CodeMismatchException') {
      return errorResponse(400, 'Invalid confirmation code');
    }
    if (error.name === 'ExpiredCodeException') {
      return errorResponse(400, 'Confirmation code has expired');
    }
    console.error('Confirm error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};

export const handleResendCode = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const { email } = JSON.parse(event.body || '{}');

  if (!email) {
    return errorResponse(400, 'email is required');
  }

  try {
    await cognitoClient.send(new ResendConfirmationCodeCommand({
      ClientId: CLIENT_ID,
      Username: email,
    }));

    return successResponse(200, { message: 'Confirmation code resent' });
  } catch (error: any) {
    console.error('Resend code error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};
