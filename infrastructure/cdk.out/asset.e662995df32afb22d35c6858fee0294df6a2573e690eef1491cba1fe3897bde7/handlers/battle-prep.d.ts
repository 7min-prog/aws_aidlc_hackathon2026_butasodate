import { APIGatewayProxyResult } from 'aws-lambda';
export declare const handleRespondInvite: (connectionId: string, data: {
    matchId: string;
    accept: boolean;
}) => Promise<APIGatewayProxyResult>;
export declare const handleSetReady: (connectionId: string, data: {
    matchId: string;
    skills: string[];
}) => Promise<APIGatewayProxyResult>;
