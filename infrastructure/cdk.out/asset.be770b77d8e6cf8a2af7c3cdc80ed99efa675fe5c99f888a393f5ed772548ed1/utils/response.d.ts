import { APIGatewayProxyResult } from 'aws-lambda';
export declare const successResponse: (statusCode: number, body: object) => APIGatewayProxyResult;
export declare const errorResponse: (statusCode: number, message: string) => APIGatewayProxyResult;
