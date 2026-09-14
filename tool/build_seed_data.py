#!/usr/bin/env python3
"""
Builds assets/data/seed_targets.json from every source file the user provided.

Sources
  source_data/AIH App Master IT Jobs + Recuiters - Google Drive_files/sheet.html
      -> 694 German companies (industry, city, career page, LinkedIn)
  source_data/AIH App Master IT Jobs + Recuiters - Google Drive 2_files/sheet.html
      -> 266 companies across DE/UK/IE/AT/NL/BE + 44 recruiters & portals
  source_data/AIH App Master IT Jobs + Recuiters - Google Drive 3_files/sheet.html
      -> 142 job boards / visa-sponsor sites / agencies (some with outcome notes)
  source_data/Netherlands Hiring Companies.xlsx
      -> 100 Netherlands companies with career-page hyperlinks
  source_data/germany.txt, netherlands.txt, country wise companies.txt, luxembourg.txt
      -> curated shortlists and staffing agencies per country
  infographics (image*.png)
      -> government portals, local job portals, recruiter databases (transcribed below)

The merge is name+country keyed and additive: a record present in several sources
keeps the richest value for every field. Nothing is dropped.
"""

import csv
import html
import json
import os
import re
import sys
import unicodedata
import zipfile
from collections import OrderedDict
from html.parser import HTMLParser

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "source_data")
OUT = os.path.join(ROOT, "assets", "data", "seed_targets.json")

SHEET1 = os.path.join(SRC, "AIH App Master IT Jobs + Recuiters - Google Drive_files", "sheet.html")
SHEET2 = os.path.join(SRC, "AIH App Master IT Jobs + Recuiters - Google Drive 2_files", "sheet.html")
SHEET3 = os.path.join(SRC, "AIH App Master IT Jobs + Recuiters - Google Drive 3_files", "sheet.html")
XLSX = os.path.join(SRC, "Netherlands Hiring Companies.xlsx")


# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #

MOJIBAKE = {
    "â€‘": "-", "â€“": "-", "â€”": "-", "â€™": "'", "â€˜": "'",
    "â€œ": '"', "â€\x9d": '"', "â€¦": "...", "Ã¤": "ä", "Ã¶": "ö",
    "Ã¼": "ü", "ÃŸ": "ß", "Ã„": "Ä", "Ã–": "Ö", "Ãœ": "Ü", "Ã©": "é",
    "Ã¨": "è", "Ã¡": "á", "Ã­": "í", "Ã³": "ó", "Ãº": "ú", "Ã±": "ñ",
    "Ã§": "ç", "Ã¥": "å", "Ã¸": "ø", "Ã¦": "æ",
}


def clean(text):
    """Normalise whitespace, strip emoji/bullets, repair mojibake."""
    if not text:
        return ""
    s = html.unescape(str(text))
    for bad, good in MOJIBAKE.items():
        s = s.replace(bad, good)
    # strip pictographs / flags / dingbats
    s = "".join(
        ch for ch in s
        if not (
            0x1F000 <= ord(ch) <= 0x1FAFF
            or 0x2600 <= ord(ch) <= 0x27BF
            or 0xFE00 <= ord(ch) <= 0xFE0F
            or ord(ch) == 0x20E3
        )
    )
    s = s.replace("​", " ").replace("\xa0", " ")
    s = re.sub(r"^[\s•·\-–—*✅✨🔹]+", "", s)
    # "1. Foo", "2) Foo", and the bare digit left behind by an emoji
    # keycap ("1️⃣ Foo" -> "1 Foo") once pictographs are stripped
    s = re.sub(r"^\d+\s*[\.\)]\s*", "", s)
    s = re.sub(r"^\d{1,2}\s+(?=[A-Za-z])", "", s)
    s = re.sub(r"\s+", " ", s).strip(" ,;|")
    return s.strip()


def norm_key(name):
    """Aggressive key for dedupe: casefold, strip legal suffixes & punctuation."""
    s = clean(name).lower()
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r"\(.*?\)", " ", s)
    s = re.sub(
        r"\b(gmbh & co\. kg|gmbh|ag|se|kg|nv|n\.v\.|bv|b\.v\.|inc|ltd|limited|"
        r"llc|plc|group|holding|holdings|deutschland|netherlands|nederland)\b",
        " ", s,
    )
    s = re.sub(r"[^a-z0-9]+", "", s)
    return s


