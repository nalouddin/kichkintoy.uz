"""
Boshlang'ich ma'lumotlarni DB ga yuklaydi:
- Admin foydalanuvchi (.env dan ADMIN_EMAIL / ADMIN_PASSWORD)
- Darslar (harflar, sonlar, ranglar, shakllar, xotira)
- Ertaklar, she'rlar, qo'shiqlar
- Tavsiyalar (ota-ona va pedagoglar uchun)

Ishga tushirish:
    python -m app.seed
"""
import asyncio
from datetime import date
from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.core.security import hash_password
from app.core.config import settings
from app.models.user import User, UserRole
from app.models.child import Child, Group
from app.models.lesson import Lesson, LessonCategory
from app.models.content import Story, StoryCategory, Recommendation, RecommendationCategory


# ============ DARSLAR KONTENT ============

LESSONS_DATA = [
    # ===== HARFLAR =====
    {
        "title": "O'zbek alifbosi - 1-qism",
        "description": "Asosiy harflarni o'rganamiz",
        "category": LessonCategory.LETTERS,
        "age_group": 4,
        "difficulty": 1,
        "order": 1,
        "content": {
            "items": [
                {"letter": "A", "word": "Anor", "emoji": "🍎", "audio": "a.mp3"},
                {"letter": "B", "word": "Baliq", "emoji": "🐟", "audio": "b.mp3"},
                {"letter": "D", "word": "Daraxt", "emoji": "🌳", "audio": "d.mp3"},
                {"letter": "G", "word": "Gul", "emoji": "🌸", "audio": "g.mp3"},
                {"letter": "I", "word": "It", "emoji": "🐕", "audio": "i.mp3"},
                {"letter": "K", "word": "Kitob", "emoji": "📚", "audio": "k.mp3"},
                {"letter": "L", "word": "Limon", "emoji": "🍋", "audio": "l.mp3"},
                {"letter": "M", "word": "Mushuk", "emoji": "🐱", "audio": "m.mp3"},
                {"letter": "O", "word": "Olma", "emoji": "🍏", "audio": "o.mp3"},
                {"letter": "Q", "word": "Quyon", "emoji": "🐰", "audio": "q.mp3"},
            ],
        },
    },
    {
        "title": "O'zbek alifbosi - 2-qism",
        "description": "Qolgan harflar",
        "category": LessonCategory.LETTERS,
        "age_group": 5,
        "difficulty": 2,
        "order": 2,
        "content": {
            "items": [
                {"letter": "N", "word": "Non", "emoji": "🥖"},
                {"letter": "P", "word": "Piyola", "emoji": "🫖"},
                {"letter": "R", "word": "Ruchka", "emoji": "✏️"},
                {"letter": "S", "word": "Soat", "emoji": "⏰"},
                {"letter": "T", "word": "Tovus", "emoji": "🦚"},
                {"letter": "U", "word": "Uzum", "emoji": "🍇"},
                {"letter": "X", "word": "Xo'roz", "emoji": "🐓"},
                {"letter": "Y", "word": "Yulduz", "emoji": "⭐"},
                {"letter": "Z", "word": "Zebra", "emoji": "🦓"},
            ],
        },
    },

    # ===== SONLAR =====
    {
        "title": "Sonlar 1 dan 10 gacha",
        "description": "Sanashni o'rganamiz",
        "category": LessonCategory.NUMBERS,
        "age_group": 3,
        "difficulty": 1,
        "order": 1,
        "content": {
            "items": [
                {"number": 1, "word": "Bir", "emoji": "1️⃣", "objects": "🍎"},
                {"number": 2, "word": "Ikki", "emoji": "2️⃣", "objects": "🍎🍎"},
                {"number": 3, "word": "Uch", "emoji": "3️⃣", "objects": "🍎🍎🍎"},
                {"number": 4, "word": "To'rt", "emoji": "4️⃣", "objects": "🍎🍎🍎🍎"},
                {"number": 5, "word": "Besh", "emoji": "5️⃣", "objects": "🍎🍎🍎🍎🍎"},
                {"number": 6, "word": "Olti", "emoji": "6️⃣", "objects": "🐟🐟🐟🐟🐟🐟"},
                {"number": 7, "word": "Yetti", "emoji": "7️⃣", "objects": "🌸🌸🌸🌸🌸🌸🌸"},
                {"number": 8, "word": "Sakkiz", "emoji": "8️⃣", "objects": "⭐⭐⭐⭐⭐⭐⭐⭐"},
                {"number": 9, "word": "To'qqiz", "emoji": "9️⃣", "objects": "🎈🎈🎈🎈🎈🎈🎈🎈🎈"},
                {"number": 10, "word": "O'n", "emoji": "🔟", "objects": "🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇"},
            ],
        },
    },
    {
        "title": "Oddiy qo'shish",
        "description": "1+1=? Sonlarni qo'shamiz",
        "category": LessonCategory.NUMBERS,
        "age_group": 5,
        "difficulty": 2,
        "order": 2,
        "content": {
            "items": [
                {"a": 1, "b": 1, "result": 2},
                {"a": 2, "b": 1, "result": 3},
                {"a": 2, "b": 2, "result": 4},
                {"a": 3, "b": 1, "result": 4},
                {"a": 3, "b": 2, "result": 5},
                {"a": 2, "b": 3, "result": 5},
                {"a": 4, "b": 1, "result": 5},
                {"a": 3, "b": 3, "result": 6},
                {"a": 4, "b": 2, "result": 6},
                {"a": 5, "b": 2, "result": 7},
            ],
        },
    },

    # ===== RANGLAR =====
    {
        "title": "Asosiy ranglar",
        "description": "Ranglarni o'rganamiz va topamiz",
        "category": LessonCategory.COLORS,
        "age_group": 3,
        "difficulty": 1,
        "order": 1,
        "content": {
            "items": [
                {"name": "Qizil", "hex": "#FF6B6B", "emoji": "🍎", "object": "olma"},
                {"name": "Ko'k", "hex": "#4ECDC4", "emoji": "🌊", "object": "dengiz"},
                {"name": "Sariq", "hex": "#FFE66D", "emoji": "☀️", "object": "quyosh"},
                {"name": "Yashil", "hex": "#95E1A3", "emoji": "🌳", "object": "daraxt"},
                {"name": "To'q sariq", "hex": "#FFA502", "emoji": "🥕", "object": "sabzi"},
                {"name": "Binafsha", "hex": "#A29BFE", "emoji": "🍇", "object": "uzum"},
                {"name": "Pushti", "hex": "#FF6B9D", "emoji": "🌸", "object": "gul"},
                {"name": "Qora", "hex": "#2D3436", "emoji": "🐱", "object": "mushuk"},
            ],
        },
    },

    # ===== SHAKLLAR =====
    {
        "title": "Geometrik shakllar",
        "description": "Doira, kvadrat, uchburchak va boshqalar",
        "category": LessonCategory.SHAPES,
        "age_group": 4,
        "difficulty": 1,
        "order": 1,
        "content": {
            "items": [
                {"name": "Doira", "emoji": "⭕", "sides": 0, "example": "quyosh"},
                {"name": "Kvadrat", "emoji": "🟦", "sides": 4, "example": "deraza"},
                {"name": "Uchburchak", "emoji": "🔺", "sides": 3, "example": "tom"},
                {"name": "To'rtburchak", "emoji": "▭", "sides": 4, "example": "kitob"},
                {"name": "Yulduz", "emoji": "⭐", "sides": 5, "example": "osmon"},
                {"name": "Yurak", "emoji": "❤️", "sides": 0, "example": "muhabbat"},
                {"name": "Romb", "emoji": "🔷", "sides": 4, "example": "varrak"},
                {"name": "Olti burchak", "emoji": "⬡", "sides": 6, "example": "asalari uyasi"},
            ],
        },
    },

    # ===== XOTIRA =====
    {
        "title": "Xotira o'yini - hayvonlar",
        "description": "Bir xil kartalarni topish",
        "category": LessonCategory.MEMORY,
        "age_group": 4,
        "difficulty": 1,
        "order": 1,
        "content": {
            "pairs": [
                {"id": 1, "emoji": "🐶"},
                {"id": 2, "emoji": "🐱"},
                {"id": 3, "emoji": "🐰"},
                {"id": 4, "emoji": "🐼"},
                {"id": 5, "emoji": "🦁"},
                {"id": 6, "emoji": "🐸"},
            ],
            "grid_size": "3x4",
        },
    },
    {
        "title": "Xotira o'yini - mevalar",
        "description": "Mevali kartalarni eslab qol",
        "category": LessonCategory.MEMORY,
        "age_group": 5,
        "difficulty": 2,
        "order": 2,
        "content": {
            "pairs": [
                {"id": 1, "emoji": "🍎"},
                {"id": 2, "emoji": "🍌"},
                {"id": 3, "emoji": "🍇"},
                {"id": 4, "emoji": "🍓"},
                {"id": 5, "emoji": "🍊"},
                {"id": 6, "emoji": "🍉"},
                {"id": 7, "emoji": "🥝"},
                {"id": 8, "emoji": "🍑"},
            ],
            "grid_size": "4x4",
        },
    },

    # ===== PUZZLE =====
    {
        "title": "Ketma-ketlikni davom ettir",
        "description": "Qaysi rasm keyin keladi?",
        "category": LessonCategory.PUZZLE,
        "age_group": 5,
        "difficulty": 2,
        "order": 1,
        "content": {
            "items": [
                {"sequence": ["🔴", "🔵", "🔴", "🔵", "?"], "answer": "🔴",
                 "options": ["🔴", "🔵", "🟢"]},
                {"sequence": ["⭐", "🌙", "⭐", "🌙", "?"], "answer": "⭐",
                 "options": ["☀️", "⭐", "🌈"]},
                {"sequence": ["🍎", "🍌", "🍎", "🍌", "?"], "answer": "🍎",
                 "options": ["🍇", "🍎", "🍊"]},
                {"sequence": ["🐱", "🐶", "🐱", "🐶", "?"], "answer": "🐱",
                 "options": ["🐱", "🐰", "🐻"]},
                {"sequence": ["🔺", "⭕", "🔺", "⭕", "?"], "answer": "🔺",
                 "options": ["🟦", "🔺", "⭐"]},
            ],
        },
    },
]


