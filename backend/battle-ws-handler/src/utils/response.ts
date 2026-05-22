import { APIGatewayProxyResult } from 'aws-lambda';

export const successResponse = (statusCode: number, body?: object): APIGatewayProxyResult => ({
  statusCode,
  body: body ? JSON.stringify(body) : '',
});

export const errorResponse = (statusCode: number, message: string): APIGatewayProxyResult => ({
  statusCode,
  body: JSON.stringify({ error: message }),
});
