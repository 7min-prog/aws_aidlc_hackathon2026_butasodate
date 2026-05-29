import { APIGatewayProxyEvent } from 'aws-lambda';

export function getUserId(event: APIGatewayProxyEvent): string | null {
  return event.requestContext.authorizer?.claims?.sub || null;
}
