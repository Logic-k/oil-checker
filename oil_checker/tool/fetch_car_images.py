#!/usr/bin/env python3
"""차종별 실사 이미지 수집 — Wikimedia Commons.

인기 국산·수입 모델에 대해 Commons API로 대표 사진 1장씩을 받아
assets/cars/real/<slug>.webp 로 저장하고, 매칭용 매핑 +
라이선스 크레딧을 assets/data/car_image_map.csv 로 쓴다.

실행: python3 tool/fetch_car_images.py   (oil_checker/ 에서)
"""
import csv
import io
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "cars" / "real"
MAP_CSV = ROOT / "assets" / "data" / "car_image_map.csv"
UA = {"User-Agent": "oil-checker-dev/1.0 (contact: github.com/Logic-k/oil-checker)"}

# pattern(한국어 모델명 prefix) → (Commons 검색어, 파일 slug)
# pattern은 car_image.dart의 _norm(소문자+특수문자 제거)과 같은 방식으로 정규화됨.
MANIFEST = {
    # 현대
    "그랜저": ("Hyundai Grandeur", "grandeur"),
    "아반떼": ("Hyundai Avante CN7", "avante"),
    "쏘나타": ("Hyundai Sonata DN8", "sonata"),
    "싼타페": ("Hyundai Santa Fe MX5", "santafe"),
    "투싼": ("Hyundai Tucson NX4", "tucson"),
    "팰리세이드": ("Hyundai Palisade", "palisade"),
    "코나": ("Hyundai Kona SX2", "kona"),
    "캐스퍼": ("Hyundai Casper", "casper"),
    "베뉴": ("Hyundai Venue", "venue"),
    "스타리아": ("Hyundai Staria", "staria"),
    "스타렉스": ("Hyundai Starex", "starex"),
    "포터": ("Hyundai Porter", "porter"),
    "아이오닉5": ("Hyundai Ioniq 5", "ioniq5"),
    "아이오닉6": ("Hyundai Ioniq 6", "ioniq6"),
    "아이오닉9": ("Hyundai Ioniq 9", "ioniq9"),
    "아이오닉": ("Hyundai Ioniq", "ioniq"),
    "벨로스터": ("Hyundai Veloster", "veloster"),
    "i30": ("Hyundai i30", "i30"),
    "엑센트": ("Hyundai Accent", "accent"),
    "베르나": ("Hyundai Verna", "verna"),
    "제네시스쿠페": ("Hyundai Genesis Coupe", "gencoupe"),
    "맥스크루즈": ("Hyundai Maxcruz", "maxcruz"),
    # 기아
    "k5": ("Kia K5 DL3", "k5"),
    "k8": ("Kia K8", "k8"),
    "k9": ("Kia K9", "k9"),
    "k3": ("Kia K3", "k3"),
    "모닝": ("Kia Morning", "morning"),
    "레이": ("Kia Ray", "ray"),
    "쏘렌토": ("Kia Sorento MQ4", "sorento"),
    "스포티지": ("Kia Sportage NQ5", "sportage"),
    "카니발": ("Kia Carnival KA4", "carnival"),
    "셀토스": ("Kia Seltos", "seltos"),
    "니로": ("Kia Niro SG2", "niro"),
    "스토닉": ("Kia Stonic", "stonic"),
    "모하비": ("Kia Mohave", "mohave"),
    "봉고": ("Kia Bongo", "bongo"),
    "ev3": ("Kia EV3", "ev3"),
    "ev6": ("Kia EV6", "ev6"),
    "ev9": ("Kia EV9", "ev9"),
    "프라이드": ("Kia Pride", "pride"),
    # 제네시스
    "g70": ("Genesis G70", "g70"),
    "g80": ("Genesis G80", "g80"),
    "g90": ("Genesis G90", "g90"),
    "gv60": ("Genesis GV60", "gv60"),
    "gv70": ("Genesis GV70", "gv70"),
    "gv80": ("Genesis GV80", "gv80"),
    # 제네시스 단독 패턴 제외 — G70/G80/G90 코드 패턴이 우선해야 함
    # KG(쌍용)
    "티볼리": ("SsangYong Tivoli", "tivoli"),
    "토레스": ("KG Torres", "torres"),
    "렉스턴스포츠": ("SsangYong Rexton Sports", "rextonsports"),
    "렉스턴": ("SsangYong Rexton", "rexton"),
    "코란도": ("SsangYong Korando", "korando"),
    "무쏘": ("KG Musso", "musso"),
    "액티언": ("KGM Actyon", "actyon"),
    # 르노코리아
    "그랑콜레오스": ("Renault Grand Koleos", "grandkoleos"),
    "아르카나": ("Renault Arkana", "arkana"),
    "xm3": ("Renault Samsung XM3", "xm3"),
    "qm6": ("Renault Samsung QM6", "qm6"),
    "sm6": ("Renault Samsung SM6", "sm6"),
    "sm5": ("Renault Samsung SM5", "sm5"),
    "qm5": ("Renault Samsung QM5", "qm5"),
    # 쉐보레
    "트랙스": ("Chevrolet Trax", "trax"),
    "트레일블레이저": ("Chevrolet TrailBlazer", "trailblazer"),
    "스파크": ("Chevrolet Spark", "spark"),
    "말리부": ("Chevrolet Malibu", "malibu"),
    "콜로라도": ("Chevrolet Colorado", "colorado"),
    # BMW
    "x5": ("BMW X5", "x5"),
    "x3": ("BMW X3", "x3"),
    "x1": ("BMW X1", "x1"),
    "x7": ("BMW X7", "x7"),
    "5시리즈": ("BMW 5 Series", "bmw5"),
    "3시리즈": ("BMW 3 Series", "bmw3"),
    "i4": ("BMW i4", "i4"),
    "ix": ("BMW iX", "ix"),
    # 벤츠
    "e클래스": ("Mercedes-Benz E-Class", "eclass"),
    "c클래스": ("Mercedes-Benz C-Class", "cclass"),
    "s클래스": ("Mercedes-Benz S-Class", "sclass"),
    "glc": ("Mercedes-Benz GLC", "glc"),
    "gle": ("Mercedes-Benz GLE", "gle"),
    "gls": ("Mercedes-Benz GLS", "gls"),
    "a클래스": ("Mercedes-Benz A-Class", "aclass"),
    # 아우디·폭스바겐·기타 수입
    "a6": ("Audi A6", "a6"),
    "a4": ("Audi A4", "a4"),
    "q5": ("Audi Q5", "q5"),
    "q7": ("Audi Q7", "q7"),
    "골프": ("Volkswagen Golf", "golf"),
    "티구안": ("Volkswagen Tiguan", "tiguan"),
    "모델3": ("Tesla Model 3", "model3"),
    "모델y": ("Tesla Model Y", "modely"),
    "model3": ("Tesla Model 3", "model3"),
    "modely": ("Tesla Model Y", "modely"),
    "xc60": ("Volvo XC60", "xc60"),
    "xc90": ("Volvo XC90", "xc90"),
    "xc40": ("Volvo XC40", "xc40"),
    "s90": ("Volvo S90", "s90"),
    "캠리": ("Toyota Camry", "camry"),
    "rav4": ("Toyota RAV4", "rav4"),
    "프리우스": ("Toyota Prius", "prius"),
    "어코드": ("Honda Accord", "accord"),
    "cr-v": ("Honda CR-V", "crv"),
    "쿠퍼": ("Mini Cooper", "minicooper"),
    "es": ("Lexus ES", "es"),
    "rx": ("Lexus RX", "rx"),
    "랭글러": ("Jeep Wrangler", "wrangler"),
    "포레스터": ("Subaru Forester", "forester"),
}