def clean_url(u):
    u = clean(u)
    if not u:
        return ""
    # cells sometimes carry a trailing parenthetical note
    u = re.split(r"\s*\(", u)[0].strip()
    if not u.startswith("http"):
        return ""
    return u


class TableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.tables, self.rows, self.cur, self.cell, self.buf = [], [], None, None, []

    def handle_starttag(self, tag, attrs):
        if tag == "table":
            self.rows = []
        elif tag == "tr":
            self.cur = []
        elif tag in ("td", "th"):
            self.cell, self.buf = True, []

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self.cell:
            self.cur.append("".join(self.buf).strip())
            self.cell, self.buf = None, []
        elif tag == "tr" and self.cur is not None:
            self.rows.append(self.cur)
            self.cur = None
        elif tag == "table":
            self.tables.append(self.rows)
            self.rows = []

    def handle_data(self, d):
        if self.cell:
            self.buf.append(d)


def read_table(path):
    if not os.path.exists(path):
        sys.exit(f"MISSING SOURCE: {path}")
    p = TableParser()
    p.feed(open(path, encoding="utf-8", errors="replace").read())
    return p.tables[0] if p.tables else []


# --------------------------------------------------------------------------- #
# country / city normalisation
# --------------------------------------------------------------------------- #

CITY_COUNTRY = {
    "amsterdam": "Netherlands", "rotterdam": "Netherlands", "utrecht": "Netherlands",
    "eindhoven": "Netherlands", "the hague": "Netherlands", "veldhoven": "Netherlands",
    "berlin": "Germany", "munich": "Germany", "münchen": "Germany", "hamburg": "Germany",
    "cologne": "Germany", "köln": "Germany", "frankfurt": "Germany", "stuttgart": "Germany",
    "düsseldorf": "Germany", "dusseldorf": "Germany", "karlsruhe": "Germany",
    "heidelberg": "Germany", "bonn": "Germany", "potsdam": "Germany", "dresden": "Germany",
    "aachen": "Germany", "freiburg": "Germany", "leipzig": "Germany", "nuremberg": "Germany",
    "london": "United Kingdom", "oxford": "United Kingdom", "cambridge": "United Kingdom",
    "manchester": "United Kingdom", "dublin": "Ireland", "cork": "Ireland",
    "vienna": "Austria", "salzburg": "Austria", "graz": "Austria", "linz": "Austria",
    "brussels": "Belgium", "antwerp": "Belgium", "ghent": "Belgium",
    "paris": "France", "lyon": "France", "barcelona": "Spain", "madrid": "Spain",
    "san sebastian": "Spain", "lisbon": "Portugal", "porto": "Portugal",
    "stockholm": "Sweden", "gothenburg": "Sweden", "copenhagen": "Denmark",
    "helsinki": "Finland", "oslo": "Norway", "zurich": "Switzerland",
    "zürich": "Switzerland", "geneva": "Switzerland", "basel": "Switzerland",
    "warsaw": "Poland", "krakow": "Poland", "kraków": "Poland", "tallinn": "Estonia",
    "riga": "Latvia", "vilnius": "Lithuania", "prague": "Czech Republic",
    "milan": "Italy", "rome": "Italy", "luxembourg": "Luxembourg",
}

