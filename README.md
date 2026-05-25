# 🎓 Kichkintoy Connect — Maktabgacha ta'lim platformasi

## 📱 Loyiha haqida

Maktabgacha yoshdagi (3–7 yosh) bolalar uchun **3 tomonni bog'lovchi mobil platforma**:
- 👶 **Bola** — o'yin orqali ta'lim oladi
- 👩‍🏫 **Pedagog** — topshiriq beradi, monitoring qiladi
- 👨‍👩‍👧 **Ota-ona** — bola rivojlanishini kuzatadi

---

## 🛠 Texnologik stek

| Qatlam | Texnologiya | Sababi |
|--------|-------------|--------|
| **Mobil ilova** | Flutter 3.x (Dart) | Bitta kod — Android + iOS |
| **Backend** | Python + FastAPI | Tez, zamonaviy, async, avtomatik Swagger |
| **Ma'lumotlar bazasi** | PostgreSQL 15 | Ishonchli, relyatsion ma'lumotlar uchun ideal |
| **ORM** | SQLAlchemy 2.0 + Alembic | Migratsiyalar boshqaruvi |
| **Autentifikatsiya** | JWT (JSON Web Tokens) | Stateless, mobil uchun qulay |
| **Fayl saqlash** | MinIO yoki AWS S3 | Audio, video, rasm fayllar uchun |
| **Real-time chat** | WebSocket (FastAPI native) | Ota-ona ↔ Pedagog muloqoti |
| **Push bildirishnomalar** | Firebase Cloud Messaging | Bepul, ishonchli |
| **Keshlash** | Redis | Sessiya va tez-tez ishlatiladigan ma'lumotlar |
| **Konteynerlash** | Docker + docker-compose | Oson deploy |

---

## 🏗 Arxitektura

```
┌─────────────────────────────────────────────────────────┐
│                  FLUTTER MOBILE APP                      │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────────┐ │
│  │ Bola UI    │  │ Pedagog UI  │  │  Ota-ona UI      │ │
│  └────────────┘  └─────────────┘  └──────────────────┘ │
└──────────────────────────┬──────────────────────────────┘
                           │ HTTPS + WebSocket
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    FASTAPI BACKEND                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐│
│  │  Auth    │ │ Lessons  │ │  Chat    │ │ Monitoring ││
│  │ Service  │ │ Service  │ │ Service  │ │  Service   ││
│  └──────────┘ └──────────┘ └──────────┘ └────────────┘│
└──────┬─────────────┬──────────────┬──────────────┬─────┘
       │             │              │              │
       ▼             ▼              ▼              ▼
  ┌─────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │PostgreSQL│  │  Redis   │  │  MinIO   │  │ Firebase ││
  │   DB    │  │  Cache   │  │  Files   │  │  FCM     │
  └─────────┘  └──────────┘  └──────────┘  └──────────┘
```

---

## 📁 Loyiha tuzilmasi

```
kichkintoy/
├── backend/                    # FastAPI server
│   ├── app/
│   │   ├── api/               # API endpointlar
│   │   │   ├── v1/
│   │   │   │   ├── auth.py
│   │   │   │   ├── children.py
│   │   │   │   ├── lessons.py
│   │   │   │   ├── teachers.py
│   │   │   │   ├── parents.py
│   │   │   │   ├── chat.py
│   │   │   │   └── reports.py
│   │   ├── core/              # Konfiguratsiya, xavfsizlik
│   │   │   ├── config.py
│   │   │   ├── security.py
│   │   │   └── database.py
│   │   ├── models/            # SQLAlchemy modellar
│   │   │   ├── user.py
│   │   │   ├── child.py
│   │   │   ├── lesson.py
│   │   │   ├── progress.py
│   │   │   └── message.py
│   │   ├── schemas/           # Pydantic sxemalar
│   │   ├── services/          # Biznes logika
│   │   ├── main.py            # Asosiy entry point
│   │   └── dependencies.py
│   ├── alembic/               # DB migratsiyalar
│   ├── tests/
│   ├── requirements.txt
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── frontend/                   # Flutter ilova
│   ├── lib/
│   │   ├── core/              # API client, konstantalar
│   │   ├── features/
│   │   │   ├── auth/          # Login, ro'yxatdan o'tish
│   │   │   ├── child/         # Bola moduli
│   │   │   │   ├── games/
│   │   │   │   │   ├── letters/
│   │   │   │   │   ├── numbers/
│   │   │   │   │   ├── colors/
│   │   │   │   │   └── shapes/
│   │   │   │   └── stories/
│   │   │   ├── teacher/       # Pedagog moduli
│   │   │   └── parent/        # Ota-ona moduli
│   │   ├── shared/            # Umumiy widgetlar
│   │   └── main.dart
│   ├── assets/
│   │   ├── images/
│   │   ├── audio/
│   │   └── animations/
│   └── pubspec.yaml
│
└── docs/                       # Hujjatlar
    ├── api.md
    └── database.md
```

---

## 🗂 Ma'lumotlar bazasi sxemasi (asosiy jadvallar)