API = "https://commons.wikimedia.org/w/api.php"


def _get(url: str, binary: bool = False):
    """429/5xx 시 지수 백오프 재시도."""
    delay = 4.0
    for attempt in range(6):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read() if binary else json.loads(r.read())
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503) and attempt < 5:
                time.sleep(delay)
                delay *= 1.8
                continue
            raise
    return None


def commons_search(query: str) -> dict | None:
    params = {
        "action": "query",
        "generator": "search",
        "gsrsearch": f"filetype:bitmap {query}",
        "gsrnamespace": "6",
        "gsrlimit": "8",
        "prop": "imageinfo",
        "iiprop": "url|size|mime|extmetadata",
        "iiurlwidth": "800",
        "format": "json",
        "formatversion": "2",
    }
    data = _get(API + "?" + urllib.parse.urlencode(params)) or {}
    pages = data.get("query", {}).get("pages") or []
    for p in pages:
        info = (p.get("imageinfo") or [{}])[0]
        mime = info.get("mime", "")
        w = info.get("width", 0)
        h = info.get("height", 0)
        if mime not in ("image/jpeg", "image/png", "image/webp"):
            continue
        if w < 400 or h < 250:
            continue  # 아이콘/도면 제외
        meta = info.get("extmetadata", {})
        lic = re.sub(r"<[^>]+>", "", meta.get("LicenseShortName", {}).get("value", ""))
        if not any(k in lic.lower() for k in ("cc", "public domain", "attribution")):
            continue
        return {
            "title": p.get("title", ""),
            "thumb": info.get("thumburl") or info.get("url"),
            "license": lic.strip(),
            "artist": re.sub(
                r"<[^>]+>", "", meta.get("Artist", {}).get("value", "")
            ).strip()[:60],
        }
    return None


