import pkg from "pg";
const { Pool } = pkg;
import { getSecret } from "./secrets.js";

let pool;

function getSslConfig() {
  return process.env.DB_SSL === "false"
    ? false
    : {
        rejectUnauthorized: false,
      };
}

function getDatabaseConfigFromEnv() {
  const { DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME } = process.env;

  if (!DB_HOST || !DB_USER || !DB_PASSWORD) {
    return null;
  }

  return {
    host: DB_HOST,
    port: Number(DB_PORT || 5432),
    user: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME || "postgres",
    ssl: getSslConfig(),
  };
}

function getDatabaseConfigFromSecret(secret) {
  return {
    host: secret.host,
    port: Number(secret.port || 5432),
    user: secret.username || secret.user,
    password: secret.password,
    database: secret.dbname || secret.database || "postgres",
    ssl: getSslConfig(),
  };
}

export async function connectDB() {
  if (pool) return pool;

  const envConfig = getDatabaseConfigFromEnv();
  const dbConfig = envConfig || getDatabaseConfigFromSecret(await getSecret());

  pool = new Pool({
    host: dbConfig.host,
    user: dbConfig.user,
    password: dbConfig.password,
    database: dbConfig.database,
    port: dbConfig.port,
    ssl: dbConfig.ssl,
  });

  await pool.query("SELECT 1");

  console.log(
    `✅ Connected to PostgreSQL using ${envConfig ? "environment variables" : "AWS Secrets Manager"}`
  );

  return pool;
}
