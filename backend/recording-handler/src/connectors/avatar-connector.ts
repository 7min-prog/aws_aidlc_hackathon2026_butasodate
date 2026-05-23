import { LambdaClient, InvokeCommand } from '@aws-sdk/client-lambda';
import { AvatarStatus } from '../types';

const lambda = new LambdaClient({});
const AVATAR_FUNCTION = process.env.AVATAR_FUNCTION_NAME || 'buta-avatar-handler-dev';

export async function addPoints(
  userId: string,
  points: number,
  categoryType: string,
  subCategoryId?: string,
): Promise<AvatarStatus> {
  const payload = {
    httpMethod: 'POST',
    path: '/avatar/points',
    headers: { 'x-user-id': userId, 'content-type': 'application/json' },
    body: JSON.stringify({ points, categoryType, subCategoryId }),
    requestContext: { authorizer: { claims: { sub: userId } } },
  };

  const res = await lambda.send(new InvokeCommand({
    FunctionName: AVATAR_FUNCTION,
    Payload: Buffer.from(JSON.stringify(payload)),
  }));

  const body = JSON.parse(Buffer.from(res.Payload!).toString());
  const parsed = JSON.parse(body.body || '{}');
  return parsed.avatar || { totalPoints: points, level: 1 };
}

export async function deductPoints(
  userId: string,
  points: number,
  categoryId: string,
): Promise<{ avatarStatus: AvatarStatus; devolutionOccurred: boolean }> {
  const payload = {
    httpMethod: 'POST',
    path: '/avatar/points/deduct',
    headers: { 'x-user-id': userId, 'content-type': 'application/json' },
    body: JSON.stringify({ points, categoryType: 'FOOD', subCategoryId: categoryId }),
    requestContext: { authorizer: { claims: { sub: userId } } },
  };

  const res = await lambda.send(new InvokeCommand({
    FunctionName: AVATAR_FUNCTION,
    Payload: Buffer.from(JSON.stringify(payload)),
  }));

  const body = JSON.parse(Buffer.from(res.Payload!).toString());
  const parsed = JSON.parse(body.body || '{}');
  return {
    avatarStatus: parsed.avatar || { totalPoints: 0, level: 1 },
    devolutionOccurred: parsed.devolved || false,
  };
}
