import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
export declare const handleGetProfile: (event: APIGatewayProxyEvent) => Promise<APIGatewayProxyResult>;
export declare const handleCreateProfile: (event: APIGatewayProxyEvent) => Promise<APIGatewayProxyResult>;
export declare const handleUpdateProfile: (event: APIGatewayProxyEvent) => Promise<APIGatewayProxyResult>;
