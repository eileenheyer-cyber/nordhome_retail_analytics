"""
=============================================================================
  Synthetic E-Commerce Dataset Generator
  Company: NordHome — A fictional European online retailer
  Seed:    42  (fully reproducible)
  Deps:    pandas, numpy  (no external faker needed)
=============================================================================

Generates 7 intentionally-messy CSV files for end-to-end analytics practice.
All dirty-data injections are marked with  # [DIRTY]  comments.
=============================================================================
"""

import os
import random
import numpy as np
import pandas as pd
from datetime import datetime, timedelta

# ── Reproducibility ──────────────────────────────────────────────────────────
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

# ── Output folder ────────────────────────────────────────────────────────────
OUTPUT_DIR = os.path.join("data", "raw")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── Size constants ────────────────────────────────────────────────────────────
N_CUSTOMERS = 8_200
N_PRODUCTS  = 1_050
N_ORDERS    = 31_000
N_CAMPAIGNS = 12_000

# ── Date window ───────────────────────────────────────────────────────────────
START_DATE = datetime(2021, 1, 1)
END_DATE   = datetime(2024, 6, 30)

# ── Static name lists (replaces Faker) ───────────────────────────────────────
FIRST_NAMES = [
    "Emma","Liam","Olivia","Noah","Ava","Elijah","Sophia","Lucas","Isabella","Mason",
    "Mia","Ethan","Charlotte","James","Amelia","Aiden","Harper","Logan","Evelyn","Jackson",
    "Abigail","Sebastian","Emily","Mateo","Elizabeth","Jack","Mila","Owen","Ella","Theodore",
    "Scarlett","Levi","Grace","Henry","Zoey","Alexander","Penelope","Daniel","Riley","Michael",
    "Layla","Benjamin","Nora","Elias","Lily","Grayson","Eleanor","Julian","Hannah","Christopher",
    "Lillian","Joseph","Addison","David","Aubrey","Carter","Ellie","Wyatt","Stella","John",
    "Natalia","Owen","Zoe","Dylan","Leah","Luke","Hazel","Gabriel","Violet","Anthony",
    "Aurora","Isaac","Savannah","Lincoln","Audrey","Anna","Sara","Aria","Chloe","Maya",
    "Klara","Lars","Ingrid","Bjorn","Astrid","Henrik","Sigrid","Erik","Maja","Sven",
    "Marie","Pierre","Sophie","Jean","Camille","François","Isabelle","Philippe","Claire","Nicolas",
    "Anna","Max","Sarah","Felix","Laura","Jonas","Julia","Thomas","Lena","Andreas",
    "Zofia","Marek","Agnieszka","Piotr","Katarzyna","Tomasz","Marta","Krzysztof","Monika","Jan",
]

LAST_NAMES = [
    "Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Martinez","Wilson",
    "Anderson","Taylor","Thomas","Jackson","White","Harris","Martin","Thompson","Young","Allen",
    "King","Wright","Scott","Torres","Nguyen","Hill","Flores","Green","Adams","Nelson",
    "Baker","Hall","Rivera","Campbell","Mitchell","Carter","Roberts","Turner","Phillips","Evans",
    "Edwards","Collins","Stewart","Morris","Murphy","Cook","Rogers","Morgan","Peterson","Cooper",
    "Müller","Schmidt","Schneider","Fischer","Weber","Meyer","Wagner","Becker","Schulz","Hoffmann",
    "Schäfer","Koch","Bauer","Richter","Klein","Wolf","Schröder","Neumann","Schwarz","Zimmermann",
    "Dupont","Leroy","Moreau","Simon","Laurent","Lefebvre","Michel","Garcia","David","Bertrand",
    "Janssen","De Vries","Van den Berg","Bakker","Visser","Smit","Meijer","De Jong","Peters","Mulder",
    "Andersen","Johansen","Hansen","Pedersen","Nielsen","Jensen","Larsen","Sorensen","Rasmussen","Christensen",
    "Kowalski","Wiśniewski","Wójcik","Kowalczyk","Kamiński","Lewandowski","Zieliński","Woźniak","Szymański","Dąbrowski",
]

