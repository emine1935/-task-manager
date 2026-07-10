# Task Manager — Git Tabanlı Deploy Örneği

Basit bir görev yöneticisi API'si üzerinden **local → git → sunucu** deploy akışını gösteren örnek proje.

- Uygulama: Node.js (Express), Docker container içinde
- Veritabanı: PostgreSQL, Docker **dışında** (hem local hem sunucuda ayrı kurulu)
- Ayarlar: `.env` dosyasında, **commit edilmez**
- Deploy: `deploy.sh` script'i (manuel SSH veya CI/CD ile tetiklenebilir)

## 1) İlk Kurulum (Local)

```bash
# 1. Postgres'i local makinenize kurun (Docker dışında)
#    Ubuntu/Debian: sudo apt install postgresql
#    Mac:           brew install postgresql

# 2. Veritabanı ve kullanıcı oluşturun
sudo -u postgres psql -c "CREATE DATABASE app_db;"
sudo -u postgres psql -c "CREATE USER app_user WITH PASSWORD 'changeme';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE app_db TO app_user;"

# 3. .env dosyanızı oluşturun
cp .env.example .env
# .env içindeki DB_HOST_LOCAL, DB_PORT, DB_USER, DB_PASSWORD değerlerini
# kendi local Postgres kurulumunuza göre düzenleyin.

# 4. Migration'ı çalıştırın (tabloları oluşturur)
chmod +x db/migrate.sh
./db/migrate.sh

# 5. Docker container'ı ayağa kaldırın
docker compose --env-file .env up -d --build

# 6. Test edin
curl http://localhost:3000/health
```

## 2) Sunucu Kurulumu (İlk Sefer)

```bash
# 1. Sunucuya PostgreSQL kurun (yine Docker dışında, local'dekiyle aynı adımlar)

# 2. Projeyi sunucuya klonlayın
git clone <repo-url> /opt/task-manager
cd /opt/task-manager

# 3. Sunucuya özel .env dosyasını oluşturun
cp .env.example .env
nano .env
# DB_HOST -> host.docker.internal (veya sunucunuzun Docker ağı ayarına göre)
# DB_HOST_LOCAL, DB_USER, DB_PASSWORD -> sunucudaki gerçek Postgres bilgileri
# APP_PORT -> sunucuda kullanılacak port
# NODE_ENV=production

# 4. deploy.sh'a çalıştırma izni verin
chmod +x deploy.sh db/migrate.sh

# 5. İlk deploy'u çalıştırın
./deploy.sh main
```

## 3) Sonraki Her Deploy

**Local'de:**
```bash
git add .
git commit -m "Değişiklik açıklaması"
git push origin main
```

**Sunucuda (manuel yöntem):**
```bash
ssh kullanici@sunucu-ip
cd /opt/task-manager
./deploy.sh main
```

**CI/CD ile otomatik (opsiyonel):**
`.github/workflows/deploy.yml` dosyasındaki GitHub Secrets'ları tanımlarsanız,
`main` branch'ine her push sonrası deploy otomatik tetiklenir. İstemiyorsanız
bu workflow dosyasını silip sadece manuel SSH yöntemini kullanabilirsiniz.

## API Uçları

| Method | Endpoint            | Açıklama                        |
|--------|----------------------|----------------------------------|
| GET    | `/health`             | Uygulama ve DB bağlantı durumu  |
| GET    | `/tasks`              | Tüm görevleri listeler          |
| POST   | `/tasks`              | Yeni görev ekler (`{"title": "..."}`) |
| PATCH  | `/tasks/:id/toggle`   | Görevi tamamlandı/tamamlanmadı yapar |
| DELETE | `/tasks/:id`          | Görevi siler                     |

## Önemli Notlar

- **`.env` dosyasını asla commit etmeyin.** `.gitignore` içinde zaten hariç tutuluyor.
- Local ve sunucu `.env` dosyaları birbirinden tamamen bağımsızdır; her makine kendi IP/port/şifre bilgilerini tutar.
- Veritabanı Docker'da DEĞİLDİR — container yeniden build edilse bile verileriniz etkilenmez.
- `DB_HOST` (container için) ile `DB_HOST_LOCAL` (host script'leri için) farklı olabilir; bkz. `.env.example` açıklamaları.
