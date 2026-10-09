#!/usr/bin/env python3
"""
Custom RSS feed generator for Rawson Properties Zimbabwe (For Sale).
Compatible with Newsboat exec: feed source.
"""

import sys
import urllib.request
import xml.etree.ElementTree as ET
from bs4 import BeautifulSoup

URL = "https://www.rawsonproperties.co.zw/for-sale"

def fetch_feed():
    req = urllib.request.Request(
        URL,
        headers={
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        },
    )

    with urllib.request.urlopen(req, timeout=15) as resp:
        html = resp.read().decode("utf-8", errors="ignore")

    soup = BeautifulSoup(html, "html.parser")

    rss = ET.Element("rss", version="2.0")
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = "Rawson Properties Zimbabwe - For Sale"
    ET.SubElement(channel, "link").text = URL
    ET.SubElement(channel, "description").text = "Latest properties for sale from Rawson Properties Zimbabwe"

    seen_links = set()
    boxes = soup.select(".property-box-2")

    for box in boxes:
        link_tag = box.select_one("a.property-img") or box.find("a", href=True)
        if not link_tag or not link_tag.get("href"):
            continue

        link = link_tag["href"]
        if "/for-sale/properties/" not in link or link in seen_links:
            continue
        seen_links.add(link)

        # Title
        title_tag = box.select_one("h3.title")
        title = title_tag.get_text(strip=True) if title_tag else "Property Listing"

        # Price
        price_tag = box.select_one("p.price")
        price = price_tag.get_text(strip=True) if price_tag else ""

        # Location
        loc_tag = box.select_one("h5.location")
        location = loc_tag.get_text(strip=True) if loc_tag else ""

        # Subtitle
        sub_title_tag = box.select_one("h2.sub-title")
        sub_title = sub_title_tag.get_text(strip=True) if sub_title_tag else ""

        # Description / Snippet
        desc_tag = box.select_one(".description p")
        desc_text = desc_tag.get_text(strip=True) if desc_tag else ""

        # Image
        img_tag = box.find("img")
        img_src = img_tag.get("src", "") if img_tag else ""

        # Construct Feed Item Title
        title_parts = []
        if price:
            title_parts.append(f"[{price}]")
        title_parts.append(title)
        if location:
            title_parts.append(f"- {location}")
        feed_title = " ".join(title_parts)

        # Construct HTML description for Newsboat article reader
        content_html = []
        if img_src:
            content_html.append(f'<p><img src="{img_src}" alt="{title}" /></p>')
        if price:
            content_html.append(f"<p><strong>Price:</strong> {price}</p>")
        if location:
            content_html.append(f"<p><strong>Location:</strong> {location}</p>")
        if sub_title:
            content_html.append(f"<p><strong>Estate/Sub-title:</strong> {sub_title}</p>")
        if desc_text:
            content_html.append(f"<p><strong>Details:</strong><br/>{desc_text}</p>")
        content_html.append(f'<p><a href="{link}">Open Listing on Rawson Properties</a></p>')

        item = ET.SubElement(channel, "item")
        ET.SubElement(item, "title").text = feed_title
        ET.SubElement(item, "link").text = link
        ET.SubElement(item, "guid").text = link
        ET.SubElement(item, "description").text = "".join(content_html)

    return ET.tostring(rss, encoding="utf-8").decode("utf-8")

if __name__ == "__main__":
    try:
        xml_output = fetch_feed()
        sys.stdout.write(xml_output)
    except Exception as e:
        # Fallback empty feed to avoid crashing Newsboat on network failure
        sys.stderr.write(f"Error fetching Rawson feed: {e}\n")
        fallback = '<?xml version="1.0" encoding="utf-8"?><rss version="2.0"><channel><title>Rawson Properties Zimbabwe - For Sale</title><link>https://www.rawsonproperties.co.zw/for-sale</link><description>Unavailable</description></channel></rss>'
        sys.stdout.write(fallback)
