import { APIGatewayProxyEvent } from 'aws-lambda';

export function getUserId(event: APIGatewayProxyEvent): string {
  const claims = event.requestContext.authorizer?.claims;
  if (!claims?.sub) throw new Error('Unauthorized');
  return claims.sub;
}