COUNTRY_ALIASES = {
    "uk": "United Kingdom", "u.k.": "United Kingdom", "united kingdom": "United Kingdom",
    "great britain": "United Kingdom", "england": "United Kingdom",
    "nl": "Netherlands", "netherlands": "Netherlands", "the netherlands": "Netherlands",
    "holland": "Netherlands", "de": "Germany", "germany": "Germany",
    "deutschland": "Germany", "ie": "Ireland", "ireland": "Ireland",
    "at": "Austria", "austria": "Austria", "be": "Belgium", "belgium": "Belgium",
    "fr": "France", "france": "France", "es": "Spain", "spain": "Spain",
    "pt": "Portugal", "portugal": "Portugal", "se": "Sweden", "sweden": "Sweden",
    "dk": "Denmark", "denmark": "Denmark", "fi": "Finland", "finland": "Finland",
    "no": "Norway", "norway": "Norway", "ch": "Switzerland", "switzerland": "Switzerland",
    "pl": "Poland", "poland": "Poland", "ee": "Estonia", "estonia": "Estonia",
    "lv": "Latvia", "latvia": "Latvia", "lt": "Lithuania", "lithuania": "Lithuania",
    "cz": "Czech Republic", "czech republic": "Czech Republic", "czechia": "Czech Republic",
    "it": "Italy", "italy": "Italy", "lu": "Luxembourg", "luxembourg": "Luxembourg",
    "mt": "Malta", "malta": "Malta", "cy": "Cyprus", "cyprus": "Cyprus",
}


def resolve_country(raw, fallback="", strict=False):
    """A cell may hold 'Berlin, Germany', 'Amsterdam 🇳🇱', 'UK,US, Canada' or a city.

    strict=True is for free-text notes ("Estonia offer received"): only return a
    country when one is actually named, never echo the note back as a country.
    """
    s = clean(raw)
    if not s:
        return fallback
    low = s.lower().strip()
    if low in COUNTRY_ALIASES:
        return COUNTRY_ALIASES[low]
    # try trailing token after a comma: "Berlin, Germany"
    parts = [p.strip().lower() for p in re.split(r"[,/]", low) if p.strip()]
    for p in reversed(parts):
        if p in COUNTRY_ALIASES:
            return COUNTRY_ALIASES[p]
    for p in parts:
        if p in CITY_COUNTRY:
            return CITY_COUNTRY[p]
    # scan free text for a country name, longest first so "United Kingdom"
    # wins over a bare "uk" substring
    for alias in sorted(COUNTRY_ALIASES, key=len, reverse=True):
        if len(alias) > 3 and re.search(r"\b" + re.escape(alias) + r"\b", low):
            return COUNTRY_ALIASES[alias]
    for city, country in CITY_COUNTRY.items():
        if re.search(r"\b" + re.escape(city) + r"\b", low):
            return country
    if "europe" in low:
        return "Europe (Multiple)"
    if strict:
        return fallback
    if len(parts) > 1:
        return "Multiple"
    return fallback or s.title()


def resolve_city(raw):
    s = clean(raw)
    if not s:
        return ""
    low = s.lower()
    if low in COUNTRY_ALIASES:
        return ""
    parts = [p.strip() for p in re.split(r"[,/]", s) if p.strip()]
    for p in parts:
        if p.lower() in CITY_COUNTRY:
            return p.title()
    if parts and parts[0].lower() not in COUNTRY_ALIASES:
        first = parts[0]
        return "" if first.lower().startswith("multiple") else first
    return ""


# --------------------------------------------------------------------------- #
# registry
# --------------------------------------------------------------------------- #

class Registry:
    """Merge-on-write store. Later writes only fill blanks, never overwrite data."""

    def __init__(self):
        self.items = OrderedDict()
        self.source_counts = {}

    def add(self, kind, name, *, country="", city="", industry="",
            career_url="", linkedin_url="", website="", note="",
            source="", tags=None, priority=None, specialization=""):
        name = clean(name)
        if not name or len(name) < 2:
            return None
        key = (kind, norm_key(name), country or "")
        # collapse same-name entries whose country was unknown in one source
        if key not in self.items:
            for (k2, n2, c2) in list(self.items):
                if k2 == kind and n2 == key[1] and (not c2 or not country):
                    key = (k2, n2, c2 or country)
                    break
        rec = self.items.get(key)
        if rec is None:
            rec = {
                "kind": kind, "name": name, "country": country, "city": city,
                "industry": industry, "careerUrl": career_url,
                "linkedinUrl": linkedin_url, "website": website,
                "specialization": specialization, "notes": note,
                "tags": list(tags or []), "sources": [],
            }
            if priority is not None:
                rec["priority"] = priority
            self.items[key] = rec
        else:
            for field, value in (
                ("country", country), ("city", city), ("industry", industry),
                ("careerUrl", career_url), ("linkedinUrl", linkedin_url),
                ("website", website), ("specialization", specialization),
            ):
                if value and not rec.get(field):
                    rec[field] = value
            if note and note not in rec["notes"]:
                rec["notes"] = (rec["notes"] + " | " + note).strip(" |")
            for t in tags or []:
                if t not in rec["tags"]:
                    rec["tags"].append(t)
            if priority is not None:
                rec["priority"] = max(rec.get("priority", 0), priority)
        if source and source not in rec["sources"]:
            rec["sources"].append(source)
        self.source_counts[source] = self.source_counts.get(source, 0) + 1
        return rec


