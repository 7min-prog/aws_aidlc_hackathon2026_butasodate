#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AuthStack } from '../lib/auth-stack';
import { RecordingStack } from '../lib/recording-stack';
import { AvatarStack } from '../lib/avatar-stack';
import { BattleSocialStack } from '../lib/battle-social-stack';
import { AdminStack } from '../lib/admin-stack';

const app = new cdk.App();

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: 'ap-northeast-1',
};

const authStack = new AuthStack(app, 'ButaAuthStack', { env });

new RecordingStack(app, 'ButaRecordingStack', {
  env,
  userPoolId: authStack.userPoolId,
});

const avatarStack = new AvatarStack(app, 'ButaAvatarStack', {
  env,
  userPoolId: authStack.userPoolId,
});

new BattleSocialStack(app, 'ButaBattleSocialStack', {
  env,
  userPoolId: authStack.userPoolId,
});

new AdminStack(app, 'ButaAdminStack', {
  env,
  userPoolId: authStack.userPoolId,
  assetsBucketName: avatarStack.assetsBucketName,
});
