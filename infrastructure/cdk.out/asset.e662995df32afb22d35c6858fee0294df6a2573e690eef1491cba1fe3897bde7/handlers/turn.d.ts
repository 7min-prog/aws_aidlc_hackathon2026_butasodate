import { APIGatewayProxyResult } from 'aws-lambda';
export declare const handleSelectAction: (connectionId: string, data: {
    matchId: string;
    action: {
        type: string;
        skillId?: string;
    };
}) => Promise<APIGatewayProxyResult>;
