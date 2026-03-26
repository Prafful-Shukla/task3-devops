import express from "express";
import apiRoutes from "./routes/api.js";

const app = express();

app.use("/api", apiRoutes);

app.get("/", (req, res) => {
  res.send("App running 🚀");
});

app.listen(5000, () => {
  console.log("🚀 Server running on port 5000");
});