EMAIL_DOMAINS = [
    "gmail.com","yahoo.com","hotmail.com","outlook.com","icloud.com",
    "web.de","gmx.de","orange.fr","laposte.net","wanadoo.fr",
    "t-online.de","freenet.de","proximus.be","ziggo.nl","kpn.nl",
]

CITIES = {
    "Germany":     ["Berlin","Hamburg","Munich","Cologne","Frankfurt","Stuttgart","Düsseldorf","Leipzig","Dortmund","Essen"],
    "France":      ["Paris","Lyon","Marseille","Toulouse","Nice","Nantes","Strasbourg","Montpellier","Bordeaux","Lille"],
    "Netherlands": ["Amsterdam","Rotterdam","The Hague","Utrecht","Eindhoven","Tilburg","Groningen","Almere","Breda","Nijmegen"],
    "Sweden":      ["Stockholm","Gothenburg","Malmö","Uppsala","Västerås","Örebro","Linköping","Helsingborg","Jönköping","Norrköping"],
    "Denmark":     ["Copenhagen","Aarhus","Odense","Aalborg","Esbjerg","Randers","Kolding","Horsens","Vejle","Roskilde"],
    "Norway":      ["Oslo","Bergen","Trondheim","Stavanger","Drammen","Fredrikstad","Kristiansand","Sandnes","Tromsø","Sarpsborg"],
    "Belgium":     ["Brussels","Antwerp","Ghent","Charleroi","Liège","Bruges","Namur","Leuven","Mons","Mechelen"],
    "Austria":     ["Vienna","Graz","Linz","Salzburg","Innsbruck","Klagenfurt","Villach","Wels","Sankt Pölten","Dornbirn"],
    "Switzerland": ["Zurich","Geneva","Basel","Bern","Lausanne","Winterthur","Lucerne","St. Gallen","Lugano","Biel"],
    "Poland":      ["Warsaw","Kraków","Łódź","Wrocław","Poznań","Gdańsk","Szczecin","Bydgoszcz","Lublin","Katowice"],
}

PHONE_PREFIXES = {
    "Germany":"+49","France":"+33","Netherlands":"+31","Sweden":"+46",
    "Denmark":"+45","Norway":"+47","Belgium":"+32","Austria":"+43",
    "Switzerland":"+41","Poland":"+48",
}


# =============================================================================
#  HELPERS
# =============================================================================

def rand_date(start: datetime, end: datetime) -> datetime:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))

def fmt_date(dt: datetime, style: int) -> str:
    if style == 0: return dt.strftime("%Y-%m-%d")
    if style == 1: return dt.strftime("%d/%m/%Y")
    return dt.strftime("%m-%d-%Y")

def mixed_date(dt: datetime, dirty_prob: float = 0.22) -> str:          # [DIRTY]
    if random.random() < dirty_prob:
        return fmt_date(dt, random.choice([1, 2]))
    return fmt_date(dt, 0)

def maybe_null(value, prob: float = 0.07):                              # [DIRTY]
    return None if random.random() < prob else value

def add_space_noise(text: str, prob: float = 0.05) -> str:              # [DIRTY]
    if not isinstance(text, str): return text
    if random.random() < prob:
        sp = " " * random.randint(1, 2)
        side = random.choice(["L","R","B"])
        if side == "L": return sp + text
        if side == "R": return text + sp
        return sp + text + sp
    return text

def random_casing(text: str, prob: float = 0.07) -> str:               # [DIRTY]
    if not isinstance(text, str): return text
    if random.random() < prob:
        return random.choice([text.upper(), text.lower()])
    return text

def gen_email(first: str, last: str) -> str:
    domain = random.choice(EMAIL_DOMAINS)
    sep    = random.choice([".", "_", ""])
    suffix = str(random.randint(1, 999)) if random.random() > 0.5 else ""
    base   = f"{first.lower()}{sep}{last.lower()}{suffix}@{domain}"
    # [DIRTY] occasional ALL-CAPS email
    if random.random() < 0.04:
        return base.upper()
    return base

def gen_phone(country: str) -> str:
    prefix = PHONE_PREFIXES.get(country, "+00")
    digits = "".join([str(random.randint(0,9)) for _ in range(9)])
    return f"{prefix} {digits[:3]} {digits[3:6]} {digits[6:]}"


# =============================================================================
#  1. CUSTOMERS
# =============================================================================

