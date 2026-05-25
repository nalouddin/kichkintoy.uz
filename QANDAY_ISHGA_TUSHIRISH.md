# 🚀 Windows uchun loyihani ishga tushirish — to'liq qo'llanma

Hech narsa o'rnatilmagan Windows kompyuterda 0 dan boshlab loyihani ishga tushirish.

**Taxminan vaqt:** 1-2 soat (yuklab olish vaqtiga bog'liq)

---

## 📋 BOSQICH 1 — Kerakli dasturlar (taxminan 45 daqiqa)

### 1.1 — Docker Desktop o'rnatish (BACKEND uchun)

**Nima va nima uchun:** Docker — bu Python, PostgreSQL, Redis va boshqalarni qutulardagi (konteyner) ichida ishlatadigan dastur. Sizga ulardan birortasini alohida o'rnatish kerak emas.

**Qadamlar:**
1. https://www.docker.com/products/docker-desktop sahifasini oching
2. **"Download for Windows"** tugmasini bosing
3. `Docker Desktop Installer.exe` faylini yuklab oling (~700 MB)
4. Faylni ishga tushiring, hammasiga "Next" bosing
5. ⚠️ **Use WSL 2 instead of Hyper-V** ga belgi qo'ying (default tanlangan)
6. O'rnatish tugagach, kompyuterni **qayta ishga tushiring**
7. Qayta ochilganda Docker Desktop avtomatik ishga tushadi
8. Docker logosi tray'da yashil bo'lib turadi: "Engine running"

**WSL 2 muammosi chiqsa:**
PowerShell'ni **Administrator** sifatida oching va yozing:
```powershell
wsl --install
wsl --update
```
Keyin kompyuterni qayta ishga tushiring.

**Tekshirish:**
PowerShell'ni oching va yozing:
```powershell
docker --version
docker compose version
```
Ikkala buyruq versiya raqamini ko'rsatishi kerak.

---

### 1.2 — Git o'rnatish (kodni boshqarish uchun)

1. https://git-scm.com/download/win sahifasiga kiring
2. Avtomatik yuklab olinadi, ishga tushiring
3. Hammasiga "Next" — default sozlamalar yetarli
4. **Tekshirish:** PowerShell'da `git --version`

---

### 1.3 — Flutter SDK o'rnatish (FRONTEND uchun)

**Nima va nima uchun:** Flutter — mobil ilova yaratish vositasi.

**Qadamlar:**

1. https://docs.flutter.dev/get-started/install/windows/mobile sahifasini oching
2. **"flutter_windows_X.X.X-stable.zip"** faylini yuklab oling (~1 GB)
3. Yuklab olingan ZIP'ni **`C:\src\flutter`** papkasiga oching
   - ⚠️ MUHIM: yo'lda **bo'sh joy** va **maxsus belgilar** bo'lmasin (`Program Files` da saqlamang!)
4. Windows qidiruvga "environment variables" yozing → **"Edit the system environment variables"**
5. **"Environment Variables..."** tugmasini bosing
6. Yuqori qismda "User variables" → **Path** ni tanlang → **Edit**
7. **New** → **`C:\src\flutter\bin`** ni qo'shing
8. OK, OK, OK
9. ⚠️ Barcha terminal va dasturlarni **yopib qayta oching**

**Tekshirish:**
Yangi PowerShell'da:
```powershell
flutter --version
```
Versiya raqamini ko'rsatishi kerak.

---

### 1.4 — Android Studio o'rnatish

**Nima va nima uchun:** Android emulator (telefon simulyatori) va Android SDK uchun kerak.

1. https://developer.android.com/studio sahifasiga kiring
2. **"Download Android Studio"** tugmasini bosing
3. ~1 GB faylni yuklab oling
4. Ishga tushiring, hammasiga "Next" bosing
5. Birinchi ochilganda **"Standard"** o'rnatishni tanlang
6. **Android SDK**, **Android Virtual Device** va boshqalarni yuklab oladi (~5 GB) — uzoq vaqt ketadi
7. Tugagach, ochiq qoldiring

---

### 1.5 — Android emulator yaratish

Android Studio ochiq holatida:

1. Birorta loyiha ochib kerak emas — boshlang'ich oynada **"More Actions"** (yoki uch nuqta) → **"Virtual Device Manager"** ni bosing
2. **"Create Device"** ni bosing
3. **Pixel 5** yoki **Pixel 7** ni tanlang → Next
4. **API 34 (UpsideDownCake)** yoki yangirog'ini tanlang (yuklab olinadi)
5. Next → Finish
6. Yaratilgan device yonidagi ▶️ tugmasini bosib ishga tushiring
7. Telefon ekrani Windowsda paydo bo'ladi

**Tekshirish:**
PowerShell'da:
```powershell
flutter devices
```
Emulator ro'yxatda chiqishi kerak.

---

### 1.6 — Flutter Doctor — hamma narsa joyidami?

```powershell
flutter doctor
```

Quyidagilar yashil `[✓]` bo'lishi kerak:
- ✓ Flutter
- ✓ Windows Version
- ✓ Android toolchain
- ✓ Connected device (kamida 1 ta)

❌ chiqsa, terminaldagi tavsiyalarni bajaring. Eng ko'p uchraydigan muammo — **Android licenses qabul qilinmagan**:
```powershell
flutter doctor --android-licenses
```
Hamma savollarga **`y`** bosing.

---

### 1.7 — VS Code o'rnatish (kod yozish uchun)

1. https://code.visualstudio.com/ → Download → o'rnating
2. Ochib, **Extensions** (chap menyu) ga kiring
3. Quyidagi extensionlarni o'rnating:
   - **Flutter** (Dart-Code tomonidan)
   - **Dart**
   - **Python** (Microsoft tomonidan)

---

## 📦 BOSQICH 2 — Loyihani ochish

1. ZIP faylni biror papkaga oching (masalan: `C:\Users\SizningIsm\Documents\kichkintoy`)
2. VS Code'ni oching → **File → Open Folder** → `kichkintoy` papkasini tanlang

---

## 🐳 BOSQICH 3 — Backend'ni ishga tushirish

VS Code'da **Terminal → New Terminal** (yoki `Ctrl+~`).

### 3.1 — backend papkasiga o'tish

```powershell
cd backend
```

### 3.2 — `.env` fayl yaratish

```powershell
copy .env.example .env
```

### 3.3 — Docker Compose ishga tushirish

⚠️ Avval **Docker Desktop ochilganini** tekshiring (tray'da yashil).

```powershell
docker compose up -d --build
```

**Birinchi marta 5-10 daqiqa** vaqt oladi. Quyidagilar ketma-ket yuz beradi:
1. PostgreSQL image yuklanadi
2. Redis image yuklanadi
3. Python image yuklanadi va backend quriladi
4. Migratsiya bajariladi (jadvallar yaratiladi)
5. Seed ishlaydi (test foydalanuvchilar va darslar qo'shiladi)
6. Server 8000 portda ishga tushadi

### 3.4 — Loglarni kuzatish

```powershell
docker compose logs -f backend
```

Quyidagilarni ko'rishingiz kerak:
```
✅ Yaratildi: ota@test.uz / test123
✅ Yaratildi: pedagog@test.uz / test123
✅ 9 ta dars yaratildi
🚀 Kichkintoy Connect ishga tushdi
```

`Ctrl+C` bilan loglardan chiqing (server o'chmaydi).

### 3.5 — Browser'da tekshirish

Browser'da oching: **http://localhost:8000**

Quyidagicha javob ko'rishingiz kerak:
```json
{"app": "Kichkintoy Connect", "version": "0.2.0", "status": "ishlayapti"}
```

API hujjati: **http://localhost:8000/docs**

✅ Backend tayyor!

### Docker buyruqlari:

```powershell
docker compose ps              # Holat
docker compose stop            # To'xtatish
docker compose start           # Qayta ishga tushirish
docker compose down            # Butunlay o'chirish (DB saqlanadi)
docker compose down -v         # Hammasini o'chirish (DB ham o'chadi!)
docker compose logs -f backend # Backend loglar
```

---

## 📱 BOSQICH 4 — Frontend'ni ishga tushirish

Yangi terminal oching (Ctrl+Shift+~) yoki avvalgisini ishlatib boring.

### 4.1 — frontend papkasiga o'tish

```powershell
cd ..\frontend
```

### 4.2 — Flutter paketlarini yuklab olish

```powershell
flutter pub get
```

5-10 daqiqa kutasiz — internetdan paketlarni yuklab oladi.

### 4.3 — Emulator yoki telefonni ulang

**Variant A — Emulator:** Android Studio orqali ishga tushiring (yuqorida ko'rsatilgan)

**Variant B — Real telefon:**
1. Telefonda **Settings → About phone → Build number** ni 7 marta bosing
2. **Developer options → USB debugging** yoqing
3. USB kabel orqali kompyuterga ulang
4. Telefonda chiqqan "Allow USB debugging" so'rovini tasdiqlang

**Tekshirish:**
```powershell
flutter devices
```

### 4.4 — Backend manzilini sozlash

⚠️ **MUHIM!** Bu joyda ko'pchilik adashadi.

`lib/core/api_client.dart` faylini oching. Yuqori qismida:

```dart
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
static const String wsUrl = 'ws://10.0.2.2:8000/api/v1/chat/ws';
```

**Agar emulator ishlatsangiz** — hech narsa o'zgartirmang, `10.0.2.2` to'g'ri (bu emulator uchun "localhost").

**Agar real telefon ishlatsangiz** — kompyuter IP manzilini topish:
```powershell
ipconfig
```

Natijadagi "Wireless LAN adapter Wi-Fi" qismida "IPv4 Address" — masalan `192.168.1.10`.

Keyin `api_client.dart` da o'zgartiring:
```dart
static const String baseUrl = 'http://192.168.1.10:8000/api/v1';
static const String wsUrl = 'ws://192.168.1.10:8000/api/v1/chat/ws';
```

⚠️ Telefon va kompyuter **bitta WiFi tarmoqda** bo'lishi shart!

### 4.5 — Ilovani ishga tushirish

```powershell
flutter run
```

⏱ Birinchi marta **5-15 daqiqa** — Android build qiladi.

Tugagach, emulator yoki telefonda ilova ochiladi.

**Hot reload:** Kod o'zgartirsangiz, terminalda `r` (kichik) bosing — ilova tezda qayta yuklanadi.

---

## ✅ BOSQICH 5 — Test qilish

### Test akkauntlari (seed avtomatik yaratgan):

| Rol | Login | Parol |
|-----|-------|-------|
| 👨‍👩‍👧 Ota-ona | `ota@test.uz` | `test123` |
| 👩‍🏫 Pedagog | `pedagog@test.uz` | `test123` |
| 👨‍💼 Admin | `admin@kichkintoy.uz` | `admin123` |

### Test ssenariy:

**1) Ota-ona sifatida kirish:**
- Welcome ekran → "Ota-ona" tugmasi
- `ota@test.uz` / `test123` → KIRISH
- "BOLA QO'SHISH" → ismi, sana, parol kiriting
- Bola qo'shilgach, login va parol ko'rsatiladi — yozib oling!

**2) Bola sifatida kirish:**
- Telefonni qayta yoqing yoki "Chiqish"
- Welcome → "Bola" tugmasi
- Ota-onadan olgan login/parolingiz bilan kiring
- O'yinlarni o'ynang (Harflar, Sonlar, Ranglar, Shakllar, Xotira, Jumboq)

**3) Ota-ona statistikani ko'rishi:**
- Yana ota-ona sifatida kiring
- Bola ustiga bosing → statistika va grafiklar ochiladi

**4) Pedagog sifatida:**
- Pedagog → guruh yaratish → bolani ushbu guruhga ulash (backend orqali)

**5) Chat:**
- Yuqorida chat ikonkasi → suhbat boshlash

