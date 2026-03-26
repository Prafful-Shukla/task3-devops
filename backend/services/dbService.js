import { connectDB } from "../config/db.js";

export async function getTime() {
  const pool = await connectDB();
  const result = await pool.query("SELECT NOW()");
  return result.rows[0];
}