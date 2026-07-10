require("dotenv").config();
const express = require("express");
const cors = require("cors");
const { pool, checkConnection } = require("./db");

const app = express();
app.use(express.json());
app.use(cors());

const PORT = process.env.APP_PORT || 3000;

// --- Health check: hem uygulamanın hem de harici veritabanının durumunu gösterir ---
app.get("/health", async (req, res) => {
  try {
    await checkConnection();
    res.json({ status: "ok", db: "connected", env: process.env.NODE_ENV || "unknown" });
  } catch (err) {
    res.status(500).json({ status: "error", db: "disconnected", message: err.message });
  }
});

// --- Görevler (tasks) için basit CRUD örneği ---
app.get("/tasks/count", async (req, res) => {
  try {
    const result = await pool.query("SELECT COUNT(*) FROM tasks");
    res.json({ count: parseInt(result.rows[0].count, 10) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
app.get("/tasks", async (req, res) => {
  try {
    const result = await pool.query("SELECT id, title, is_done, created_at FROM tasks ORDER BY id DESC");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/tasks", async (req, res) => {
  const { title } = req.body;
  if (!title || !title.trim()) {
    return res.status(400).json({ error: "title alanı zorunludur" });
  }
  try {
    const result = await pool.query(
      "INSERT INTO tasks (title) VALUES ($1) RETURNING id, title, is_done, created_at",
      [title.trim()]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/tasks/:id/toggle", async (req, res) => {
  try {
    const result = await pool.query(
      "UPDATE tasks SET is_done = NOT is_done WHERE id = $1 RETURNING id, title, is_done, created_at",
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: "Görev bulunamadı" });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/tasks/:id", async (req, res) => {
  try {
    await pool.query("DELETE FROM tasks WHERE id = $1", [req.params.id]);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Sunucu ${PORT} portunda çalışıyor (env: ${process.env.NODE_ENV || "unknown"})`);
});