def generate_customers() -> pd.DataFrame:
    print("  Generating customers …")

    COUNTRIES_CLEAN = list(CITIES.keys())

    COUNTRY_ALIASES = {                                                  # [DIRTY]
        "Germany":     ["Germany","DE","Deutschland","germany","GERMANY"],
        "France":      ["France","FR","france","FRANCE"],
        "Netherlands": ["Netherlands","NL","The Netherlands","netherlands"],
        "Sweden":      ["Sweden","SE","sweden"],
        "Denmark":     ["Denmark","DK","denmark"],
        "Norway":      ["Norway","NO","norway"],
        "Belgium":     ["Belgium","BE","belgium"],
        "Austria":     ["Austria","AT","austria"],
        "Switzerland": ["Switzerland","CH","Schweiz","switzerland"],
        "Poland":      ["Poland","PL","poland"],
    }

    CHANNELS  = ["Organic Search","Paid Social","Email","Referral","Direct","Influencer","Affiliate"]
    GENDERS   = ["Male","Female","Non-binary","Prefer not to say"]
    LOYALTY   = ["Y","N","Yes","No","TRUE","FALSE","1","0"]             # [DIRTY] inconsistent

    rows = []
    for i in range(1, N_CUSTOMERS + 1):
        country_clean   = random.choice(COUNTRIES_CLEAN)
        country_display = random.choice(COUNTRY_ALIASES[country_clean]) # [DIRTY]
        city            = random.choice(CITIES[country_clean])
        first           = random.choice(FIRST_NAMES)
        last            = random.choice(LAST_NAMES)
        email           = gen_email(first, last)
        phone           = gen_phone(country_clean)

        birth_year = random.randint(1950, 2005)
        if random.random() < 0.01:                                      # [DIRTY] unrealistic
            birth_year = random.choice([1890, 2020, 2025, 1800])

        reg_date = rand_date(START_DATE, END_DATE)

        rows.append({
            "customer_id":      f"CUST-{i:05d}",
            "first_name":       add_space_noise(random_casing(first)),
            "last_name":        add_space_noise(random_casing(last)),
            "email":            maybe_null(add_space_noise(email), prob=0.05),   # [DIRTY]
            "phone":            maybe_null(phone, prob=0.12),                    # [DIRTY]
            "country":          add_space_noise(country_display),
            "city":             add_space_noise(city),
            "registration_date": mixed_date(reg_date),
            "birth_year":       maybe_null(birth_year, prob=0.08),               # [DIRTY]
            "gender":           random.choice(GENDERS),
            "marketing_channel": random.choice(CHANNELS),
            "loyalty_member":   random.choice(LOYALTY),
        })

    df = pd.DataFrame(rows)

    # ── Duplicate customer rows (different email casing) ── [DIRTY]
    n_dupes   = int(N_CUSTOMERS * 0.02)
    dupe_rows = df.sample(n=n_dupes, random_state=SEED).copy()
    dupe_rows["email"] = dupe_rows["email"].apply(
        lambda e: e.title() if isinstance(e, str) else e
    )
    dupe_rows["customer_id"] = [f"CUST-{N_CUSTOMERS + j + 1:05d}" for j in range(n_dupes)]
    df = pd.concat([df, dupe_rows], ignore_index=True)

    print(f"    → {len(df):,} rows  (incl. {n_dupes} duplicates)")
    return df


# =============================================================================
#  2. PRODUCTS
# =============================================================================