# ============ ERTAKLAR ============

STORIES_DATA = [
    {
        "title": "Uch echki",
        "description": "Uch echki ko'prik orqali o'tmoqchi bo'ladi",
        "content": (
            "Bir bor ekan, uch echki bor ekan. Katta echki, o'rta echki va kichkina echki. "
            "Ular ko'prik orqali yashil o'tlarga o'tmoqchi bo'lishibdi. Ko'prik tagida esa "
            "yovuz bir ajdaho yasharkan. Kichkina echki avval o'tdi. Ajdaho to'xtatdi: "
            "'Kim bu?' 'Men kichkina echkiman, katta singlimni kuting!' dedi. Ajdaho o'tkazdi. "
            "O'rta echki ham shunday dedi. Nihoyat katta echki keldi va ajdahoni engib o'tdi. "
            "Uchala echki yashil o'tlarda baxtli yashab qoldi."
        ),
        "age_group": 4,
        "category": StoryCategory.STORY,
        "author": "Xalq ertagi",
        "duration_seconds": 180,
        "order": 1,
    },
    {
        "title": "Qizil shapkali qiz",
        "description": "Buvisi uchun ovqat olib ketayotgan qizcha",
        "content": (
            "Bir qishloqda Qizil shapkali qiz yasharkan. Bir kuni onasi: 'Buvingga "
            "ovqat olib bor, lekin yo'ldan chetga chiqma,' dedi. Qizil shapkali qiz "
            "yo'lga tushdi. O'rmonda bo'ri uchratdi. Bo'ri: 'Qaerga ketayapsan?' dedi. "
            "Qizil shapkali qiz aytib qo'ydi. Bo'ri oldin buvining uyiga yetib bordi. "
            "Lekin ovchi bo'rini quvib chiqardi. Buvicha omon qoldi. Qizil shapkali qiz "
            "ham sog'-salomat yetib keldi va buvisi bilan baxtli uchrashdi."
        ),
        "age_group": 5,
        "category": StoryCategory.STORY,
        "author": "Sharl Perro",
        "duration_seconds": 240,
        "order": 2,
    },
    {
        "title": "Bahor keldi",
        "description": "Bahor fasli haqida she'r",
        "content": (
            "Bahor keldi, qor ketdi,\n"
            "Daraxtlarga gul bitdi.\n"
            "Qushlar sayrар, sevinib,\n"
            "Bolalar o'ynар yugurib.\n\n"
            "Lola ochdi qizarib,\n"
            "Sabza chiqdi yashnarib.\n"
            "Bahor keldi, bahor keldi,\n"
            "Quvonch keldi, nur keldi!"
        ),
        "age_group": 3,
        "category": StoryCategory.POEM,
        "author": "Hamid Olimjon",
        "duration_seconds": 60,
        "order": 3,
    },
    {
        "title": "Bolalar qo'shig'i",
        "description": "Kichkintoylar uchun quvnoq qo'shiq",
        "content": (
            "Qo'shiq:\n"
            "Men o'qiyman, sen o'qiyman,\n"
            "Biz birga o'qiymiz.\n"
            "Harflar, sonlar, ranglar bilan,\n"
            "Dunyo kashf etamiz!\n\n"
            "Yulduz kabi porlaylik,\n"
            "Bilim olib boraylik.\n"
            "Kelajak bizniki,\n"
            "Oldinga boraylik!"
        ),
        "age_group": 4,
        "category": StoryCategory.SONG,
        "author": "Kichkintoy Connect",
        "duration_seconds": 90,
        "order": 4,
    },
    {
        "title": "Aqlli quyon",
        "description": "Aqli bilan yovuzni yenggan quyon haqida ertak",
        "content": (
            "Bir o'rmonda quyon va bo'ri yasharkan. Bo'ri har doim quyonni qo'rqitarkan. "
            "Bir kuni quyon o'ylab qoldi: 'Kuchim bo'lmasa ham aqilim bor!' "
            "Quyon bo'rini ko'lga olib bordi va: 'Mana, suvda ham bir bo'ri bor, "
            "u mendan kuchli,' dedi. Bo'ri suvga qarab o'z aksini ko'rdi va qo'rqib qochdi. "
            "Shundan beri quyon tinch yashab qoldi. Aqil kuchdan kuchli!"
        ),
        "age_group": 5,
        "category": StoryCategory.STORY,
        "author": "Xalq ertagi",
        "duration_seconds": 200,
        "order": 5,
    },
]