REG = Registry()


# --------------------------------------------------------------------------- #
# 1. German master sheet (694 companies)
# --------------------------------------------------------------------------- #

def load_sheet1():
    rows = read_table(SHEET1)
    n = 0
    for r in rows[3:]:
        if len(r) < 4 or not clean(r[1]):
            continue
        name = clean(r[1])
        if name.lower() == "company":
            continue
        city_raw = clean(r[3])
        REG.add(
            "company", name,
            country="Germany",
            city="" if city_raw.lower().startswith("multiple") else city_raw,
            industry=clean(r[2]),
            career_url=clean_url(r[4] if len(r) > 4 else ""),
            linkedin_url=clean_url(r[5] if len(r) > 5 else ""),
            source="german_master_sheet",
            tags=["germany-master"],
        )
        n += 1
    return n


# --------------------------------------------------------------------------- #
# 2. Multi-country sheet: companies (col A-C) + recruiters (col E-G)
# --------------------------------------------------------------------------- #

def load_sheet2():
    rows = read_table(SHEET2)
    comp = rec = 0
    for r in rows[2:]:
        # companies
        if len(r) > 3 and clean(r[1]) and clean(r[1]).lower() != "company name":
            name = clean(r[1])
            raw_loc = r[3]
            REG.add(
                "company", name,
                country=resolve_country(raw_loc),
                city=resolve_city(raw_loc),
                career_url=clean_url(r[2]),
                source="multi_country_sheet",
                tags=["curated-target"],
            )
            comp += 1
        # recruitment agencies / portals
        if len(r) > 7 and clean(r[5]) and clean(r[5]).lower() != "recruitement company":
            name = clean(r[5])
            REG.add(
                "agency", name,
                country=resolve_country(r[7]),
                website=clean_url(r[6]),
                career_url=clean_url(r[6]),
                source="multi_country_sheet_recruiters",
                tags=["recruiter-portal"],
            )
            rec += 1
    return comp, rec


# --------------------------------------------------------------------------- #
# 3. Visa-sponsor / job-board sheet (142 rows, some with outcome notes)
# --------------------------------------------------------------------------- #

# rows whose "name" is really a heading / note rather than an entity
SHEET3_SKIP = {
    "company name", "rule changed for h1b",
    "for usa: below is the golden way of finding sponsor:",
}


def load_sheet3():
    rows = read_table(SHEET3)
    n = 0
    for r in rows[1:]:
        if len(r) < 3:
            continue
        name = clean(r[1])
        if not name or name.lower() in SHEET3_SKIP:
            continue
        if name.startswith("http"):
            continue
        if name.lower().startswith("note:"):
            continue
        url = clean_url(r[2])
        note = clean(r[3]) if len(r) > 3 else ""
        tags = ["visa-sponsor-source"]
        if note and re.search(r"offer\s*rec", note, re.I):
            tags.append("offer-received-here")
        REG.add(
            "agency", name,
            website=url, career_url=url,
            country=resolve_country(note, strict=True) if note else "",
            note=note,
            source="visa_sponsor_sheet",
            tags=tags,
        )
        n += 1
    return n


# --------------------------------------------------------------------------- #
# 4. Netherlands xlsx (100 companies + career hyperlinks)
# --------------------------------------------------------------------------- #