def generate_products() -> pd.DataFrame:
    print("  Generating products …")

    CATALOGUE = {
        "Home":      {
            "Decor":      ["Scented Candle","Picture Frame","Wall Clock","Throw Pillow","Woven Basket","Ceramic Vase","Artificial Plant"],
            "Bedding":    ["Duvet Set","Pillow Case Set","Bed Runner","Mattress Topper","Weighted Blanket"],
            "Lighting":   ["Table Lamp","Pendant Light","LED Strip","Fairy Lights","Floor Lamp"],
        },
        "Kitchen":   {
            "Cookware":   ["Non-Stick Pan","Cast Iron Skillet","Saucepan Set","Wok","Roasting Tin"],
            "Utensils":   ["Silicone Spatula","Knife Set","Cutting Board","Grater","Whisk"],
            "Storage":    ["Glass Jar Set","Spice Rack","Bento Box","Food Container Set","Bread Bin"],
            "Appliances": ["Milk Frother","Electric Kettle","Toaster","Hand Blender","Coffee Grinder"],
        },
        "Beauty":    {
            "Skincare":   ["Face Serum","Moisturiser","Eye Cream","Face Mask Set","Toning Mist"],
            "Haircare":   ["Hair Oil","Silk Hair Wrap","Detangling Brush","Scalp Massager","Dry Shampoo"],
            "Bodycare":   ["Body Scrub","Shea Butter Cream","Bath Salts","Shower Oil","Body Lotion"],
        },
        "Lifestyle": {
            "Wellness":   ["Yoga Mat","Resistance Bands","Foam Roller","Meditation Cushion","Balance Board"],
            "Stationery": ["Leather Journal","Fountain Pen Set","Washi Tape Pack","Sticky Notes","Desk Organiser"],
            "Travel":     ["Packing Cubes","Cable Organiser","Travel Pillow","Luggage Tag","Passport Holder"],
        },
        "Gifts":     {
            "Gift Sets":  ["Spa Gift Set","Gourmet Hamper","Cocktail Kit","Candle Collection","Tea Gift Set"],
            "Novelty":    ["Personalised Mug","Custom Phone Case","Novelty Socks","Photo Book","Desk Plant Kit"],
        },
    }

    BRANDS   = ["NordHome","HausStil","MaisonVie","PureEssence","UrbanNest",
                "CozyLiving","ArcticBloom","Lumière","EcoKraft","WholesomeGoods"]
    VARIANTS = ["","Pro","Lite","XL","Mini","Classic","Premium","Organic","Limited Edition","Deluxe"]

    rows = []
    pid  = 1
    while pid <= N_PRODUCTS:
        category    = random.choice(list(CATALOGUE.keys()))
        subcats     = CATALOGUE[category]
        subcategory = random.choice(list(subcats.keys()))
        base_name   = random.choice(subcats[subcategory])
        variant     = random.choice(VARIANTS)
        product_name = f"{base_name} {variant}".strip() if variant else base_name

        brand      = random.choice(BRANDS)
        unit_cost  = round(random.uniform(2.0, 120.0), 2)
        list_price = round(unit_cost * random.uniform(1.4, 3.2), 2)

        if random.random() < 0.005:                                     # [DIRTY] zero price
            list_price = 0.0

        launched  = rand_date(datetime(2018, 1, 1), datetime(2024, 1, 1))
        disc_flag = "Y" if (random.random() < 0.12 and launched < datetime(2022, 1, 1)) else "N"

        rows.append({
            "product_id":        f"PROD-{pid:04d}",
            "product_name":      add_space_noise(product_name),
            "category":          maybe_null(add_space_noise(category), prob=0.04),  # [DIRTY]
            "subcategory":       subcategory,
            "brand":             brand,
            "unit_cost":         unit_cost,
            "list_price":        list_price,
            "launch_date":       launched.strftime("%Y-%m-%d"),
            "discontinued_flag": disc_flag,
        })
        pid += 1

    df = pd.DataFrame(rows)

    # ── Duplicate product name rows ── [DIRTY]
    n_dupes   = 40
    dupe_rows = df.sample(n=n_dupes, random_state=SEED).copy()
    for j, idx in enumerate(dupe_rows.index):
        orig = str(dupe_rows.loc[idx, "product_name"]).strip()
        dupe_rows.loc[idx, "product_name"] = random.choice([
            orig.upper(), orig.lower(), "  " + orig, orig + "  ", orig.replace(" ", "  ")
        ])
        dupe_rows.loc[idx, "product_id"] = f"PROD-{pid:04d}"
        pid += 1

    df = pd.concat([df, dupe_rows], ignore_index=True)
    print(f"    → {len(df):,} rows  (incl. {n_dupes} name-duplicates)")
    return df


# =============================================================================
#  3. ORDERS
# =============================================================================

