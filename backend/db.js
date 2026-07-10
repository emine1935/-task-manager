const { Pool } = require("pg");

// Bu değişkenler container'a docker-compose.yml üzerinden .env dosyasından geçirilir.
// Not: DB_HOST burada container İÇİNDEN host makinedeki (Docker dışı) Postgres'e
// erişmek için kullanılır (örn. host.docker.internal). Host üzerinde doğrudan
// çalışan script'ler (migrate.sh gibi) için DB_HOST_LOCAL kullanılır.
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 10,
  idleTimeoutMillis: 30000,
});

pool.on("error", (err) => {
  console.error("Beklenmeyen veritabanı havuzu hatası:", err.message);
});

async function checkConnection() {
  const client = await pool.connect();
  try {
    await client.query("SELECT 1");
    return true;
  } finally {
    client.release();
  }
}

module.exports = { pool, checkConnection };
