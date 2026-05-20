import { handleSignup, handleConfirm, handleResendCode } from '../../src/handlers/signup';
import { cognitoClient } from '../../src/utils/cognito-client';
import { APIGatewayProxyEvent } from 'aws-lambda';

jest.mock('../../src/utils/cognito-client', () => ({
  cognitoClient: { send: jest.fn() },
  CLIENT_ID: 'test-client-id',
}));

const mockEvent = (body: object): APIGatewayProxyEvent =>
  ({ body: JSON.stringify(body) } as any);

describe('handleSignup', () => {
  it('returns 400 if email is missing', async () => {
    const result = await handleSignup(mockEvent({ password: 'Test1234!' }));
    expect(result.statusCode).toBe(400);
  });

  it('returns 400 if password is missing', async () => {
    const result = await handleSignup(mockEvent({ email: 'test@example.com' }));
    expect(result.statusCode).toBe(400);
  });

  it('returns 201 on successful signup', async () => {
    (cognitoClient.send as jest.Mock).mockResolvedValue({});
    const result = await handleSignup(mockEvent({ email: 'test@example.com', password: 'Test1234!' }));
    expect(result.statusCode).toBe(201);
  });

  it('returns 409 if email already exists', async () => {
    (cognitoClient.send as jest.Mock).mockRejectedValue({ name: 'UsernameExistsException' });
    const result = await handleSignup(mockEvent({ email: 'test@example.com', password: 'Test1234!' }));
    expect(result.statusCode).toBe(409);
  });

  it('returns 400 if password is invalid', async () => {
    (cognitoClient.send as jest.Mock).mockRejectedValue({ name: 'InvalidPasswordException' });
    const result = await handleSignup(mockEvent({ email: 'test@example.com', password: 'weak' }));
    expect(result.statusCode).toBe(400);
  });
});

describe('handleConfirm', () => {
  it('returns 400 if email or code is missing', async () => {
    const result = await handleConfirm(mockEvent({ email: 'test@example.com' }));
    expect(result.statusCode).toBe(400);
  });

  it('returns 200 on successful confirmation', async () => {
    (cognitoClient.send as jest.Mock).mockResolvedValue({});
    const result = await handleConfirm(mockEvent({ email: 'test@example.com', code: '123456' }));
    expect(result.statusCode).toBe(200);
  });

  it('returns 400 on code mismatch', async () => {
    (cognitoClient.send as jest.Mock).mockRejectedValue({ name: 'CodeMismatchException' });
    const result = await handleConfirm(mockEvent({ email: 'test@example.com', code: '000000' }));
    expect(result.statusCode).toBe(400);
  });

  it('returns 400 on expired code', async () => {
    (cognitoClient.send as jest.Mock).mockRejectedValue({ name: 'ExpiredCodeException' });
    const result = await handleConfirm(mockEvent({ email: 'test@example.com', code: '123456' }));
    expect(result.statusCode).toBe(400);
  });
});

describe('handleResendCode', () => {
  it('returns 400 if email is missing', async () => {
    const result = await handleResendCode(mockEvent({}));
    expect(result.statusCode).toBe(400);
  });

  it('returns 200 on successful resend', async () => {
    (cognitoClient.send as jest.Mock).mockResolvedValue({});
    const result = await handleResendCode(mockEvent({ email: 'test@example.com' }));
    expect(result.statusCode).toBe(200);
  });
});