def generate_orders(customer_ids: list) -> pd.DataFrame:
    print("  Generating orders …")

    STATUSES  = ["Completed","Shipped","Processing","Cancelled","Returned","Refunded"]
    CHANNELS  = ["Website","Mobile App","Marketplace","Phone"]
    SHIPPING  = ["Standard","Express","Next Day","Click & Collect","Free Shipping"]
    COUNTRIES = list(CITIES.keys())

    rows = []
    for i in range(1, N_ORDERS + 1):
        cust_id  = random.choice(customer_ids)
        order_dt = rand_date(START_DATE, END_DATE)
        status   = random.choices(STATUSES, weights=[55,20,8,7,5,5])[0]

        rows.append({
            "order_id":        f"ORD-{i:06d}",
            "customer_id":     cust_id,
            "order_date":      mixed_date(order_dt),
            "order_status":    status,
            "country":         random.choice(COUNTRIES),
            "sales_channel":   random.choice(CHANNELS),
            "shipping_method": random.choice(SHIPPING),
        })

    df = pd.DataFrame(rows)

    # ── Orphan customer_ids ── [DIRTY]
    bad_n   = int(N_ORDERS * 0.008)
    bad_idx = df.sample(n=bad_n, random_state=SEED).index
    df.loc[bad_idx, "customer_id"] = [f"CUST-GHOST-{j}" for j in range(bad_n)]

    # ── Duplicate order rows ── [DIRTY]
    n_dupes = int(N_ORDERS * 0.015)
    dupes   = df.sample(n=n_dupes, random_state=SEED).copy()
    df      = pd.concat([df, dupes], ignore_index=True)

    print(f"    → {len(df):,} rows  (incl. {n_dupes} dupe rows, {bad_n} orphan cust_ids)")
    return df


# =============================================================================
#  4. ORDER ITEMS
# =============================================================================

def generate_order_items(order_ids: list, product_ids: list) -> pd.DataFrame:
    print("  Generating order items …")

    rows   = []
    item_n = 1

    for oid in order_ids:
        n_items = max(1, int(np.random.poisson(2.3)))
        prods   = random.choices(product_ids, k=n_items)
        for pid in prods:
            qty      = random.randint(1, 5)
            price    = round(random.uniform(5.0, 250.0), 2)
            discount = round(random.uniform(0, 0.30), 4)
            lt       = round(qty * price * (1 - discount), 2)

            if random.random() < 0.03:  lt  = round(lt * random.uniform(0.5,1.5), 2)  # [DIRTY] wrong total
            if random.random() < 0.005: qty = -qty                                     # [DIRTY] negative qty
            if random.random() < 0.003: qty = random.randint(500, 2000)               # [DIRTY] extreme qty
            if random.random() < 0.004: discount = round(random.uniform(1.01, 2.5), 4)# [DIRTY] >100% discount
            if random.random() < 0.003: price = 0.0                                   # [DIRTY] zero price

            rows.append({
                "order_item_id": f"ITEM-{item_n:07d}",
                "order_id":      oid,
                "product_id":    pid,
                "quantity":      qty,
                "unit_price":    price,
                "discount":      discount,
                "line_total":    lt,
            })
            item_n += 1

    df = pd.DataFrame(rows)

    # Pad to guarantee >70 k rows
    while len(df) < 70_000:
        qty   = random.randint(1, 4)
        price = round(random.uniform(5.0, 200.0), 2)
        disc  = round(random.uniform(0, 0.25), 4)
        df = pd.concat([df, pd.DataFrame([{
            "order_item_id": f"ITEM-{item_n:07d}",
            "order_id":      random.choice(order_ids),
            "product_id":    random.choice(product_ids),
            "quantity":      qty, "unit_price": price, "discount": disc,
            "line_total":    round(qty * price * (1 - disc), 2),
        }])], ignore_index=True)
        item_n += 1

    # ── Ghost product_ids ── [DIRTY]
    bad_n   = int(len(df) * 0.006)
    bad_idx = df.sample(n=bad_n, random_state=SEED).index
    df.loc[bad_idx, "product_id"] = [f"PROD-GHOST-{j}" for j in range(bad_n)]

    print(f"    → {len(df):,} rows")
    return df


# =============================================================================
#  5. PAYMENTS
# =============================================================================

def parse_any_date(s: str) -> datetime:
    for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%m-%d-%Y"):
        try:
            return datetime.strptime(str(s), fmt)
        except ValueError:
            continue
    return START_DATE

