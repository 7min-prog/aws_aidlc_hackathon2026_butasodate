import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
export declare const handleSignup: (event: APIGatewayProxyEvent) => Promise<APIGatewayProxyResult>;
export declare const handleConfirm: (event: APIGatewayProxyEvent) => Promise<APIGatewayProxyResult>;
export declare const handleResendCode: (event: APIGatewayProxyEvent) => Promise<APIGatewayProxyResult>;
