
# Task Manager - Git Tabanli Otomatik Deploy Sistemi

> Bir uygulamanin local gelistirme ortamindan, Docker + Git tabanli otomatik bir is akisiyla sunucuya (production) guvenli ve tekrarlanabilir sekilde tasinmasini gosteren ornek bir proje.

---

## Icindekiler

- [Genel Bakis](#genel-bakis)
- [Ozellikler](#ozellikler)
- [Mimari](#mimari)
- [Teknoloji Yigini](#teknoloji-yigini)
- [Proje Yapisi](#proje-yapisi)
- [Gereksinimler](#gereksinimler)
- [Kurulum](#kurulum)
  - [1. Local Kurulum](#1-local-kurulum)
  - [2. Sunucu Kurulumu](#2-sunucu-kurulumu)
- [Ortam Degiskenleri (.env)](#ortam-degiskenleri-env)
- [API Referansi](#api-referansi)
- [Deploy Akisi](#deploy-akisi)
- [Guvenlik](#guvenlik)
- [Sorun Giderme](#sorun-giderme)
- [Lisans](#lisans)

---

## Genel Bakis

Bu proje, basit bir **Gorev Yoneticisi (Task Manager)** uygulamasi uzerinden su senaryoyu uctan uca gosterir:

1. Kod **local** makinede yazilir ve Git ile commit'lenir.
2. `git push` ile GitHub'daki uzak depoya gonderilir.
3. **Sunucu** bu degisikligi `git pull` ile ceker ve tek bir script (`deploy.sh`) ile otomatik olarak yeniden yayina alir.
4. **Veritabani** (PostgreSQL) hem local hem sunucuda Docker'in **disinda**, isletim sistemine dogrudan kuruludur - diger tum bilesenler (backend API) Docker container'i icinde calisir.
5. IP, port ve sifre gibi tum hassas ayarlar, her makineye ozel bir `.env` dosyasinda tutulur ve **hicbir zaman Git'e commit edilmez**.

Uygulamanin kendisi basit bir gorev yoneticisidir (ekleme, tamamlama, silme) - asil amac, arkasindaki **deploy altyapisini** gostermektir.

---

## Ozellikler

- Gorev ekleme, listeleme, tamamlama ve silme (REST API + gorsel arayuz)
- Defter temali, sade ve responsive bir web arayuzu
- Docker Compose ile tek komutla ayaga kalkan backend
- Docker disinda, bagimsiz ve kalici PostgreSQL veritabani
- Git tabanli, tek script ile otomatik sunucu deploy'u
- Makineye ozel `.env` dosyalari - commit'lere asla dahil olmaz
- Opsiyonel CI/CD destegi (GitHub Actions ile SSH uzerinden otomatik deploy)

---

## Mimari
+-----------------------------+          +-----------------------------+
|        LOCAL MAKINE          |          |      SUNUCU (PRODUCTION)     |
|                               |          |                               |
|  +---------------------+     |   git    |  +---------------------+     |
|  |  Docker Container     |     |   push   |  |  Docker Container     |     |
|  |  +-----------------+  |     | -------> |  |  +-----------------+  |     |
|  |  | Backend (Node.js)|  |     |          |  |  | Backend (Node.js)|  |     |
|  |  | + Gorsel Arayuz  |  |     |   git    |  |  | + Gorsel Arayuz  |  |     |
|  |  +--------+--------+  |     |   pull   |  |  +--------+--------+  |     |
|  +-----------|----------+     | <------- |  +-----------|----------+     |
|              |                 |          |              |                |
|  +-----------v----------+     |          |  +-----------v----------+     |
|  |  PostgreSQL            |     |          |  |  PostgreSQL            |     |
|  |  (Docker DISINDA)      |     |          |  |  (Docker DISINDA)      |     |
|  +-----------------------+     |          |  +-----------------------+     |
|                               |          |                               |
|  .env (local ayarlari)       |          |  .env (sunucu ayarlari)      |
+-----------------------------+          +-----------------------------+

**Onemli:** Veritabani her iki makinede de birbirinden tamamen izole calisir. Container yeniden build edildiginde veritabani ve verileri etkilenmez.

---

## Teknoloji Yigini

| Katman | Teknoloji |
|---|---|
| Backend | Node.js + Express |
| Veritabani | PostgreSQL (Docker disinda) |
| Container | Docker + Docker Compose |
| Frontend | HTML / CSS / Vanilla JavaScript |
| Versiyon Kontrolu | Git + GitHub |
| Deploy | Bash script (deploy.sh) + SSH |
| CI/CD (opsiyonel) | GitHub Actions |

---

## Proje Yapisi
proje/
|-- backend/
|   |-- server.js          # Express sunucu, API endpoint'leri
|   |-- db.js               # PostgreSQL baglanti havuzu
|   |-- package.json        # npm bagimliliklari
|   |-- Dockerfile          # Backend Docker imaj tanimi
|   |-- .dockerignore
|   -- public/ |       -- index.html      # Gorsel arayuz (frontend)
|-- db/
|   |-- init.sql            # Veritabani semasi
|   -- migrate.sh          # Migration calistirma script'i |-- .github/workflows/ |   -- deploy.yml          # Opsiyonel CI/CD tanimi
|-- docker-compose.yml       # Uygulama servisi tanimi (DB haric)
|-- .env.example             # Ortam degiskenleri sablonu (commit edilir)
|-- .env                     # Gercek ayarlar (commit EDILMEZ)
|-- .gitignore
|-- deploy.sh                 # Sunucuda calisan ana deploy script'i
`-- README.md

---

## Gereksinimler

- Git - https://git-scm.com/
- Node.js (LTS surum) - https://nodejs.org/
- Docker Desktop - https://www.docker.com/products/docker-desktop/
- PostgreSQL - https://www.postgresql.org/download/

---

## Kurulum

### 1. Local Kurulum

```bash
# 1) PostgreSQL'i local makinenize kurun (Docker disinda)

# 2) Veritabani ve kullanici olusturun
psql -U postgres -c "CREATE DATABASE app_db;"
psql -U postgres -c "CREATE USER app_user WITH PASSWORD 'changeme';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE app_db TO app_user;"
psql -U postgres -d app_db -c "GRANT ALL ON SCHEMA public TO app_user;"

# 3) .env dosyanizi olusturun
cp .env.example .env
# .env icindeki DB_HOST_LOCAL, DB_PORT, DB_USER, DB_PASSWORD degerlerini duzenleyin

# 4) Migration'i calistirin (tablolari olusturur)
chmod +x db/migrate.sh
./db/migrate.sh

# 5) Docker container'i ayaga kaldirin
docker compose --env-file .env up -d --build

# 6) Test edin
curl http://localhost:3000/health
```

Tarayicidan `http://localhost:3000` adresine giderek gorsel arayuzu gorebilirsiniz.

### 2. Sunucu Kurulumu

```bash
# 1) Sunucuya PostgreSQL kurun (yine Docker disinda)

# 2) Projeyi klonlayin
git clone <repo-url> /opt/task-manager
cd /opt/task-manager

# 3) Sunucuya ozel .env dosyasini olusturun
cp .env.example .env
nano .env
# DB_HOST -> host.docker.internal
# DB_HOST_LOCAL, DB_USER, DB_PASSWORD -> sunucudaki gercek bilgiler
# APP_PORT -> sunucuda kullanilacak port
# NODE_ENV=production

# 4) Deploy script'ine calistirma izni verin ve ilk deploy'u yapin
chmod +x deploy.sh db/migrate.sh
./deploy.sh main
```

**Sonraki her guncelleme icin**, sunucuda yalnizca sunu calistirmaniz yeterlidir:

```bash
./deploy.sh main
```

---

## Ortam Degiskenleri (.env)

| Degisken | Aciklama | Ornek |
|---|---|---|
| `NODE_ENV` | Ortam tipi | `development` / `production` |
| `APP_PORT` | Uygulamanin disa acacagi port | `3000` |
| `DB_HOST` | Container icinden host'a erisim adresi | `host.docker.internal` |
| `DB_HOST_LOCAL` | Host uzerinde calisan script'ler icin adres | `127.0.0.1` |
| `DB_PORT` | PostgreSQL portu | `5432` |
| `DB_NAME` | Veritabani adi | `app_db` |
| `DB_USER` | Veritabani kullanicisi | `app_user` |
| `DB_PASSWORD` | Veritabani sifresi | `changeme` |

> NOT: `.env` dosyasi `.gitignore` icinde tanimlidir ve **asla** commit edilmemelidir. Sadece `.env.example` (sablon) Git'e dahildir.

---

## API Referansi

| Method | Endpoint | Aciklama |
|---|---|---|
| GET | `/health` | Uygulama ve veritabani baglanti durumu |
| GET | `/tasks` | Tum gorevleri listeler |
| POST | `/tasks` | Yeni gorev ekler - body: `{"title": "..."}` |
| PATCH | `/tasks/:id/toggle` | Gorevi tamamlandi/tamamlanmadi yapar |
| DELETE | `/tasks/:id` | Gorevi siler |
| GET | `/tasks/count` | Toplam gorev sayisini doner |

---

## Deploy Akisi

Local'de kod yazilir ve test edilir
|
v
git add . && git commit -m "..." && git push
|
v
Sunucuda: ./deploy.sh main
|
|--> git pull origin main
|--> Veritabani migration'lari calistirilir
|--> docker compose down && up -d --build
|--> Kullanilmayan imajlar temizlenir
`--> /health endpoint'i ile otomatik dogrulama


Deploy, istege bagli olarak **manuel SSH** ile veya `.github/workflows/deploy.yml` uzerinden **CI/CD** ile tetiklenebilir.

---

## Guvenlik

- `.env` dosyalari `.gitignore` ile Git'ten tamamen haric tutulur.
- Local ve sunucu ayarlari birbirinden bagimsizdir; her makine kendi IP/port/sifre bilgilerini tasir.
- Sadece `.env.example` (gercek degerler olmadan, sablon halinde) Git'e dahildir.
- Veritabani erisimi Docker disinda tutularak, container yeniden build edilse bile veriler korunur.

---

## Sorun Giderme

Gelistirme surecinde karsilasilan bazi yaygin sorunlar ve cozumleri:

| Sorun | Cozum |
|---|---|
| `permission denied for schema public` | PostgreSQL 15+ surumlerinde varsayilan izin kaldirilmistir. `postgres` kullanicisiyla baglanip `GRANT ALL ON SCHEMA public TO app_user;` calistirin. |
| `psql` komutu taninmiyor | PostgreSQL `bin` klasorunu (orn. `C:\Program Files\PostgreSQL\18\bin`) sistem PATH'ine ekleyin. |
| Docker container isim catismasi | `docker-compose.yml` icinde sabit bir `container_name` varsa kaldirin; Docker Compose otomatik, proje bazli isimlendirme kullansin. |
| `.env` icindeki Turkce karakterler bozuluyor | Dosyayi UTF-8 kodlamasiyla kaydedin (`Set-Content -Encoding UTF8` veya editorde "UTF-8" secenegi). |
| Container, beklenen veritabanina baglanmiyor | `DB_HOST` (container icin) ile `DB_HOST_LOCAL` (host script'leri icin) degerlerinin dogru ayristirildigindan emin olun. |

---

## Lisans

Bu proje egitim/staj amacli gelistirilmistir.

---

**Not:** Bu README, projenin teknik dokumantasyonudur. Kullanilan teknolojilerin ve karsilasilan sorunlarin daha detayli bir dokumu icin proje ile birlikte paylasilan rapor dosyasina bakiniz.