def generate_payments(orders_df: pd.DataFrame) -> pd.DataFrame:
    print("  Generating payments …")

    METHODS = [                                                          # [DIRTY] many spellings
        "Credit Card","creditcard","CC","card",
        "Debit Card","debit","Debit",
        "PayPal","paypal","PAYPAL",
        "Bank Transfer","bank transfer","BankTransfer",
        "Apple Pay","applepay",
        "Klarna","Buy Now Pay Later",
    ]
    STATUSES = ["Paid","Pending","Failed","Refunded","Partially Refunded"]

    date_map = dict(zip(orders_df["order_id"], orders_df["order_date"]))

    rows = []
    for i, oid in enumerate(orders_df["order_id"]):
        order_dt = parse_any_date(date_map[oid])
        pay_dt   = order_dt + timedelta(days=random.randint(0, 3))

        if random.random() < 0.015:                                     # [DIRTY] pay before order
            pay_dt = order_dt - timedelta(days=random.randint(1, 10))

        rows.append({
            "payment_id":     f"PAY-{i+1:07d}",
            "order_id":       oid,
            "payment_method": maybe_null(random.choice(METHODS), prob=0.06),  # [DIRTY]
            "payment_status": random.choices(STATUSES, weights=[70,10,5,10,5])[0],
            "payment_date":   mixed_date(pay_dt),
            "payment_amount": round(random.uniform(10.0, 600.0), 2),
        })

    df = pd.DataFrame(rows)

    # ── Ghost order_ids ── [DIRTY]
    bad_n   = int(len(df) * 0.007)
    bad_idx = df.sample(n=bad_n, random_state=SEED).index
    df.loc[bad_idx, "order_id"] = [f"ORD-GHOST-{j:06d}" for j in range(bad_n)]

    # ── Duplicate payments ── [DIRTY]
    n_dupes = int(len(df) * 0.015)
    dupes   = df.sample(n=n_dupes, random_state=SEED).copy()
    df      = pd.concat([df, dupes], ignore_index=True)

    print(f"    → {len(df):,} rows  (incl. {n_dupes} dupe payments)")
    return df


# =============================================================================
#  6. RETURNS
# =============================================================================

def generate_returns(orders_df: pd.DataFrame, items_df: pd.DataFrame) -> pd.DataFrame:
    print("  Generating returns …")

    REASONS = [
        "Damaged on arrival","Wrong item sent","Changed mind",
        "Not as described","Poor quality","Duplicate order",
        "No longer needed","Better price elsewhere",
    ]

    date_map     = dict(zip(orders_df["order_id"], orders_df["order_date"]))
    product_pool = items_df["product_id"].dropna().unique().tolist()
    valid_orders = orders_df[~orders_df["order_id"].str.contains("GHOST")]

    n_ret   = int(len(items_df) * 0.08)
    sampled = valid_orders.sample(n=min(n_ret, len(valid_orders)), random_state=SEED)

    rows = []
    for i, (_, row) in enumerate(sampled.iterrows()):
        oid      = row["order_id"]
        order_dt = parse_any_date(date_map.get(oid, "2022-01-01"))
        ret_dt   = order_dt + timedelta(days=random.randint(1, 30))

        if random.random() < 0.02:                                      # [DIRTY] return before order
            ret_dt = order_dt - timedelta(days=random.randint(1, 5))

        refund = round(random.uniform(5.0, 300.0), 2)
        if random.random() < 0.005:                                     # [DIRTY] negative refund
            refund = -abs(refund)

        rows.append({
            "return_id":     f"RET-{i+1:06d}",
            "order_id":      oid,
            "product_id":    random.choice(product_pool),
            "return_date":   mixed_date(ret_dt),
            "return_reason": maybe_null(random.choice(REASONS), prob=0.10),  # [DIRTY]
            "refund_amount": refund,
        })

    # ── Orphan returns (no matching order) ── [DIRTY]
    for j in range(60):
        rows.append({
            "return_id":     f"RET-GHOST-{j:04d}",
            "order_id":      f"ORD-GHOST-{j:06d}",
            "product_id":    random.choice(product_pool),
            "return_date":   rand_date(START_DATE, END_DATE).strftime("%Y-%m-%d"),
            "return_reason": random.choice(REASONS),
            "refund_amount": round(random.uniform(5.0, 150.0), 2),
        })

    df = pd.DataFrame(rows)
    print(f"    → {len(df):,} rows  (incl. 60 orphan returns)")
    return df


