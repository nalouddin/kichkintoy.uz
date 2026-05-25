# 🚀 Loyihani ishga tushirish qo'llanmasi

## 📋 Talablar

- **Docker** va **Docker Compose** (backend uchun)
- **Flutter SDK 3.5+** (mobil uchun) — https://flutter.dev
- **Android Studio** yoki **VS Code** (Flutter plagini bilan)
- (Ixtiyoriy) PostgreSQL klient — pgAdmin yoki DBeaver

---

## 1️⃣ Backend ishga tushirish

### Variant A — Docker bilan (tavsiya etiladi)

```bash
cd kichkintoy/backend
cp .env.example .env
docker-compose up -d
```

Hammasi tayyor! Quyidagi xizmatlar ishga tushadi:
- **API**: http://localhost:8000
- **Swagger UI** (avtomatik hujjat): http://localhost:8000/docs
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **MinIO**: http://localhost:9001 (UI), localhost:9000 (API)

### Variant B — Lokal Python bilan

```bash
cd kichkintoy/backend

# Virtual muhit
python -m venv venv
source venv/bin/activate   # Linux/Mac
# venv\Scripts\activate    # Windows

# Paketlar
pip install -r requirements.txt

# Atrof-muhit
cp .env.example .env
# .env faylida DATABASE_URL ni o'z PostgreSQL ga moslang

# Alembic migratsiyalar (DB jadvallarini yaratish)
alembic init alembic
alembic revision --autogenerate -m "initial"
alembic upgrade head

# Serverni ishga tushirish
uvicorn app.main:app --reload
```

### ✅ Tekshirish

Browser'da oching: **http://localhost:8000/docs**

Siz Swagger UI ko'rishingiz kerak. U yerdan barcha API endpointlarni jonli sinab ko'rsangiz bo'ladi.

**Birinchi qadam — test foydalanuvchi yaratish:**
1. `/auth/register` → "Try it out" → quyidagi JSON bilan:
```json
{
  "email": "ota@test.uz",
  "password": "test123",
  "full_name": "Test Ota",
  "role": "parent"
}
```
2. Keyin `/auth/login` orqali tokeningizni oling.

---

## 2️⃣ Frontend ishga tushirish

```bash
cd kichkintoy/frontend

# Paketlarni o'rnatish
flutter pub get

# Emulator yoki real qurilmada ishga tushirish
flutter run
```

### ⚠️ MUHIM — Backend URL ni sozlash

Agar **real qurilmada** test qilsangiz (emulatorda emas), kompyuteringizning IP manzilini bilib oling:

```bash
# Linux/Mac
ifconfig | grep "inet "

# Windows
ipconfig
```

Keyin `lib/core/api_client.dart` faylida o'zgartiring:

```dart
static const String _baseUrl = 'http://SIZNING_IP_MANZILINGIZ:8000/api/v1';
// Misol: 'http://192.168.1.10:8000/api/v1'
```

Android emulator uchun `10.0.2.2` ishlatish kerak (allaqachon sozlangan).

---

## 3️⃣ Birinchi sinov

1. Backend ishga tushganini tekshiring: http://localhost:8000
2. Swagger orqali test ota-ona yarating
3. Flutter ilovasini ishga tushiring
4. "Ota-ona" tugmasini bosing
5. Yangi yaratgan email/parol bilan kiring
6. ✅ Tabriklaymiz! Tizim ishlamoqda

---

## 📊 Loyihaning hozirgi holati

### ✅ Tayyor
- Backend: FastAPI + PostgreSQL skeleton
- 6 ta asosiy model (User, Child, Group, Lesson, Progress, Message)
- JWT autentifikatsiya (register/login/refresh)
- Darslar va natijalar API
- Flutter ilovaning skeleton'i
- Welcome → Login navigatsiyasi
- Bola moduli asosiy ekrani
- **HARFLAR O'YINI to'liq ishlaydi** ✨

### 🚧 Keyingi bosqichlar (sizning navbatingiz)
1. **Alembic migratsiyalar** — DB jadvallarini avtomatik yaratish
2. **Seed data** — boshlang'ich darslar/o'yinlar bilan DB to'ldirish
3. **Qolgan o'yinlar** — Sonlar, Ranglar, Shakllar, Puzzle, Xotira
4. **Audio integratsiyasi** — har harf uchun talaffuz
5. **Bola qo'shish ekrani** (ota-ona uchun)
6. **Guruh boshqaruvi** (pedagog uchun)
7. **Statistika va grafiklar** (fl_chart bilan)
8. **WebSocket chat** (real-time)
9. **Push bildirishnomalar** (Firebase FCM)
10. **Fayl yuklash** (MinIO orqali)

---

## 🐛 Tez-tez uchraydigan muammolar

**"Connection refused" Flutter'da:**
- Emulator ishlatyapsizmi? → `10.0.2.2` to'g'ri
- Real qurilma? → kompyuter IP manzilini yozing
- Bitta WiFi tarmoqda ekanligingizni tekshiring

**"Database connection failed" backend'da:**
- Docker konteynerlari ishga tushdimi? → `docker-compose ps`
- `.env` fayli mavjudmi? → `.env.example` dan nusxa oling

**Flutter paketlari xato beradi:**
- `flutter clean && flutter pub get`
- Flutter versiyasi 3.5+ ekanligini tekshiring: `flutter --version`

---

## 📚 Foydali manbalar

- Flutter: https://docs.flutter.dev
- FastAPI: https://fastapi.tiangolo.com
- SQLAlchemy 2.0: https://docs.sqlalchemy.org
- Riverpod: https://riverpod.dev
