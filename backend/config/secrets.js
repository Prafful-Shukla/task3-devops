import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from "@aws-sdk/client-secrets-manager";

const secretId = process.env.SECRET_ID;
const region = process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION || "us-east-1";

let cachedSecret;
let client;

function getClient() {
  if (!client) {
    client = new SecretsManagerClient({ region });
  }

  return client;
}

export async function getSecret() {
  if (!secretId) {
    throw new Error(
      "SECRET_ID is not set. Provide DB_* environment variables for local runs or set SECRET_ID for AWS Secrets Manager."
    );
  }

  if (cachedSecret) {
    return cachedSecret;
  }

  const response = await getClient().send(
    new GetSecretValueCommand({
      SecretId: secretId,
    })
  );

  if (!response.SecretString) {
    throw new Error(`Secret ${secretId} did not contain a SecretString payload.`);
  }

  cachedSecret = JSON.parse(response.SecretString);
  console.log(`✅ Secret fetched from AWS Secrets Manager: ${secretId}`);

  return cachedSecret;
}
