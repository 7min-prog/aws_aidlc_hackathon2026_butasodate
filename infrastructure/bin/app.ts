#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AuthStack } from '../lib/auth-stack';
import { RecordingStack } from '../lib/recording-stack';

const app = new cdk.App();

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: 'ap-northeast-1',
};

new AuthStack(app, 'ButaAuthStack', { env });

new RecordingStack(app, 'ButaRecordingStack', {
  env,
  userPoolId: process.env.COGNITO_USER_POOL_ID || 'ap-northeast-1_PLACEHOLDER',
});
