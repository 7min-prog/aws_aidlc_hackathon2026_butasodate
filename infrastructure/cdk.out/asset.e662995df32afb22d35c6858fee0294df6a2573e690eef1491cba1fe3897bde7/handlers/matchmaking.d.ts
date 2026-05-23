import { APIGatewayProxyResult } from 'aws-lambda';
export declare const handleRequestMatch: (connectionId: string, data: {
    type: "random" | "friend";
    targetId?: string;
    level?: number;
}) => Promise<APIGatewayProxyResult>;
export declare const handleCancelMatch: (connectionId: string) => Promise<APIGatewayProxyResult>;