def load_xlsx():
    if not os.path.exists(XLSX):
        sys.exit(f"MISSING SOURCE: {XLSX}")
    z = zipfile.ZipFile(XLSX)
    shared = z.read("xl/sharedStrings.xml").decode("utf-8", errors="replace")
    strings = [
        html.unescape(re.sub("<[^>]+>", "", m))
        for m in re.findall(r"<si>(.*?)</si>", shared, re.S)
    ]
    sheet = z.read("xl/worksheets/sheet1.xml").decode("utf-8", errors="replace")
    rels = z.read("xl/worksheets/_rels/sheet1.xml.rels").decode("utf-8", errors="replace")
    relmap = dict(re.findall(r'Id="([^"]+)"[^>]*Target="([^"]+)"', rels))
    links = {}
    for m in re.findall(r"<hyperlink[^>]*/>", sheet):
        ref = re.search(r'ref="([^"]+)"', m)
        rid = re.search(r'r:id="([^"]+)"', m)
        if ref and rid:
            links[ref.group(1)] = relmap.get(rid.group(1), "")

    def val(cell_xml):
        t = re.search(r't="([^"]+)"', cell_xml)
        v = re.search(r"<v>(.*?)</v>", cell_xml, re.S)
        if not v:
            return ""
        if t and t.group(1) == "s":
            return strings[int(v.group(1))]
        return html.unescape(v.group(1))

    n = 0
    for _, body in re.findall(r'<row[^>]*r="(\d+)"[^>]*>(.*?)</row>', sheet, re.S):
        cells = re.findall(r'(<c[^>]*r="([A-Z]+\d+)"[^>]*(?:/>|>.*?</c>))', body, re.S)
        d = {}
        for full, ref in cells:
            d[re.sub(r"\d", "", ref)] = (val(full), links.get(ref, ""))
        name = clean(d.get("B", ("", ""))[0])
        if not name or name.lower() == "company":
            continue
        REG.add(
            "company", name,
            country="Netherlands",
            city=clean(d.get("D", ("", ""))[0]),
            industry=clean(d.get("C", ("", ""))[0]),
            career_url=clean_url(d.get("E", ("", ""))[1]),
            source="netherlands_xlsx",
            tags=["netherlands-top100"],
            priority=2,
        )
        n += 1
    return n


# --------------------------------------------------------------------------- #
# 5. Curated txt shortlists
# --------------------------------------------------------------------------- #

def load_txt_lists():
    added = 0

    # --- germany.txt: numbered list w/ city in parens, then themed shortlists
    path = os.path.join(SRC, "germany.txt")
    for line in open(path, encoding="utf-8", errors="replace"):
        raw = line.strip()
        if not raw:
            continue
        low = raw.lower()
        if low.startswith("top company list") or low.startswith("major giants"):
            continue
        name = clean(raw)
        if not name or len(name) < 2:
            continue
        # "Aldi South IT – Mülheim an der Ruhr" / "Zalando | Berlin" / "3D Spark (Hamburg)"
        city = ""
        m = re.match(r"^(.*?)\s*\((.*?)\)\s*$", name)
        if m:
            name, city = clean(m.group(1)), clean(m.group(2))
        elif "|" in name:
            a, b = name.split("|", 1)
            name, city = clean(a), clean(b)
        elif " - " in name or " – " in name:
            a, b = re.split(r"\s+[-–]\s+", name, maxsplit=1)
            if len(clean(b)) < 40:
                name, city = clean(a), clean(b)
        name = clean(name)
        if not name:
            continue
        REG.add(
            "company", name, country="Germany", city=city,
            source="germany_shortlist", tags=["germany-priority"], priority=3,
        )
        added += 1

    # --- netherlands.txt: "ASML — Technology · Veldhoven"
    path = os.path.join(SRC, "netherlands.txt")
    for line in open(path, encoding="utf-8", errors="replace"):
        raw = line.strip()
        if not raw or raw.lower().startswith("part "):
            continue
        s = clean(raw)
        name, industry, city = s, "", ""
        if "—" in s or "-" in s:
            parts = re.split(r"\s*[—–]\s*", s, maxsplit=1)
            if len(parts) == 2:
                name = clean(parts[0])
                rest = parts[1]
                if "·" in rest:
                    industry, city = [clean(x) for x in rest.split("·", 1)]
                else:
                    industry = clean(rest)
        if not name:
            continue
        REG.add(
            "company", name, country="Netherlands", city=city, industry=industry,
            source="netherlands_shortlist", tags=["netherlands-priority"], priority=3,
        )
        added += 1

    # --- country wise companies.txt: staffing agencies grouped under a country header
    path = os.path.join(SRC, "country wise companies.txt")
    current = ""
    for line in open(path, encoding="utf-8", errors="replace"):
        raw = line.rstrip()
        if not raw.strip():
            continue
        s = clean(raw)
        if not s:
            continue
        if not raw.lstrip().startswith("•"):
            current = COUNTRY_ALIASES.get(s.lower(), s)
            continue
        REG.add(
            "agency", s, country=current,
            specialization="General Recruitment",
            source="country_staffing_agencies",
            tags=["staffing-agency"], priority=2,
        )
        added += 1

    # --- luxembourg.txt: "Randstad Luxembourg → randstad.lu/en"
    path = os.path.join(SRC, "luxembourg.txt")
    for line in open(path, encoding="utf-8", errors="replace"):
        s = clean(line)
        if not s:
            continue
        name, url = s, ""
        if "→" in s:
            a, b = s.split("→", 1)
            name, url = clean(a), clean(b)
        if url and not url.startswith("http"):
            url = "https://" + url
        REG.add(
            "agency", name, country="Luxembourg", website=url, career_url=url,
            specialization="General Recruitment",
            source="luxembourg_agencies", tags=["staffing-agency"],
        )
        added += 1

    return added