def norm(s: str) -> str:
    return re.sub(r"[^a-z0-9가-힣]", "", s.lower())


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    MAP_CSV.parent.mkdir(parents=True, exist_ok=True)
    rows = []
    ok = miss = 0
    done_patterns = set()
    if MAP_CSV.exists():  # 재실행 시 이미 저장된 패턴 건너뛰기
        for row in csv.DictReader(MAP_CSV.open(encoding="utf-8")):
            if (ROOT / row["file"]).exists():
                done_patterns.add(row["pattern"])
                rows.append(row)
    for pattern, (query, slug) in MANIFEST.items():
        if norm(pattern) in done_patterns:
            print(f"[SKIP] {pattern}")
            continue
        try:
            hit = commons_search(query)
        except Exception as e:  # noqa: BLE001
            print(f"[ERR] {pattern}: {e}")
            miss += 1
            continue
        if not hit:
            print(f"[MISS] {pattern} ({query})")
            miss += 1
            continue
        out = OUT_DIR / f"{slug}.webp"
        if not out.exists():
            try:
                raw = _get(hit["thumb"], binary=True)
                img = Image.open(io.BytesIO(raw)).convert("RGB")
                img.thumbnail((640, 640))
                img.save(out, "WEBP", quality=82)
            except Exception as e:  # noqa: BLE001
                print(f"[ERR-dl] {pattern}: {e}")
                miss += 1
                continue
        rows.append(
            {
                "pattern": norm(pattern),
                "file": f"assets/cars/real/{slug}.webp",
                "title": hit["title"],
                "license": hit["license"],
                "artist": hit["artist"],
            }
        )
        ok += 1
        print(f"[OK] {pattern} -> {slug}.webp ({hit['license']})")
        time.sleep(1.6)  # Commons API 예의 — 짧은 간격은 429 유발

    with MAP_CSV.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["pattern", "file", "title", "license", "artist"])
        for r in rows:
            w.writerow([r["pattern"], r["file"], r["title"], r["license"], r["artist"]])
    print(f"\ndone: {ok} saved, {miss} missed -> {MAP_CSV}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