# ============ TAVSIYALAR ============

RECOMMENDATIONS_DATA = [
    {
        "title": "Bolani kitob o'qishga qiziqtirish",
        "content": (
            "Har kuni uxlashdan oldin bolangizga 10-15 daqiqa ertak o'qib bering. "
            "Kitob tanlaydigan paytda bolaning o'zi tanlashiga ruxsat bering — bu "
            "mustaqillikni rivojlantiradi. Rasmli kitoblardan boshlang, so'ngra matn "
            "ko'proq bo'lgan kitoblarga o'ting. O'qish paytida his-tuyg'ularni ifodalab "
            "o'qing — bu bolaning qiziqishini oshiradi."
        ),
        "category": RecommendationCategory.PARENT,
        "age_group": 4,
        "author": "Psixolog Dilnoza Yusupova",
    },
    {
        "title": "Kundalik tartib bolaning rivojlanishiga ta'siri",
        "content": (
            "Bolalar uchun kundalik tartib juda muhim. Har kuni bir xil vaqtda "
            "uyg'onish, ovqatlanish va uxlash miyani tinchlantiradi. Tartibli hayot "
            "kechiruvchi bolalar kamroq xavotirlanadi va yangi bilimlarni osonroq o'zlashtiradi. "
            "Ertalab 20 daqiqa jismoniy harakat, kechqurun esa kitob o'qish davrasini "
            "joriy qiling."
        ),
        "category": RecommendationCategory.PARENT,
        "age_group": None,
        "author": "Dr. Kamola Rahimova",
    },
    {
        "title": "Sinfda harflarni o'rgatishning samarali usullari",
        "content": (
            "Harflarni o'rgatishda ko'rish, eshitish va sezish kanallarini birga ishlating. "
            "Harfni qumga yoki plastilin bilan yasatib ko'ring. Har bir harf uchun qo'shiq "
            "yoki she'r o'rgating. Kuniga 2-3 ta yangi harf yetarli — ko'p bo'lsa bola "
            "charchaydi. O'yinchoqlar va rasmlar yordamida harfni so'z bilan bog'lang."
        ),
        "category": RecommendationCategory.TEACHER,
        "age_group": 4,
        "author": "Pedagog Malika Toshmatova",
    },
    {
        "title": "Bolaning diqqatini rivojlantirish",
        "content": (
            "3-5 yoshli bolalar diqqatini 10-15 daqiqadan ko'proq ushlab turolmaydi. "
            "Shu sababli o'quv mashg'ulotlarini qisqa va qiziqarli qiling. "
            "Bola diqqatini rivojlantirish uchun har kuni labirint, rasm topish, "
            "farqlarni topish o'yinlarini o'ynating. Ekran vaqtini cheklang — "
            "kuniga 1 soatdan oshmasin."
        ),
        "category": RecommendationCategory.PSYCHOLOGY,
        "age_group": 4,
        "author": "Psixolog Aziza Karimova",
    },
    {
        "title": "Nutq rivojlanishini qo'llab-quvvatlash",
        "content": (
            "Bolangiz bilan ko'p gaplashing — hatto u hali yaxshi gapira olmasa ham. "
            "Kundalik hayotdagi narsalarni nomlang: 'Bu qizil olma, olma mazali.' "
            "Savol bering va javob kutib turing. She'r va qo'shiqlar nutqni rivojlantiradi. "
            "Agar 3 yoshda 50 dan kam so'z bilsa, nutq terapevtiga murojaat qiling."
        ),
        "category": RecommendationCategory.DEVELOPMENT,
        "age_group": 3,
        "author": "Nutq terapevti Shahnoza Umarova",
    },
]