# --------------------------------------------------------------------------- #
# 6. Infographics (transcribed from the uploaded images)
# --------------------------------------------------------------------------- #

GOV_PORTALS = [
    ("Make it in Germany", "Germany", "https://www.make-it-in-germany.com/en/looking-for-foreign-professionals/jobs",
     "Official portal for working and living in Germany."),
    ("Bundesagentur für Arbeit (BA)", "Germany", "https://www.arbeitsagentur.de/jobsuche/",
     "Germany's Federal Employment Agency."),
    ("UWV", "Netherlands", "https://www.uwv.nl/",
     "The public employment service of the Netherlands."),
    ("Werk.nl", "Netherlands", "https://www.werk.nl/werkzoekenden/vacatures/",
     "Official job site of the Dutch government."),
    ("AMS (Arbeitsmarktservice)", "Austria", "https://www.ams.at",
     "Public employment service of Austria."),
    ("VDAB", "Belgium", "https://www.vdab.be/",
     "Flemish public employment and training service."),
    ("Work in Denmark", "Denmark", "https://www.workindenmark.dk/",
     "Official site for international professionals."),
    ("Arbetsförmedlingen", "Sweden", "https://arbetsformedlingen.se/",
     "Sweden's Public Employment Service."),
    ("NAV", "Norway", "https://www.nav.no/",
     "Norway's Labour and Welfare Administration."),
    ("Job Market Finland", "Finland", "https://tyomarkkinatori.fi/en",
     "The official job site of the Finnish government."),
]

LOCAL_PORTALS = [
    ("StepStone", "Germany", "https://www.stepstone.de/", "One of Germany's largest job portals."),
    ("HeyJobs", "Germany", "https://www.heyjobs.co/", "Find jobs across Germany easily."),
    ("Jobware", "Germany", "https://www.jobware.de/", "Great for professional job opportunities."),
    ("Nationale Vacaturebank", "Netherlands", "https://www.nationalevacaturebank.nl/",
     "The official job board of the Netherlands."),
    ("Jobat", "Belgium", "https://www.jobat.be/", "Belgium's leading job search platform."),
    ("Karriere.at", "Austria", "https://www.karriere.at", "Austria's popular job portal."),
    ("Jobindex", "Denmark", "https://www.jobindex.dk/", "Denmark's most used job search site."),
    ("Jobbsafari", "Sweden", "https://www.jobbsafari.se/", "Find jobs across Sweden faster."),
    ("Finn.no", "Norway", "https://www.finn.no/job", "Norway's biggest marketplace for jobs."),
    ("Duunitori", "Finland", "https://duunitori.fi/", "Finland's leading job search platform."),
]

