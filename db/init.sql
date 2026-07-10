-- Bu şema hem local hem sunucudaki Docker-dışı PostgreSQL kurulumunda
-- migrate.sh script'i aracılığıyla çalıştırılır.
-- IF NOT EXISTS kullanıldığı için tekrar çalıştırmak güvenlidir (idempotent).

CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    is_done BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks (created_at DESC);