# ============ SEED FUNKSIYALAR ============

async def create_admin_if_not_exists(session) -> User:
    login = settings.ADMIN_EMAIL  # "admin" yoki email manzil
    result = await session.execute(
        select(User).where(
            (User.phone == login) | (User.email == login)
        )
    )
    admin = result.scalar_one_or_none()
    if admin:
        print(f"ℹ️  Admin allaqachon mavjud: {login}")
        return admin

    admin = User(
        phone=login,
        email=login if "@" in login else None,
        password_hash=hash_password(settings.ADMIN_PASSWORD),
        password_plain=settings.ADMIN_PASSWORD,
        full_name="Tizim Administratori",
        role=UserRole.ADMIN,
    )
    session.add(admin)
    await session.flush()
    print(f"✅ Admin yaratildi — login: {login}  parol: {settings.ADMIN_PASSWORD}")
    return admin


async def create_lessons(session):
    result = await session.execute(select(Lesson))
    existing_titles = {l.title for l in result.scalars().all()}

    created = 0
    for data in LESSONS_DATA:
        if data["title"] in existing_titles:
            continue
        session.add(Lesson(**data))
        created += 1

    if created > 0:
        print(f"✅ {created} ta dars yaratildi")
    else:
        print("ℹ️  Barcha darslar allaqachon mavjud")


