import express from "express";
import { connectDB } from "../config/db.js";

const router = express.Router();

router.get("/test-db", async (req, res) => {
  try {
    const pool = await connectDB();

    const result = await pool.query("SELECT NOW()");
    res.json({
      success: true,
      time: result.rows[0],
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

export default router;