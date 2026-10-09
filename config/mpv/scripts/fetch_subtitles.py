#!/usr/bin/env python3
"""
Subtitle Fetcher Backend for mpv.
Queries Cinemeta and OpenSubtitles to auto-fetch English subtitles
for any media playing in mpv (including webtorrent / HTTP streams).
"""

import sys
import os
import re
import urllib.request
import urllib.parse
import json
from pathlib import Path

SUB_CACHE_DIR = Path.home() / ".cache" / "mpv_subs"
SUB_CACHE_DIR.mkdir(parents=True, exist_ok=True)

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

def clean_media_title(raw_title: str) -> tuple[str, str, int | None, int | None]:
    clean = raw_title
    clean = re.sub(r'^(?:https?|magnet):\S+', '', clean)
    clean = re.sub(r'\.(?:mkv|mp4|avi|webm|ts|mov|m4v)$', '', clean, flags=re.IGNORECASE)
    clean = re.sub(r'\[.*?\]|\(.*?\)', ' ', clean)
    clean = re.sub(r'[._\-+]', ' ', clean)

    tv_match = re.search(r'(?i)\b(?:s|season\s*)(\d+)\s*(?:e|ep|episode\s*)(\d+)\b', clean)
    if tv_match:
        season = int(tv_match.group(1))
        episode = int(tv_match.group(2))
        clean = re.sub(r'(?i)\b(?:s|season\s*)\d+\s*(?:e|ep|episode\s*)\d+\b.*$', '', clean)
        cat = "series"
    else:
        season, episode = None, None
        cat = "movie"
        year_match = re.search(r'\b(19\d\d|20\d\d)\b', clean)
        if year_match:
            clean = re.sub(r'\b(19\d\d|20\d\d)\b.*$', r'\1', clean)

    clean = re.sub(r'\s+', ' ', clean).strip()
    return clean, cat, season, episode

def fetch_subtitles(query_str: str, track_index: int = 0) -> str | None:
    clean_title, cat, season, episode = clean_media_title(query_str)
    if not clean_title:
        return None

    # 1. Query Cinemeta to resolve IMDb ID
    search_url = f"https://v3-cinemeta.strem.io/catalog/{cat}/top/search={urllib.parse.quote(clean_title)}.json"
    try:
        req = urllib.request.Request(search_url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=6) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            metas = data.get("metas", [])
            if not metas:
                alt_cat = "movie" if cat == "series" else "series"
                alt_url = f"https://v3-cinemeta.strem.io/catalog/{alt_cat}/top/search={urllib.parse.quote(clean_title)}.json"
                req_alt = urllib.request.Request(alt_url, headers=HEADERS)
                with urllib.request.urlopen(req_alt, timeout=6) as resp_alt:
                    alt_data = json.loads(resp_alt.read().decode("utf-8"))
                    metas = alt_data.get("metas", [])
                    if metas:
                        cat = alt_cat

            if not metas:
                return None

            imdb_id = metas[0]["id"]
            name = metas[0].get("name", clean_title)
    except Exception:
        return None

    # 2. Query OpenSubtitles v3 for subtitle tracks
    if cat == "series" and season is not None and episode is not None:
        sub_key = f"{imdb_id}:{season}:{episode}"
    else:
        sub_key = imdb_id

    sub_api_url = f"https://opensubtitles-v3.strem.io/subtitles/{cat}/{sub_key}.json"
    try:
        req_sub = urllib.request.Request(sub_api_url, headers=HEADERS)
        with urllib.request.urlopen(req_sub, timeout=6) as resp_sub:
            sub_data = json.loads(resp_sub.read().decode("utf-8"))
            all_subs = sub_data.get("subtitles", [])
            en_subs = [s for s in all_subs if s.get("lang") in ["eng", "en"]]
            if not en_subs:
                return None

            chosen_sub = en_subs[track_index % len(en_subs)]
            dl_url = chosen_sub.get("url")
            if not dl_url:
                return None

            dl_req = urllib.request.Request(dl_url, headers=HEADERS)
            with urllib.request.urlopen(dl_req, timeout=6) as dl_resp:
                content = dl_resp.read()

            safe_name = re.sub(r'[^a-zA-Z0-9_\-]', '_', name)
            out_file = SUB_CACHE_DIR / f"{safe_name}_{sub_key}_en_{track_index}.srt"
            with open(out_file, "wb") as f:
                f.write(content)

            return str(out_file.resolve())
    except Exception:
        return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)

    title_arg = sys.argv[1]
    idx_arg = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].isdigit() else 0

    sub_path = fetch_subtitles(title_arg, idx_arg)
    if sub_path and os.path.exists(sub_path):
        print(sub_path)
        sys.exit(0)
    else:
        sys.exit(1)
