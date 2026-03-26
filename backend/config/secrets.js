import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from "@aws-sdk/client-secrets-manager";

const client = new SecretsManagerClient({
  region: "us-east-1", // ⚠️ change if different
});

export async function getSecret() {
  const response = await client.send(
    new GetSecretValueCommand({
      SecretId: "task1/rds/postgres", // your secret name
    })
  );

  const secret = JSON.parse(response.SecretString);
  console.log("✅ Secret fetched from AWS");

  return secret;
}