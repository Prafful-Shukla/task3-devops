import pkg from "pg";
const { Pool } = pkg;
import { getSecret } from "./secrets.js";

let pool;

export async function connectDB() {
  if (pool) return pool;

  const secret = await getSecret();

  pool = new Pool({
  host: secret.host,
  user: secret.username,
  password: secret.password,
  database: secret.dbname || "postgres",
  port: secret.port,
  ssl: {
    rejectUnauthorized: false,
  },
});

  await pool.query("SELECT 1"); // test connection

  console.log("✅ Connected to PostgreSQL");

  return pool;
}