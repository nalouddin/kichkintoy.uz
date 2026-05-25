"""add content tables: stories and recommendations

Revision ID: c4d5e6f7a8b9
Revises: a2b3c4d5e6f7
Create Date: 2025-05-23
"""
from typing import Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'c4d5e6f7a8b9'
down_revision: Union[str, None] = 'a2b3c4d5e6f7'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'stories',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('description', sa.String(500), nullable=True),
        sa.Column('content', sa.Text, nullable=False),
        sa.Column('audio_url', sa.String(500), nullable=True),
        sa.Column('thumbnail_url', sa.String(500), nullable=True),
        sa.Column('age_group', sa.Integer, nullable=False),
        sa.Column('category', sa.Enum('story', 'poem', 'song', name='storycategory'), nullable=False),
        sa.Column('author', sa.String(200), nullable=True),
        sa.Column('duration_seconds', sa.Integer, server_default='0'),
        sa.Column('order', sa.Integer, server_default='0'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index('ix_stories_age_group', 'stories', ['age_group'])
    op.create_index('ix_stories_category', 'stories', ['category'])

    op.create_table(
        'recommendations',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('content', sa.Text, nullable=False),
        sa.Column('category', sa.Enum('parent', 'teacher', 'psychology', 'development', name='recommendationcategory'), nullable=False),
        sa.Column('age_group', sa.Integer, nullable=True),
        sa.Column('author', sa.String(200), nullable=True),
        sa.Column('is_active', sa.Boolean, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index('ix_recommendations_category', 'recommendations', ['category'])

    # ================================================================
    # SEED: ERTAKLAR (5 ta)
    # ================================================================
    op.execute("""INSERT INTO stories (title, description, content, age_group, category, author, "order") VALUES

    ('Uchta cho''chqa',
     'Uchta aka-uka cho''chqa va bo''ri haqida mashhur ertak',
     'Bir vaqtlar uchta aka-uka cho''chqa yashar edi. Kattasi somon uycha qurib oldi. O''rtanchasi yog''och uycha qurib oldi. Kichigi esa g''isht uycha qurib oldi.

Bir kuni bo''ri keldi va kattasining somon uychasiga pufladi — uycha yiqildi! Cho''chqa qochib o''rtanchaning yog''och uychasiga kirdi. Bo''ri pufladi — bu ham yiqildi! Ikkalasi qochib kichigining g''isht uychasiga kirdi.

Bo''ri puflay-puflay charchadi, lekin g''isht uycha yiqilmadi. Cho''chqalar xursand bo''lib qoldi va bo''ri uylariga qaytib ketdi.

Qattiq asosga qurilgan uy hamma narsaga bardosh beradi!',
     3, 'story', 'Xalq ertagi', 1),

    ('Qizil shapka',
     'Qizil shapkali qiz va bo''ri haqidagi ertak',
     'Bir qishloqda Qizil Shapka ismli qiz yashar edi. Bir kuni onasi unga:
— Buvingga tarvuz va non olib bor, — dedi.

Qizil Shapka yo''lga chiqdi. O''rmonda bo''ri uchrab qoldi:
— Qaerga ketayapsan?
— Buvimnikiga, — dedi qiz.

Bo''ri tez yurib buvining uyiga yetib oldi va uni yashirdi. Qizil Shapka kelganda bo''ri buviday bo''lib yotibdi.

Lekin qizning qichqirig''ini eshitib, ovchi keldi va buvini bo''ri qornidan olib chiqdi.

Endi Qizil Shapka notanish odamlar bilan gaplashmaslikni yaxshi biladi.',
     4, 'story', 'Xalq ertagi', 2),

    ('Chumchuq va chumoli',
     'Do''stlik va yordamlashish haqidagi ertak',
     'Bir kuni chumoli daryodan suv ichayotganda suvga tushib ketdi. Yaqinda o''tirgan chumchuq buni ko''rib, bitta bargcha tashlab yubordi. Chumoli bargga chiqib sog''omon qutildi.

Ko''p o''tmay bir ovchi chumchuqni tutmoqchi bo''ldi. Chumoli buni ko''rib, ovchining oyog''ini chaqib yubordi. Ovchi sakrab ketdi va chumchuq uchib qoldi.

Do''stingga yaxshilik qilsang, u ham senga yaxshilik qiladi!',
     3, 'story', 'Ezop', 3),

    ('Mushuk va sichqon',
     'Aqlli sichqon haqidagi kulgili ertak',
     'Bir mushuk har kuni sichqonlarni ovlar edi. Sichqonlar yig''ilib maslahat qilishdi:
— Mushukka qo''ng''iroq osib qo''ysak, uni eshitib qochib ketamiz!

Hamma rozi bo''ldi. Lekin endi bir savol tug''ildi:
— Kim boradi mushuk bo''yniga qo''ng''iroq osib kelishga?

Hech kim javob bermadi. Maslahatda qolish emas, ish qilish kerakligi ma''lum bo''ldi.',
     4, 'story', 'Ezop', 4),

    ('Lochin va qarg''a',
     'Manmanlik va kamtarlik haqidagi ertak',
     'Baland qoyada lochin va qarg''a yonma-yon yashardi. Bir kuni qarg''a lochinga:
— Sen doim baland uchasan, lekin men ham xuddi shunday ucha olaman! — dedi.

Lochin indamadi. Qarg''a baland ko''tarilib uchdi, lekin tez charchadi va pastga tushdi.

— Ko''rdingmi, sen ham meni yengolmading! — dedi lochin.

— Yo''q, sen meni yutqazding, — dedi qarg''a. — Chunki men o''zimni sen bilan tenglashtirishga urinib ovga ham chiqmadim.

Qobiliyatingni boshqalar bilan emas, o''zing bilan solishtir.',
     5, 'story', 'Xalq ertagi', 5)
    """)

    # ================================================================
    # SEED: SHE'RLAR (5 ta)
    # ================================================================
    op.execute("""INSERT INTO stories (title, description, content, age_group, category, author, "order") VALUES

    ('Bahor keldi',
     'Bahor fasli haqidagi she''r',
     'Bahor keldi, bahor keldi,
Gullar ochildi.
Qushlar sayradi,
Bog''lar yashnadi.

Quyosh kuldi bizga,
Shamol esdi yengil.
Bolalar o''ynadi,
Kulgular to''ldi.',
     3, 'poem', 'Xalq she''ri', 1),

    ('Oyim',
     'Ona haqidagi mehribon she''r',
     'Oyim, oyim, sevgili oyim,
Seni sevaman men juda ham.
Qo''llaring iliq, yuzing nurli,
Sening bilan baxtliman har dam.

Ertalab turasan avval sen,
Taom pishirasan menga.
Kechqurun uxlatsang qo''shing bilan,
Sog''inaman faqat seni.',
     4, 'poem', 'Xalq she''ri', 2),

    ('Maktab',
     'Maktabga borish haqidagi quvnoq she''r',
     'Maktabga boraman erta,
Sumkam og''ir, yurak shod.
O''qiyman, yozaman,
Bilayman ko''p narsani.

Do''stlarim kutib turar,
O''qituvchi gaplar.
Har kuni bir narsa
O''rganamiz biz.',
     5, 'poem', 'Bolalar she''ri', 3),

    ('Daraxt',
     'Tabiat va daraxt haqidagi she''r',
     'Katta daraxt turar bog''da,
Shoxlari ko''kka cho''zilgan.
Qushlarga uy bo''lgan u,
Soyasida dam olingan.

Ildizi chuqur yotibdi,
Toshlar orasiga kirgan.
Yomg''ir yog''sa ham, shamol esse ham,
Turib beradi u tirik.',
     4, 'poem', 'Xalq she''ri', 4),

    ('Mening yurtim',
     'Vatan sevgisi haqidagi she''r',
     'Mening yurtim — O''zbekiston,
Ko''k osmon, yashil dala.
Tog''lar bor, daryolar bor,
Bog''larda gullar bor.

Shu yerda tug''ildim men,
Shu yerda o''sdim ham.
Yurtimni sevaman doim,
Eng go''zal joyi — mening yerim.',
     5, 'poem', 'Bolalar she''ri', 5)
    """)

    # ================================================================
    # SEED: QO'SHIQLAR (5 ta)
    # ================================================================
    op.execute("""INSERT INTO stories (title, description, content, age_group, category, author, "order") VALUES

    ('Sonlar qo''shig''i',
     'Sonlarni o''rganish uchun qo''shiq',
     'Bir — bitta olma,
Ikki — ikkita uzum,
Uch — uchta olcha,
To''rt — to''rtta tarvuz.

Besh — beshtacha anor,
Olti — oltita gilos,
Yetti — yettita o''rik,
Sakkiz — sakkizta limon.

To''qqiz — to''qqizta shaftoli,
O''n — o''nta anjir.
Sonlarni bilamiz,
Biz o''qiymiz!',
     3, 'song', 'Ta''lim qo''shig''i', 1),

    ('Alifbo qo''shig''i',
     'Harflarni o''rganish uchun qo''shiq',
     'A — anor, B — bodring,
V — vaqt, G — gul.
D — daraxt, E — ekin,
F — fasl, G'' — g''oz.

H — hovuz, I — ip,
J — jiyda, K — kitob.
L — lola, M — maktab,
N — non, O — ot.

Harflarni bilamiz,
O''qishni yaxshi ko''ramiz!',
     4, 'song', 'Ta''lim qo''shig''i', 2),

    ('Ranglar qo''shig''i',
     'Ranglarni o''rganish uchun qo''shiq',
     'Qizil rang — pomidor,
Ko''k rang — osmon.
Sariq rang — quyosh,
Yashil — o''t-o''lan.

To''q sariq — limon,
Binafsha — uzum.
Pushti — gul bargi,
Oq — qor, bulut.

Ranglarni bilamiz,
Dunyo rangli bo''ladi!',
     3, 'song', 'Ta''lim qo''shig''i', 3),

    ('Fasllar qo''shig''i',
     'To''rt fasl haqidagi qo''shiq',
     'Bahor keldi — gullar ochdi,
Yoz keldi — issiq bo''ldi.
Kuz keldi — barglar to''kildi,
Qish keldi — qor yog''di.

Bahor, yoz, kuz, qish —
To''rt fasl bir yilda.
Har bir fasl o''z rangida,
Hammasi go''zal bizga.',
     3, 'song', 'Bolalar qo''shig''i', 4),

    ('Hayvonlar qo''shig''i',
     'Hayvonlar ovozi haqidagi kulgili qo''shiq',
     'It vov-vov deydi,
Mushuk miyov-miyov.
Sigir mo''-mo'' deydi,
Ot kishna-kishna.

Qo''y ma''-ma'' deydi,
Echki me''-me''.
Tovuq qiq-qiq deydi,
Xo''roz qiq-qiq.

Hayvonlarni bilamiz,
Ovozlarini aytamiz!',
     3, 'song', 'Bolalar qo''shig''i', 5)
    """)

    # ================================================================
    # SEED: TAVSIYALAR — OTA-ONA (5 ta)
    # ================================================================
    op.execute("""INSERT INTO recommendations (title, content, category, age_group, author) VALUES

    ('Bolangiz bilan har kuni o''ynang',
     'Har kuni kamida 30 daqiqa bolangiz bilan o''ynash uning rivojlanishi uchun juda muhim.

Nima uchun muhim:
• O''yin orqali bola yangi so''zlarni o''rganadi
• Ijodiy fikrlashi rivojlanadi
• Siz bilan muloqot ko''nikmasi oshadi
• Emotsional bog''liq bo''lib o''sadi

Nima o''ynash mumkin:
• Lego yoki qurilish o''yinchoqlari
• Rasm solish va bo''yash
• Rol o''yinlari (do''xtur, oshpaz, o''qituvchi)
• Aqliy o''yinlar (puzzle, loto)',
     'parent', NULL, 'Psixolog Dilorom Yusupova'),

    ('Har kuni ertak o''qing',
     'Bolaga har kuni ertak o''qish uning til rivojlanishiga katta hissa qo''shadi.

Foydasi:
• So''z boyligi tez o''sadi
• Xayol kuchi rivojlanadi
• O''qishga qiziqish paydo bo''ladi
• Tinglash ko''nikmasi yaxshilanadi

Maslahat:
Uxlashdan oldin 15-20 daqiqa ertak o''qing. Bolaga savollar bering: "Nima bo''ldi? Nima deb o''ylaysan?"',
     'parent', NULL, 'Psixolog Aziza Karimova'),

    ('Bolaning mustaqilligini rivojlantiring',
     'Bolalarga kichik ishlarni mustaqil bajarishga ruxsat bering.

3-4 yoshda:
• O''z kiyimlarini yig''ishtirish
• O''yinchoqlarni joyiga qo''yish

5-6 yoshda:
• Oddiy taomlar tayyorlashga yordam
• O''z xonasini yig''ishtirish
• Kitoblarini tartiblashtirish

Muhim: Muvaffaqiyat uchun maqtang, xatolar uchun aytmang!',
     'parent', 3, 'Psixolog Hulkar Toshmatova'),

    ('To''g''ri ovqatlanish tartibi',
     'Bolaning sog''lom rivojlanishi uchun ovqatlanish tartibi muhim.

Kunlik tartibi:
• Nonushta: 8:00 — kuchli va to''yimli
• Tushlik: 13:00 — asosiy ovqat
• Peshin: 16:00 — meva yoki sut mahsulotlari
• Kechki ovqat: 19:00 — yengil

Foydali oziqlar:
✓ Meva va sabzavotlar
✓ Sut mahsulotlari (kalsiy)
✓ Baliq (omega-3)
✓ Qovoq, lavlagi, sabzi

Zararli oziqlarni kamaytiring:
✗ Shirin gazli ichimliklar
✗ Chips, krek
✗ Ko''p miqdorda qand',
     'parent', NULL, 'Pediatr Dr. Nodira Hamidova'),

    ('Sog''lom uyqu tartibi',
     'Bolalar uchun yetarli uyqu juda muhim — u buyida o''sish va miya rivojlanishi uchun kerak.

Yoshga qarab uyqu vaqti:
• 3-4 yosh: 11-13 soat (tunda + kunduzgi uyqu)
• 5-6 yosh: 10-12 soat (faqat tunda)

Yaxshi uyqu uchun:
✓ Har kuni bir xil vaqtda uxlatish
✓ Uxlashdan oldin ertak o''qish
✓ Xona salqin va qorong''u bo''lsin
✓ Ekrandan 1 soat oldin voz keching

Uyqu yetishmasa:
• Diqqat qisqaradi
• Kayfiyat yomonlashadi
• O''sish sekinlashadi',
     'parent', NULL, 'Pediatr Dr. Sarvinoz Mirzayeva')
    """)

    # ================================================================
    # SEED: TAVSIYALAR — PEDAGOG (5 ta)
    # ================================================================
    op.execute("""INSERT INTO recommendations (title, content, category, age_group, author) VALUES

    ('Guruhda o''qitishning samarali usullari',
     'Maktabgacha yoshdagi bolalar bilan ishlashda eng samarali usullar.

1. O''yin orqali o''rgatish
Har qanday bilimni o''yin shaklida bering.

2. Takrorlash va mustahkamlash
Yangi mavzuni 3-4 marta turli faoliyatlar orqali takrorlang.

3. Ko''rgazmali qurollar
Rasmlar, o''yinchoqlar, real buyumlardan foydalaning.

4. Individual yondashuv
Har bir bolaning o''z sur''ati bor. Solishtirmang, rag''batlantiring.

5. Maqtov va taqdirlash
Har qanday muvaffaqiyatni nishonlang.',
     'teacher', NULL, 'Pedagog Mohira Ergasheva'),

    ('Bolalarni to''g''ri baholash',
     'Maktabgacha yoshdagi bolalarni baholash o''yin va kuzatish orqali amalga oshirilishi kerak.

Baholash usullari:
• Kuzatish jurnali — kundalik faoliyatni qayd eting
• Portfolio — bolaning ishlari to''plami
• O''yin jarayonida kuzatish
• Suhbat (bola bilan)

Nimani baholash kerak:
✓ Muloqot ko''nikmasi
✓ Motor harakatlar
✓ Ijodiy fikrlash
✓ Jamoada ishlash

Muhim: Bolalarni bir-biri bilan solishtirmang. Har birini o''zi bilan solishtiring.',
     'teacher', NULL, 'Metodist Gulnora Xasanova'),

    ('Ota-onalar bilan samarali muloqot',
     'Ota-onalar bilan ishlash pedagogning muhim vazifasi.

Haftalik muloqot:
• Qisqa xabarlar (WhatsApp/Telegram)
• Yutuqlarni ulashing
• Muammolarni yashirmang

Ota-ona yig''ilishi:
• Oyda bir marta o''tkazing
• Bolaning rivojlanishini ko''rsating
• Uyda nima qilish kerakligini ayting

Muloqot qoidalari:
✓ Ijobiydan boshlang
✓ Aniq misollar keltiring
✓ Ota-onani sherик sifatida ko''ring
✗ Farzandini yomonlamang',
     'teacher', NULL, 'Pedagog Zilola Rahimova'),

    ('Bolalarni jamoada ishlashga o''rgatish',
     'Guruh ko''nikmalarini rivojlantirish maktabgacha yoshdanoq boshlanishi kerak.

Jamoaviy o''yinlar:
• Guruh qurilish o''yinlari
• Umumiy rasm solish
• Ertak dramatizatsiyasi
• Guruhda muammo hal qilish

Qoidalar o''rgatish:
1. Navbat kutish
2. Boshqalarni tinglash
3. Fikrni baham ko''rish
4. Kelishmovchiliklarni so''z bilan hal qilish

Kuzating:
• Kim rahbar bo''lmoqchi?
• Kim uyalchan?
• Kim yolg''iz qolishni yaxshi ko''radi?',
     'teacher', NULL, 'Psixolog Kamola Askarova'),

    ('Diqqatni jamlash faoliyatlari',
     'Bolalarning diqqatini jalb qilish va ushlab turish pedagogning asosiy san''ati.

Diqqat muddati (yoshga qarab):
• 3 yosh: 5-7 daqiqa
• 4 yosh: 8-10 daqiqa
• 5 yosh: 10-15 daqiqa
• 6 yosh: 15-20 daqiqa

Diqqatni jalb qilish usullari:
✓ Kutilmagan ovoz yoki harakat
✓ "Sehrli so''z" ishlatish
✓ Bolani ishtirokchi qilish
✓ Qisqa, aniq topshiriqlar

Faoliyatlarni almashtiring:
O''tirish → Harakat → O''tirish',
     'teacher', 4, 'Pedagog Nargiza Tursunova')
    """)

    # ================================================================
    # SEED: TAVSIYALAR — PSIXOLOG (5 ta)
    # ================================================================
    op.execute("""INSERT INTO recommendations (title, content, category, age_group, author) VALUES

    ('Bolalar bilan muloqot psixologiyasi',
     'Bolalar bilan to''g''ri muloqot qilish ularning ruhiy sog''lom o''sishiga yordam beradi.

Asosiy tamoyillar:

1. Tinglang
Bolaning gapini o''rtada to''xtatmang.

2. Ko''z darajasida gaplashing
Bola bilan gaplashganda uning balandligiga tuning.

3. His-tuyg''ularini tan oling
"Bilaman, sen g''azablandingmi?" — bu bola o''zini tushunilgan his qildiradi.

4. Tanqid emas, tavsiya
"Yomon qilding" o''rniga "Keyingi safar shunday qilsak yaxshi bo''lardi" deng.

5. Vaqt ajrating
Bolaga to''liq e''tibor beradigan maxsus "siz uchun vaqt" yarating.',
     'psychology', NULL, 'Psixolog Dr. Farida Nazarova'),

    ('Bolaning qo''rquvlarini tushunish',
     'Ko''pchilik bolalar qorong''ulikdan, begona odamlardan yoki ayriliqdan qo''rqishadi. Bu normal holat.

3-4 yoshdagi qo''rquvlar:
• Qorong''ulik, yolg''iz qolish
• Katta ovozlar (momaqaldiroq)
• Hayoliy maxluqlar

5-6 yoshdagi qo''rquvlar:
• Maktabga borish
• Do''stlar bilan munosabat

Nima qilish kerak:
✓ Qo''rquvini kulgiga olmang
✓ Nima uchun qo''rqishini tushuntirishga harakat qiling
✓ Birga hal qiling',
     'psychology', NULL, 'Psixolog Kamola Askarova'),

    ('Tantrum (g''azab tutishi) bilan ishlash',
     'Bolalarda g''azab tutishi 1-4 yoshda eng ko''p uchraydi. Bu rivojlanishning normal qismi.

Nima uchun bo''ladi:
• His-tuyg''ularini nazorat qila olmaslik
• Charchash yoki ochlik
• Mustaqil bo''lishga intilish
• E''tibor tortish

Tantrum paytida:
✓ Xotirjam qoling (sizning xotirjamligingiz o''tadi)
✓ Xavfsiz joyda qoldiring
✓ "Tushunaman, g''azablandingmi" deng
✗ Jag''ilamang va do''q urmang
✗ Talabini bajarmang

Keyin (tinchigandan so''ng):
• His-tuyg''ularini nomlashga o''rgating
• "G''azablanganingda nima qilsa bo''ladi?" deb so''rang',
     'psychology', 3, 'Psixolog Dr. Farida Nazarova'),

    ('Ijtimoiy ko''nikmalarni rivojlantirish',
     'Bolalar do''stlashish va muloqot qilishni o''rganishi kerak.

Asosiy ijtimoiy ko''nikmalar:
• Salomlashish va xayrlashish
• Navbat kutish va ulashish
• "Iltimos" va "Rahmat" deyish
• Boshqalarning his-tuyg''ularini sezish

Rivojlantirish usullari:
✓ Rol o''yinlari o''ynash
✓ Boshqa bolalar bilan o''ynashga imkon yaratish
✓ Kitob qahramonlarining his-tuyg''ularini muhokama qilish
✓ O''zi qilgan yaxshi ishlarini maqtang

Muammo bo''lsa:
Bolangiz do''stlashishda qiynalsa — bu ko''proq amaliyot kerakligini bildiradi.',
     'psychology', 4, 'Psixolog Aziza Karimova'),

    ('Diqqat va xotira muammolari',
     'Bolaning diqqati tarqoq bo''lsa yoki tez unutsa, bu bir necha sababdan bo''lishi mumkin.

Normal rivojlanish ko''rsatkichlari:
• 3 yosh: 5-7 daqiqa diqqat
• 5 yosh: 10-15 daqiqa diqqat

Diqqatni rivojlantirish:
✓ Qisqa, aniq topshiriqlar bering
✓ Ish joyini tartibli saqlang
✓ Fon shovqinini kamaytiring
✓ Bir vaqtda bitta topshiriq

Xotirani mustahkamlash:
✓ Takrorlash o''yinlari
✓ Qo''shiq va she''rlar
✓ Rasmli kartochkalar

Qachon mutaxassisga murojaat qilish kerak:
Agar 6 yoshida ham juda qiyin bo''lsa — ADHD tekshiruvidan o''ting.',
     'psychology', NULL, 'Neyropsixolog Dr. Sherzod Umarov')
    """)

    # ================================================================
    # SEED: TAVSIYALAR — RIVOJLANISH (5 ta)
    # ================================================================
    op.execute("""INSERT INTO recommendations (title, content, category, age_group, author) VALUES

    ('2-3 yoshdagi bolaning rivojlanishi',
     'Bu yosh — so''z portlashi davri. Bola juda tez rivojlanadi.

Til rivojlanishi:
• 2 yoshda 50-200 so''z
• 3 yoshda 300-500 so''z
• Ikki so''zli gaplar tuzadi

Jismoniy:
• Yuguradi, sakraydi
• Zinapoyadan chiqadi
• Qalamni ushlaydi

Ijtimoiy:
• Kattalarni taqlid qiladi
• "Yo''q" deyishni yaxshi ko''radi (mustaqillik)
• Boshqa bolalar bilan qisqa o''yin

Ota-ona uchun:
✓ Ko''p gaplashing
✓ Ko''p o''qing
✓ Sabr qiling — bu "yo''q" davri o''tib ketadi',
     'development', 2, 'Pediatr Dr. Nodira Hamidova'),

    ('3-4 yoshdagi bolaning rivojlanishi',
     'Bu yoshda bolalar tez rivojlanadi.

Til rivojlanishi:
• 3 yoshda 300-500 so''z
• 4 yoshda 1000-1500 so''z
• Oddiy gaplarni to''g''ri tuzadi

Jismoniy:
• Sakraydi, yuguradi, to''pni otadi
• Qalam bilan chiziq tortadi
• Kiyimini yecha oladi

Ijtimoiy:
• Boshqa bolalar bilan o''ynaydi
• Navbat kutishni o''rganadi
• Oddiy qoidalarni tushunadi

Agar kechikish bo''lsa:
Mutaxassis (logoped, pediatr) bilan maslahatlashing.',
     'development', 3, 'Pediatr Dr. Sarvinoz Mirzayeva'),

    ('5-6 yoshdagi bolaning rivojlanishi',
     'Maktabga tayyorlik bosqichi.

Aqliy tayyorlik:
• Ranglar, shakllar, sonlar (1-10) biladi
• Sabab-natija bog''liqligini tushunadi
• Diqqatini 15-20 daqiqa ushlaydi

Nutq tayyorligi:
• Rasmga qarab hikoya tuzadi
• So''z o''yinlarini tushunadi

Qo''l motorikasi:
• Qaychi ishlatadi
• Qalam to''g''ri ushlaydi

Maktabga tayyorlik:
✓ O''z ismini yozadi
✓ 1 dan 10 gacha sanaydi
✓ Geometrik shakllarni biladi',
     'development', 5, 'Pedagog Nilufar Xolmatova'),

    ('Mayda motorika rivojlanishi',
     'Mayda motorika — barmoqlar va qo''l harakatlarini nazorat qilish. Bu miya rivojlanishi bilan bog''liq.

Nima uchun muhim:
• Yozishga tayyorlik
• Miya-qo''l koordinatsiyasi
• Diqqatni rivojlantirish

Faoliyatlar (3-4 yosh):
✓ Plastilin bilan ishlash
✓ Qog''oz yirtish va yapish
✓ Tugmachalarni qadash
✓ Mozaika yig''ish

Faoliyatlar (5-6 yosh):
✓ Qaychi bilan kesish
✓ Ipga munchoq tizish
✓ Chiziqni bo''yash
✓ Origami

Kuniga 10-15 daqiqa kifoya.',
     'development', NULL, 'Ergoterapeut Malika Yusupova'),

    ('Ijodiy rivojlanish va san''at',
     'Ijodiy faoliyat bolaning aqliy va emotsional rivojlanishida muhim o''rin tutadi.

Ijodiy faoliyat turlari:
🎨 Rasm va bo''yash
✂️ Applique (qirqish-yapish)
🏺 Plastilin va gil
🎭 Teatr va rol o''yinlar
🎵 Musiqa va raqS

Nima beradi:
• O''z-o''zini ifoda etish imkoni
• Muammoni ijodiy hal qilish
• His-tuyg''ularni chiqarish
• Qo''l motorikasi rivojlanishi

Muhim: Natijani emas, jarayonni maqtang!
"Chizding! Shu ranglarni qanday tanladingga hayronman" — bu to''g''ri.
"Yaxshi chizding!" — bu kam.',
     'development', NULL, 'San''at terapevti Dilnoza Tosheva')
    """)


def downgrade() -> None:
    op.execute("DELETE FROM recommendations")
    op.execute("DELETE FROM stories")
    op.drop_index('ix_recommendations_category', 'recommendations')
    op.drop_index('ix_stories_category', 'stories')
    op.drop_index('ix_stories_age_group', 'stories')
    op.drop_table('recommendations')
    op.drop_table('stories')
    op.execute("DROP TYPE IF EXISTS storycategory")
    op.execute("DROP TYPE IF EXISTS recommendationcategory")