---

## 🐛 Eng ko'p uchraydigan muammolar

### "docker: command not found"
Docker Desktop o'rnatilmagan yoki PATH'da yo'q. Qayta o'rnating va kompyuterni qayta yoqing.

### "Cannot connect to Docker daemon"
Docker Desktop **ochilmagan**. Tray'da Docker logosi yashil bo'lguncha kuting.

### Port 5432 yoki 8000 band
Boshqa dastur shu portni ishlatyapti. Quyidagicha topib o'chiring:
```powershell
netstat -ano | findstr :8000
# Topilgan PID raqamini ishlatib:
taskkill /PID <PID_RAQAMI> /F
```

### Flutter "Connection refused"
- Backend ishlayaptimi? `http://localhost:8000` ni browser'da ochib ko'ring
- `api_client.dart` da **to'g'ri IP** yozilganmi?
- Telefon va kompyuter **bitta WiFi'da**mi?
- Windows Firewall 8000 portni bloklamayaptimi? Vaqtincha Firewall'ni o'chirib sinab ko'ring

### "flutter pub get" xato beradi
```powershell
flutter clean
flutter pub get
```

### Emulator sekin
- Android Studio → Virtual Device Manager → Edit → **RAM ni 4096 MB** ga oshiring
- Boshqa og'ir dasturlarni yoping
- Kompyuter virtualization (BIOS'da VT-x) yoqilganmi tekshiring

### "Android licenses not accepted"
```powershell
flutter doctor --android-licenses
```
Barcha savollarga `y`.

### Docker juda sekin (Windows)
Docker Desktop → Settings → Resources → **WSL Integration** ni yoqing.
Resources → Memory'ni 4 GB ga oshiring.

---

## 📚 Foydali manzillar

| Manzil | Tavsif |
|--------|--------|
| http://localhost:8000 | Backend |
| http://localhost:8000/docs | Swagger UI (API tester) |
| http://localhost:8000/redoc | ReDoc (API hujjat) |
| http://localhost:8000/health | Health check |

---

## 🆘 Yordam kerak bo'lsa

Xato chiqsa, quyidagi ma'lumotlar bilan murojaat qiling:
1. Qaysi bosqichda?
2. Aniq xato matni (skrinshot yaxshi)
3. `flutter doctor` natijasi
4. `docker compose logs backend` natijasi (oxirgi 20 satr)
