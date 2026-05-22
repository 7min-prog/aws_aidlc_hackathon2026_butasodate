import { ApiGatewayManagementApiClient, PostToConnectionCommand } from '@aws-sdk/client-apigatewaymanagementapi';

const ENDPOINT = process.env.WEBSOCKET_ENDPOINT || '';

const wsClient = new ApiGatewayManagementApiClient({
  region: 'ap-northeast-1',
  endpoint: ENDPOINT,
});

export async function sendToConnection(connectionId: string, data: object): Promise<void> {
  try {
    await wsClient.send(new PostToConnectionCommand({
      ConnectionId: connectionId,
      Data: Buffer.from(JSON.stringify(data)),
    }));
  } catch (error: any) {
    if (error.statusCode === 410) {
      // Connection is gone - ignore
      console.log(`Connection ${connectionId} is stale`);
    } else {
      throw error;
    }
  }
}