# =============================================================================
#  7. MARKETING CAMPAIGNS
# =============================================================================

def generate_campaigns(customer_ids: list) -> pd.DataFrame:
    print("  Generating marketing campaigns …")

    CAMPAIGNS = [
        ("SUMMER_SALE_2021",    "Summer Sale 2021"),
        ("BLACK_FRIDAY_2021",   "Black Friday 2021"),
        ("VALENTINES_2022",     "Valentine's Day 2022"),
        ("SPRING_REFRESH_2022", "Spring Refresh 2022"),
        ("SUMMER_SALE_2022",    "Summer Sale 2022"),
        ("BLACK_FRIDAY_2022",   "Black Friday 2022"),
        ("CHRISTMAS_2022",      "Christmas 2022"),
        ("NEW_YEAR_2023",       "New Year New Home 2023"),
        ("SPRING_REFRESH_2023", "Spring Refresh 2023"),
        ("SUMMER_SALE_2023",    "Summer Sale 2023"),
        ("BLACK_FRIDAY_2023",   "Black Friday 2023"),
        ("CHRISTMAS_2023",      "Christmas 2023"),
        ("VALENTINES_2024",     "Valentine's Day 2024"),
        ("SPRING_REFRESH_2024", "Spring Refresh 2024"),
    ]

    CHANNELS = ["Email","Paid Social","Display","Push Notification","SMS","Influencer","Affiliate"]

    rows = []
    for i in range(1, N_CAMPAIGNS + 1):
        camp_code, camp_name = random.choice(CAMPAIGNS)
        channel  = random.choice(CHANNELS)
        cust_id  = random.choice(customer_ids)

        try:
            year = int(camp_code[-4:])
        except ValueError:
            year = 2022
        camp_dt = rand_date(datetime(max(2021, year), 1, 1),
                            datetime(min(2024, year), 12, 31))

        clicked   = random.choices([1, 0], weights=[30, 70])[0]
        converted = 1 if (clicked and random.random() < 0.20) else 0

        rows.append({
            "campaign_id":   f"CAMP-{i:06d}",
            "customer_id":   cust_id,
            "campaign_name": camp_name,
            "channel":       channel,
            "campaign_date": mixed_date(camp_dt),
            "clicked":       clicked,
            "converted":     converted,
        })

    df = pd.DataFrame(rows)
    print(f"    → {len(df):,} rows")
    return df


# =============================================================================
#  MAIN
# =============================================================================

def main():
    print("\n" + "=" * 65)
    print("  NordHome Synthetic Dataset Generator — Seed 42")
    print("=" * 65)

    customers_df  = generate_customers()
    real_cust_ids = [c for c in customers_df["customer_id"] if "GHOST" not in c]

    products_df   = generate_products()
    real_prod_ids = [p for p in products_df["product_id"] if "GHOST" not in p]

    orders_df     = generate_orders(real_cust_ids)
    real_ord_ids  = [o for o in orders_df["order_id"] if "GHOST" not in o]

    items_df      = generate_order_items(real_ord_ids, real_prod_ids)
    payments_df   = generate_payments(orders_df)
    returns_df    = generate_returns(orders_df, items_df)
    campaigns_df  = generate_campaigns(real_cust_ids)

    print("\n  Saving CSV files …")
    files = {
        "raw_customers.csv":          customers_df,
        "raw_products.csv":           products_df,
        "raw_orders.csv":             orders_df,
        "raw_order_items.csv":        items_df,
        "raw_payments.csv":           payments_df,
        "raw_returns.csv":            returns_df,
        "raw_marketing_campaigns.csv": campaigns_df,
    }

    total = 0
    for fname, df in files.items():
        path = os.path.join(OUTPUT_DIR, fname)
        df.to_csv(path, index=False)
        total += len(df)
        print(f"    ✓ {fname:<40} {len(df):>9,} rows")

    print("\n" + "=" * 65)
    print(f"  Total rows : {total:,}")
    print(f"  Output     : {os.path.abspath(OUTPUT_DIR)}")
    print("=" * 65 + "\n")


if __name__ == "__main__":
    main()