import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
export declare const handleConnect: (event: APIGatewayProxyEvent) => Promise<APIGatewayProxyResult>;
export declare const handleDisconnect: (connectionId: string) => Promise<APIGatewayProxyResult>;
declare function getConnectionByUserId(userId: string): Promise<{
    connectionId: string;
    userId: string;
} | undefined>;
export { getConnectionByUserId };