async def create_stories(session):
    result = await session.execute(select(Story))
    existing_titles = {s.title for s in result.scalars().all()}

    created = 0
    for data in STORIES_DATA:
        if data["title"] in existing_titles:
            continue
        session.add(Story(**data))
        created += 1

    if created > 0:
        print(f"✅ {created} ta ertak/she'r yaratildi")
    else:
        print("ℹ️  Barcha ertaklar allaqachon mavjud")


async def create_recommendations(session):
    result = await session.execute(select(Recommendation))
    existing_titles = {r.title for r in result.scalars().all()}

    created = 0
    for data in RECOMMENDATIONS_DATA:
        if data["title"] in existing_titles:
            continue
        session.add(Recommendation(**data))
        created += 1

    if created > 0:
        print(f"✅ {created} ta tavsiya yaratildi")
    else:
        print("ℹ️  Barcha tavsiyalar allaqachon mavjud")


# ============ TEST MA'LUMOTLAR (faqat DEBUG=True) ============

TEST_PARENTS = [
    {"full_name": "Anvar Karimov",    "phone": "ota1", "password": "test1234"},
    {"full_name": "Barno Rahimova",   "phone": "ota2", "password": "test1234"},
    {"full_name": "Davron Toshmatov", "phone": "ota3", "password": "test1234"},
    {"full_name": "Gulnora Usmonova", "phone": "ota4", "password": "test1234"},
    {"full_name": "Hamid Yusupov",    "phone": "ota5", "password": "test1234"},
]

TEST_TEACHERS = [
    {"full_name": "Malika Abdullayeva", "phone": "pedagog1", "password": "test1234"},
    {"full_name": "Nodira Saidova",     "phone": "pedagog2", "password": "test1234"},
    {"full_name": "Ozoda Tursunova",    "phone": "pedagog3", "password": "test1234"},
    {"full_name": "Parizod Xolmatova",  "phone": "pedagog4", "password": "test1234"},
    {"full_name": "Rohila Mirzayeva",   "phone": "pedagog5", "password": "test1234"},
]