### `users` — Barcha foydalanuvchilar (umumiy)
| Ustun | Tur | Tavsif |
|-------|-----|--------|
| id | UUID | PK |
| email | VARCHAR | Unique |
| phone | VARCHAR | Unique |
| password_hash | VARCHAR | bcrypt |
| role | ENUM | `child`, `parent`, `teacher`, `admin` |
| full_name | VARCHAR | |
| avatar_url | VARCHAR | |
| created_at | TIMESTAMP | |

### `children` — Bolalar profili
| Ustun | Tur | Tavsif |
|-------|-----|--------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| parent_id | UUID | FK → users (ota-ona) |
| birth_date | DATE | |
| age_group | INTEGER | 3, 4, 5, 6, 7 |
| group_id | UUID | FK → groups (pedagog guruhi) |
| avatar_url | VARCHAR | |

### `groups` — Pedagog guruhlari
| Ustun | Tur | Tavsif |
|-------|-----|--------|
| id | UUID | PK |
| teacher_id | UUID | FK → users |
| name | VARCHAR | "Quyoshcha guruhi" |
| age_group | INTEGER | |

### `lessons` — Darslar va o'yinlar
| Ustun | Tur | Tavsif |
|-------|-----|--------|
| id | UUID | PK |
| title | VARCHAR | "Harflarni o'rganamiz" |
| category | ENUM | `letters`, `numbers`, `colors`, `shapes`, `memory`, `story` |
| age_group | INTEGER | |
| content_url | VARCHAR | Audio/video/JSON konfiguratsiya |
| difficulty | INTEGER | 1-5 |
| order | INTEGER | Ketma-ketlik |

### `assignments` — Pedagog tomonidan berilgan topshiriqlar
| Ustun | Tur | Tavsif |
|-------|-----|--------|
| id | UUID | PK |
| teacher_id | UUID | FK → users |
| group_id | UUID | FK → groups |
| lesson_id | UUID | FK → lessons |
| due_date | TIMESTAMP | |
| created_at | TIMESTAMP | |

### `progress` — Bola natijalari
| Ustun | Tur | Tavsif |
|-------|-----|--------|
| id | UUID | PK |
| child_id | UUID | FK → children |
| lesson_id | UUID | FK → lessons |
| score | INTEGER | 0-100 |
| time_spent | INTEGER | Soniyada |
| completed_at | TIMESTAMP | |
| attempts | INTEGER | Necha marta urinilgan |

### `messages` — Chat xabarlari
| Ustun | Tur | Tavsif |
|-------|-----|--------|
| id | UUID | PK |
| sender_id | UUID | FK → users |
| receiver_id | UUID | FK → users |
| content | TEXT | |
| message_type | ENUM | `text`, `voice`, `image` |
| is_read | BOOLEAN | |
| created_at | TIMESTAMP | |

### `competencies` — Kompetensiyalar (baholash uchun)
| Ustun | Tur | Tavsif |
|-------|-----|--------|
| id | UUID | PK |
| child_id | UUID | FK → children |
| competency_type | ENUM | `speech`, `attention`, `memory`, `motor`, `social` |
| level | INTEGER | 1-10 |
| updated_at | TIMESTAMP | |

---

## 🚀 Ishlab chiqish bosqichlari (Roadmap)

### **Bosqich 1 — Asos (2-3 hafta)**
- ✅ Backend: FastAPI loyihasini sozlash
- ✅ PostgreSQL ulanish, modellar, migratsiyalar
- ✅ JWT autentifikatsiya (3 ta rol: bola/ota-ona/pedagog)
- ✅ Flutter loyihasini sozlash, navigatsiya
- ✅ Login/Ro'yxatdan o'tish ekranlari

### **Bosqich 2 — Bola moduli (3-4 hafta)**
- 🎮 Harflar o'yini (A–Anor, audio)
- 🔢 Sonlar o'yini (1–20, sanash)
- 🎨 Ranglar va shakllar o'yini
- 🧩 Xotira va puzzle o'yinlari
- 📊 Har bir o'yin natijasi serverga yuboriladi

### **Bosqich 3 — Pedagog moduli (2-3 hafta)**
- 👥 Guruh yaratish va boshqarish
- 📝 Topshiriq yuklash
- 📈 Bolalar monitoringi (grafik)
- ✅ Baholash tizimi

### **Bosqich 4 — Ota-ona moduli (2 hafta)**
- 📊 Bola statistikasi (grafik)
- 📅 Kunlik faoliyat ko'rinishi
- ⏱ Ekran vaqti nazorati

### **Bosqich 5 — Muloqot (2 hafta)**
- 💬 WebSocket real-time chat
- 🎤 Ovozli xabar
- 📞 Video qo'ng'iroq (WebRTC yoki Agora)

### **Bosqich 6 — Test va Deploy (2 hafta)**
- 🧪 Unit va integration testlar
- 🚢 Docker, CI/CD
- 📱 Google Play / App Store

**Jami: ~3-4 oy** to'liq MVP uchun.
# kichkintoy.uz