RECRUITER_DBS = [
    ("Apollo", "https://www.apollo.io/", "Find recruiter emails and direct contacts."),
    ("RocketReach", "https://rocketreach.co/", "Look up recruiter contact details."),
    ("Hunter", "https://hunter.io/", "Find and verify professional email addresses."),
    ("SignalHire", "https://www.signalhire.com/", "Contact finder for recruiters and hiring managers."),
    ("LinkedIn Sales Navigator", "https://business.linkedin.com/sales-solutions/sales-navigator",
     "Advanced search to find recruiters by role, company or location."),
]

# Screenshot 2026-08-30: global staffing groups with LINK + Contact columns
GLOBAL_STAFFING = [
    ("ManpowerGroup", "https://www.manpowergroup.com/en"),
    ("Randstad", "https://www.randstad.com/"),
    ("Kelly Services", "https://www.kellyservices.com/"),
    ("TeamLease Digital", "https://www.teamleasedigital.com/"),
    ("ABC Consultants", "https://www.abcconsultants.in/"),
]


def load_infographics():
    n = 0
    for name, country, url, note in GOV_PORTALS:
        REG.add("portal", name, country=country, website=url, career_url=url,
                note=note, specialization="Government Job Portal",
                source="infographic_gov_portals",
                tags=["government", "official"], priority=3)
        n += 1
    for name, country, url, note in LOCAL_PORTALS:
        REG.add("portal", name, country=country, website=url, career_url=url,
                note=note, specialization="Local Job Board",
                source="infographic_local_portals", tags=["job-board"], priority=2)
        n += 1
    for name, url, note in RECRUITER_DBS:
        REG.add("portal", name, website=url, career_url=url, note=note,
                specialization="Recruiter Contact Database",
                source="infographic_recruiter_dbs",
                tags=["recruiter-database", "networking-tool"], priority=3)
        n += 1
    for name, url in GLOBAL_STAFFING:
        REG.add("agency", name, website=url, career_url=url,
                specialization="Global Staffing Group",
                source="screenshot_staffing_groups",
                tags=["staffing-agency", "global"], priority=2)
        n += 1
    return n


# --------------------------------------------------------------------------- #
# main
# --------------------------------------------------------------------------- #

def main():
    n1 = load_sheet1()
    n2c, n2r = load_sheet2()
    n3 = load_sheet3()
    n4 = load_xlsx()
    n5 = load_txt_lists()
    n6 = load_infographics()

    records = list(REG.items.values())
    for i, rec in enumerate(records):
        rec["id"] = f"seed_{i:04d}"
        rec.setdefault("priority", 1)

    companies = [r for r in records if r["kind"] == "company"]
    agencies = [r for r in records if r["kind"] == "agency"]
    portals = [r for r in records if r["kind"] == "portal"]

    by_country = {}
    for r in companies:
        by_country[r["country"] or "Unknown"] = by_country.get(r["country"] or "Unknown", 0) + 1

    payload = {
        "generatedFrom": [
            "AIH App Master IT Jobs + Recuiters - Google Drive (sheets 1-3)",
            "Netherlands Hiring Companies.xlsx",
            "germany.txt", "netherlands.txt",
            "country wise companies.txt", "luxembourg.txt",
            "company career pages / recruiter databases / government / local portal infographics",
        ],
        "counts": {
            "companies": len(companies),
            "agencies": len(agencies),
            "portals": len(portals),
            "total": len(records),
        },
        "rowsReadPerSource": {
            "german_master_sheet": n1,
            "multi_country_sheet_companies": n2c,
            "multi_country_sheet_recruiters": n2r,
            "visa_sponsor_sheet": n3,
            "netherlands_xlsx": n4,
            "txt_shortlists": n5,
            "infographics": n6,
        },
        "companiesByCountry": dict(sorted(by_country.items(), key=lambda kv: -kv[1])),
        "records": records,
    }

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=False, indent=1)

    total_read = n1 + n2c + n2r + n3 + n4 + n5 + n6
    print(f"rows read from sources : {total_read}")
    print(f"unique records written : {len(records)}")
    print(f"  companies {len(companies)}   agencies {len(agencies)}   portals {len(portals)}")
    print("companies by country   :")
    for k, v in sorted(by_country.items(), key=lambda kv: -kv[1]):
        print(f"    {v:>4}  {k}")
    print(f"\nwrote {OUT}")


if __name__ == "__main__":
    main()