TEST_CHILDREN = [
    {"full_name": "Ali Karimov",       "login": "ali_k",    "birth_date": date(2020, 6, 15),  "password": "bola1234"},
    {"full_name": "Fatima Rahimova",   "login": "fatima_r", "birth_date": date(2021, 3, 10),  "password": "bola1234"},
    {"full_name": "Jasur Toshmatov",   "login": "jasur_t",  "birth_date": date(2019, 8, 20),  "password": "bola1234"},
    {"full_name": "Kamola Usmonova",   "login": "kamola_u", "birth_date": date(2020, 1,  5),  "password": "bola1234"},
    {"full_name": "Lochinbek Yusupov", "login": "lochin_y", "birth_date": date(2018, 11, 12), "password": "bola1234"},
]

TEST_GROUPS = [
    {"name": "Nilufar guruhi",   "age_group": 5},
    {"name": "Sarvinoz guruhi",  "age_group": 4},
    {"name": "Bahor guruhi",     "age_group": 6},
    {"name": "Yulduzcha guruhi", "age_group": 4},
    {"name": "Kamalak guruhi",   "age_group": 5},
]


async def create_test_data(session):
    today = date.today()
    print("🧪 Test ma'lumotlari...")

    # Ota-onalar
    parent_users = []
    for p in TEST_PARENTS:
        ex = (await session.execute(select(User).where(User.phone == p["phone"]))).scalar_one_or_none()
        if not ex:
            ex = User(phone=p["phone"],
                      password_hash=hash_password(p["password"]),
                      password_plain=p["password"],
                      full_name=p["full_name"], role=UserRole.PARENT)
            session.add(ex)
            await session.flush()
        parent_users.append(ex)
    print("  ✅ 5 ta ota-ona  (login: ota1–ota5 / parol: test1234)")

    # Pedagoglar
    teacher_users = []
    for t in TEST_TEACHERS:
        ex = (await session.execute(select(User).where(User.phone == t["phone"]))).scalar_one_or_none()
        if not ex:
            ex = User(phone=t["phone"],
                      password_hash=hash_password(t["password"]),
                      password_plain=t["password"],
                      full_name=t["full_name"], role=UserRole.TEACHER)
            session.add(ex)
            await session.flush()
        teacher_users.append(ex)
    print("  ✅ 5 ta pedagog  (login: pedagog1–pedagog5 / parol: test1234)")

    # Guruhlar (har pedagog uchun 1 ta)
    groups = []
    for g, teacher in zip(TEST_GROUPS, teacher_users):
        ex = (await session.execute(select(Group).where(Group.name == g["name"]))).scalar_one_or_none()
        if not ex:
            ex = Group(teacher_id=teacher.id, name=g["name"], age_group=g["age_group"])
            session.add(ex)
            await session.flush()
        groups.append(ex)
    print(f"  ✅ {len(TEST_GROUPS)} ta guruh")

    # Bolalar (har ota-ona uchun 1 ta, guruhga biriktirilgan)
    for i, (c, parent) in enumerate(zip(TEST_CHILDREN, parent_users)):
        ex = (await session.execute(select(User).where(User.phone == c["login"]))).scalar_one_or_none()
        if ex:
            continue
        bd = c["birth_date"]
        age = today.year - bd.year - ((today.month, today.day) < (bd.month, bd.day))
        child_user = User(phone=c["login"], password_hash=hash_password(c["password"]),
                          password_plain=c["password"],
                          full_name=c["full_name"], role=UserRole.CHILD)
        session.add(child_user)
        await session.flush()
        child = Child(user_id=child_user.id, parent_id=parent.id,
                      birth_date=bd, age_group=age,
                      group_id=groups[i].id if i < len(groups) else None)
        session.add(child)
        await session.flush()
    print(f"  ✅ {len(TEST_CHILDREN)} ta bola (login: ali_k, fatima_r, jasur_t, kamola_u, lochin_y / bola1234)")


async def seed():
    print("\n🌱 Seed boshlandi...\n")
    async with AsyncSessionLocal() as session:
        try:
            await create_admin_if_not_exists(session)
            await session.flush()
            await create_lessons(session)
            await create_stories(session)
            await create_recommendations(session)
            if settings.DEBUG:
                await create_test_data(session)
            await session.commit()
            print("\n✨ Seed muvaffaqiyatli tugadi!\n")
        except Exception as e:
            await session.rollback()
            print(f"\n❌ Xato: {e}\n")
            raise


if __name__ == "__main__":
    asyncio.run(seed())
