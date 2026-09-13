#!/usr/bin/env python3
"""Generates clean, modern, high-quality SVG icons for MOBA abilities, items, champions, stats, and brand assets."""

import os

BASE_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "icons")
ITEMS_DIR = os.path.join(BASE_DIR, "items")
CHAMPS_DIR = os.path.join(BASE_DIR, "champions")
ABILITIES_DIR = os.path.join(BASE_DIR, "abilities")
STATS_DIR = os.path.join(BASE_DIR, "stats")
UI_DIR = os.path.join(BASE_DIR, "ui")


def write_svg(folder: str, name: str, svg_content: str) -> None:
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, f"{name}.svg")
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg_content.strip())


def ability_svg(bg_dark: str, primary_color: str, accent_color: str, glyph_svg: str) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <defs>
    <radialGradient id="bg_glow_{primary_color.replace('#','')}" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="{primary_color}" stop-opacity="0.4" />
      <stop offset="85%" stop-color="{bg_dark}" stop-opacity="0.95" />
      <stop offset="100%" stop-color="#040608" stop-opacity="1.0" />
    </radialGradient>
    <linearGradient id="border_grad_{primary_color.replace('#','')}" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="{accent_color}" />
      <stop offset="60%" stop-color="{primary_color}" />
      <stop offset="100%" stop-color="#111822" />
    </linearGradient>
  </defs>
  <rect width="64" height="64" rx="8" fill="url(#bg_glow_{primary_color.replace('#','')})" />
  <rect x="2" y="2" width="60" height="60" rx="6" fill="none" stroke="url(#border_grad_{primary_color.replace('#','')})" stroke-width="2" />
  <path d="M 4,10 L 4,4 L 10,4" stroke="{accent_color}" stroke-width="1.5" fill="none" opacity="0.8" />
  <path d="M 60,10 L 60,4 L 54,4" stroke="{accent_color}" stroke-width="1.5" fill="none" opacity="0.8" />
  <path d="M 4,54 L 4,60 L 10,60" stroke="{accent_color}" stroke-width="1.5" fill="none" opacity="0.8" />
  <path d="M 60,54 L 60,60 L 54,60" stroke="{accent_color}" stroke-width="1.5" fill="none" opacity="0.8" />
  <g transform="translate(32,32)">
    {glyph_svg}
  </g>
</svg>"""


def item_svg(bg_color: str, border_color: str, symbol_svg: str) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <rect width="64" height="64" rx="10" fill="#0d1117" />
  <rect x="3" y="3" width="58" height="58" rx="8" fill="{bg_color}" stroke="{border_color}" stroke-width="2" />
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="{border_color}" stop-opacity="0.8" />
      <stop offset="100%" stop-color="{bg_color}" stop-opacity="0.4" />
    </linearGradient>
  </defs>
  <rect x="6" y="6" width="52" height="52" rx="6" fill="url(#grad)" opacity="0.35" />
  <g transform="translate(32,32)">
    {symbol_svg}
  </g>
</svg>"""


def stat_svg(stroke_col: str, fill_col: str, body_svg: str) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
  <rect width="32" height="32" rx="6" fill="#0a0d14" stroke="#1f2937" stroke-width="1.5" />
  <g transform="translate(16,16)">
    {body_svg}
  </g>
</svg>"""


def gen_all():
    # --- Champion Portraits ---
    write_svg(CHAMPS_DIR, "arcanist", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#0c071a" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#1f143d" stroke="#9d4edd" stroke-width="3" />
  <circle cx="40" cy="40" r="24" fill="#3a1c71" stroke="#c77dff" stroke-width="2" />
  <circle cx="40" cy="40" r="14" fill="#7b2cbf" />
  <circle cx="40" cy="40" r="7" fill="#e0aaff" />
  <polygon points="40,12 43,26 40,22 37,26" fill="#c77dff" />
  <polygon points="40,68 43,54 40,58 37,54" fill="#c77dff" />
  <polygon points="12,40 26,43 22,40 26,37" fill="#c77dff" />
  <polygon points="68,40 54,43 58,40 54,37" fill="#c77dff" />
</svg>""")

    write_svg(CHAMPS_DIR, "warden", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#120e06" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#2b200b" stroke="#e0a93b" stroke-width="3" />
  <path d="M 40,14 L 62,22 L 62,45 C 62,58 40,68 40,68 C 40,68 18,58 18,45 L 18,22 Z" fill="#61430e" stroke="#ffc043" stroke-width="2.5" />
  <path d="M 40,24 L 54,30 L 54,44 C 54,52 40,59 40,59 C 40,59 26,52 26,44 L 26,30 Z" fill="#c48a1d" />
  <circle cx="40" cy="40" r="6" fill="#fff275" />
</svg>""")

    write_svg(CHAMPS_DIR, "ranger", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#06140d" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#102e1c" stroke="#38b000" stroke-width="3" />
  <path d="M 22,58 C 28,34 50,22 58,22 C 58,30 46,52 22,58 Z" fill="#2d6a4f" stroke="#70e000" stroke-width="2" />
  <line x1="20" y1="60" x2="60" y2="20" stroke="#ccff33" stroke-width="3" stroke-linecap="round" />
  <polygon points="60,20 48,23 57,32" fill="#ffff3f" />
  <line x1="20" y1="60" x2="28" y2="58" stroke="#70e000" stroke-width="2" />
  <line x1="20" y1="60" x2="22" y2="52" stroke="#70e000" stroke-width="2" />
</svg>""")

    write_svg(CHAMPS_DIR, "wraith", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#0a0508" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#1c0a12" stroke="#e63946" stroke-width="3" />
  <path d="M 40,16 C 26,24 24,48 24,62 L 56,62 C 56,48 54,24 40,16 Z" fill="#2b0914" stroke="#ff4d6d" stroke-width="2" />
  <polygon points="32,38 38,40 33,42" fill="#ff0054" />
  <polygon points="48,38 42,40 47,42" fill="#ff0054" />
  <line x1="22" y1="64" x2="36" y2="48" stroke="#ff758f" stroke-width="3" stroke-linecap="round" />
  <line x1="58" y1="64" x2="44" y2="48" stroke="#ff758f" stroke-width="3" stroke-linecap="round" />
</svg>""")

    write_svg(CHAMPS_DIR, "luminary", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#140f04" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#2e210a" stroke="#ffb703" stroke-width="3" />
  <circle cx="40" cy="40" r="22" fill="none" stroke="#fb8500" stroke-width="3" stroke-dasharray="6 4" />
  <circle cx="40" cy="40" r="14" fill="#ffb703" />
  <circle cx="40" cy="40" r="7" fill="#fff3b0" />
  <polygon points="40,10 43,18 37,18" fill="#ffb703" />
  <polygon points="40,70 43,62 37,62" fill="#ffb703" />
  <polygon points="10,40 18,43 18,37" fill="#ffb703" />
  <polygon points="70,40 62,43 62,37" fill="#ffb703" />
</svg>""")

    # --- 25 Ability Icons ---

    # 1. Arcanist Abilities
    write_svg(ABILITIES_DIR, "arcanist_p", ability_svg("#1a0f30", "#9d4edd", "#00f5d4", """
      <circle cx="0" cy="0" r="6" fill="#00f5d4" stroke="#fff" stroke-width="1.5" />
      <circle cx="-13" cy="-8" r="3.5" fill="#c77dff" /><circle cx="14" cy="-5" r="3.5" fill="#c77dff" /><circle cx="-1" cy="14" r="3.5" fill="#9d4edd" />
      <ellipse cx="0" cy="0" rx="17" ry="10" fill="none" stroke="#7b2cbf" stroke-width="1.5" stroke-dasharray="4 3" transform="rotate(-25)" />
    """))

    write_svg(ABILITIES_DIR, "arcanist_q", ability_svg("#101533", "#00b4d8", "#c77dff", """
      <polygon points="0,-16 9,2 0,-1 -9,2" fill="#00f5d4" stroke="#c77dff" stroke-width="1.5" />
      <polygon points="0,-8 5,6 0,4 -5,6" fill="#fff" />
      <line x1="-7" y1="5" x2="-14" y2="18" stroke="#7b2cbf" stroke-width="2" stroke-linecap="round" />
      <line x1="7" y1="5" x2="14" y2="18" stroke="#7b2cbf" stroke-width="2" stroke-linecap="round" />
      <line x1="0" y1="8" x2="0" y2="20" stroke="#00f5d4" stroke-width="2.5" stroke-linecap="round" />
    """))

    write_svg(ABILITIES_DIR, "arcanist_w", ability_svg("#1c1136", "#7209b7", "#4cc9f0", """
      <ellipse cx="0" cy="0" rx="17" ry="8" fill="#1b143d" stroke="#c77dff" stroke-width="2" transform="rotate(-35)" />
      <ellipse cx="0" cy="0" rx="10" ry="4" fill="#7b2cbf" stroke="#00f5d4" stroke-width="1.5" transform="rotate(-35)" />
      <polygon points="-12,-11 -6,-17 0,-11" fill="#fff" opacity="0.9" />
      <polygon points="12,11 6,17 0,11" fill="#00f5d4" opacity="0.9" />
    """))

    write_svg(ABILITIES_DIR, "arcanist_e", ability_svg("#150b28", "#5a189a", "#c77dff", """
      <circle cx="0" cy="0" r="5" fill="#0c071a" stroke="#00f5d4" stroke-width="2" />
      <path d="M-15,0 C-15,-9 0,-16 12,-12 C18,-9 16,5 8,12 C0,17 -14,12 -12,2" fill="none" stroke="#9d4edd" stroke-width="2.5" stroke-linecap="round" />
      <circle cx="-10" cy="-7" r="2.5" fill="#c77dff" /><circle cx="11" cy="6" r="2.5" fill="#fff" />
    """))

    write_svg(ABILITIES_DIR, "arcanist_r", ability_svg("#0f1b3b", "#00f5d4", "#f72585", """
      <rect x="-6" y="-20" width="12" height="40" rx="4" fill="#00f5d4" stroke="#fff" stroke-width="2" />
      <ellipse cx="0" cy="-6" rx="15" ry="5" fill="none" stroke="#c77dff" stroke-width="2" />
      <ellipse cx="0" cy="8" rx="19" ry="6" fill="none" stroke="#9d4edd" stroke-width="2" />
      <line x1="-18" y1="-18" x2="18" y2="-18" stroke="#fff" stroke-width="2.5" />
    """))

    # 2. Warden Abilities
    write_svg(ABILITIES_DIR, "warden_p", ability_svg("#211707", "#d48b11", "#ffd166", """
      <path d="M-14,-14 L14,-14 L18,8 C18,16 0,20 0,20 C0,20 -18,16 -18,8 Z" fill="#61430e" stroke="#ffc043" stroke-width="2" />
      <line x1="-12" y1="-3" x2="12" y2="-3" stroke="#e0a93b" stroke-width="2" />
      <circle cx="0" cy="-8" r="2.5" fill="#fff275" /><circle cx="0" cy="5" r="2.5" fill="#fff275" />
    """))

    write_svg(ABILITIES_DIR, "warden_q", ability_svg("#261a05", "#e0a93b", "#ffffff", """
      <path d="M-10,-15 L10,-11 L6,14 C6,18 -4,18 -10,13 Z" fill="#8c5a14" stroke="#ffd166" stroke-width="2" />
      <polygon points="4,-4 14,-2 6,4" fill="#ffe066" />
      <path d="M12,-16 C18,-8 18,8 12,16" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" />
      <path d="M17,-12 C22,-5 22,5 17,12" fill="none" stroke="#ffb703" stroke-width="2" stroke-linecap="round" />
    """))

    write_svg(ABILITIES_DIR, "warden_w", ability_svg("#1a1506", "#f4a261", "#ffe6a7", """
      <polygon points="0,-16 15,-7 15,10 0,19 -15,10 -15,-7" fill="#422906" stroke="#ffd166" stroke-width="2" />
      <polygon points="0,-10 9,-4 9,6 0,12 -9,6 -9,-4" fill="#a4711b" stroke="#fff" stroke-width="1.5" />
    """))

    write_svg(ABILITIES_DIR, "warden_e", ability_svg("#2b1a08", "#c87d1a", "#ffd166", """
      <polygon points="-5,-18 5,-18 8,-10 -8,-10" fill="#e0a93b" stroke="#fff" stroke-width="1.5" />
      <rect x="-2.5" y="-10" width="5" height="13" fill="#61430e" />
      <path d="M0,5 L-13,18 M0,5 L-4,19 M0,5 L7,17 M0,5 L14,18" stroke="#ffb703" stroke-width="2.5" stroke-linecap="round" />
    """))

    write_svg(ABILITIES_DIR, "warden_r", ability_svg("#2e1c03", "#e0a93b", "#fff275", """
      <circle cx="0" cy="-2" r="9" fill="#784e10" stroke="#ffd166" stroke-width="2" />
      <polygon points="-6,-6 -3,-12 0,-7 3,-12 6,-6" fill="#ffe066" />
      <path d="M-13,-12 C-19,-2 -19,8 -13,16" fill="none" stroke="#ffd166" stroke-width="2" />
      <path d="M13,-12 C19,-2 19,8 13,16" fill="none" stroke="#ffd166" stroke-width="2" />
      <path d="M-18,-15 C-25,-3 -25,12 -18,20" fill="none" stroke="#fff" stroke-width="2.5" />
      <path d="M18,-15 C25,-3 25,12 18,20" fill="none" stroke="#fff" stroke-width="2.5" />
    """))

    # 3. Ranger Abilities
    write_svg(ABILITIES_DIR, "ranger_p", ability_svg("#0c2317", "#38b000", "#ccff33", """
      <path d="M-10,14 C-8,4 4,-8 14,-14 C12,-2 0,10 -10,14 Z" fill="#2d6a4f" stroke="#70e000" stroke-width="2" />
      <line x1="-12" y1="16" x2="16" y2="-16" stroke="#ccff33" stroke-width="2" stroke-linecap="round" />
      <path d="M-16,8 C-10,4 -6,0 -4,-8" fill="none" stroke="#9ef01a" stroke-width="1.5" stroke-linecap="round" />
    """))

    write_svg(ABILITIES_DIR, "ranger_q", ability_svg("#092817", "#70e000", "#ffff3f", """
      <polygon points="0,-18 12,10 0,4 -12,10" fill="#38b000" stroke="#ccff33" stroke-width="2" />
      <polygon points="0,-12 6,4 0,1 -6,4" fill="#ffff3f" />
      <line x1="0" y1="4" x2="0" y2="19" stroke="#70e000" stroke-width="2.5" stroke-linecap="round" />
    """))

    write_svg(ABILITIES_DIR, "ranger_w", ability_svg("#082115", "#2d6a4f", "#70e000", """
      <path d="M-14,0 C-14,-12 2,-16 12,-8" fill="none" stroke="#70e000" stroke-width="3" stroke-linecap="round" />
      <polygon points="14,-8 11,-15 6,-7" fill="#ccff33" />
      <path d="M14,0 C14,12 -2,16 -12,8" fill="none" stroke="#38b000" stroke-width="3" stroke-linecap="round" />
      <polygon points="-14,8 -11,15 -6,7" fill="#ffff3f" />
    """))

    write_svg(ABILITIES_DIR, "ranger_e", ability_svg("#112415", "#38b000", "#ffd166", """
      <polygon points="0,-15 15,10 -15,10" fill="#143623" stroke="#70e000" stroke-width="2" />
      <polygon points="0,-8 8,6 -8,6" fill="#2d6a4f" stroke="#ccff33" stroke-width="1.5" />
      <circle cx="0" cy="0" r="3" fill="#ffff3f" />
    """))

    write_svg(ABILITIES_DIR, "ranger_r", ability_svg("#082619", "#70e000", "#ffffff", """
      <line x1="-16" y1="14" x2="-8" y2="-16" stroke="#70e000" stroke-width="2" stroke-linecap="round" />
      <polygon points="-8,-16 -12,-11 -5,-12" fill="#ccff33" />
      <line x1="0" y1="16" x2="0" y2="-18" stroke="#ffff3f" stroke-width="2.5" stroke-linecap="round" />
      <polygon points="0,-18 -4,-12 4,-12" fill="#fff" />
      <line x1="16" y1="14" x2="8" y2="-16" stroke="#70e000" stroke-width="2" stroke-linecap="round" />
      <polygon points="8,-16 5,-12 12,-11" fill="#ccff33" />
    """))

    # 4. Wraith Abilities
    write_svg(ABILITIES_DIR, "wraith_p", ability_svg("#210712", "#e63946", "#ff758f", """
      <path d="M0,-14 C-12,-8 -12,8 0,16 C12,8 12,-8 0,-14 Z" fill="#1c0a12" stroke="#ff4d6d" stroke-width="2" />
      <line x1="-7" y1="-2" x2="-2" y2="0" stroke="#ff0054" stroke-width="2.5" stroke-linecap="round" />
      <line x1="7" y1="-2" x2="2" y2="0" stroke="#ff0054" stroke-width="2.5" stroke-linecap="round" />
    """))

    write_svg(ABILITIES_DIR, "wraith_q", ability_svg("#260815", "#ff0054", "#ffb3c6", """
      <line x1="-14" y1="-14" x2="14" y2="14" stroke="#ff4d6d" stroke-width="3" stroke-linecap="round" />
      <polygon points="14,14 6,14 14,6" fill="#ff0054" />
      <line x1="14" y1="-14" x2="-14" y2="14" stroke="#e63946" stroke-width="3" stroke-linecap="round" />
      <polygon points="-14,14 -6,14 -14,6" fill="#ff0054" />
    """))

    write_svg(ABILITIES_DIR, "wraith_w", ability_svg("#1a050e", "#7209b7", "#f72585", """
      <circle cx="-6" cy="-4" r="8" fill="#2b0914" opacity="0.8" />
      <circle cx="6" cy="-4" r="9" fill="#1c0a12" opacity="0.9" />
      <circle cx="0" cy="5" r="10" fill="#380e1e" opacity="0.85" />
      <path d="M-15,10 C-6,6 6,14 15,8" fill="none" stroke="#ff4d6d" stroke-width="2" stroke-linecap="round" />
    """))

    write_svg(ABILITIES_DIR, "wraith_e", ability_svg("#240713", "#ff4d6d", "#70e000", """
      <polygon points="0,-16 6,-2 2,12 -2,12 -6,-2" fill="#e63946" stroke="#ff758f" stroke-width="1.5" />
      <circle cx="0" cy="16" r="2.5" fill="#38b000" />
      <circle cx="2" cy="19" r="1.5" fill="#70e000" />
    """))

    write_svg(ABILITIES_DIR, "wraith_r", ability_svg("#330514", "#ff0054", "#ffffff", """
      <path d="M-14,-14 C-6,-18 4,-12 14,-6 L10,6 C4,2 -4,-4 -14,-14 Z" fill="#ff0054" />
      <path d="M14,-14 C6,-18 -4,-12 -14,-6 L-10,6 C-4,2 4,-4 14,-14 Z" fill="#ff0054" />
      <circle cx="0" cy="2" r="6" fill="#fff" stroke="#ff0054" stroke-width="1.5" />
      <circle cx="-2" cy="1" r="1.5" fill="#1c0a12" /><circle cx="2" cy="1" r="1.5" fill="#1c0a12" />
    """))

    # 5. Luminary Abilities
    write_svg(ABILITIES_DIR, "luminary_p", ability_svg("#261a04", "#ffb703", "#fff3b0", """
      <circle cx="0" cy="0" r="11" fill="none" stroke="#ffb703" stroke-width="2.5" />
      <circle cx="0" cy="0" r="5" fill="#fff3b0" />
      <line x1="0" y1="-17" x2="0" y2="-12" stroke="#fb8500" stroke-width="2" stroke-linecap="round" />
      <line x1="0" y1="17" x2="0" y2="12" stroke="#fb8500" stroke-width="2" stroke-linecap="round" />
      <line x1="-17" y1="0" x2="-12" y2="0" stroke="#fb8500" stroke-width="2" stroke-linecap="round" />
      <line x1="17" y1="0" x2="12" y2="0" stroke="#fb8500" stroke-width="2" stroke-linecap="round" />
    """))

    write_svg(ABILITIES_DIR, "luminary_q", ability_svg("#241703", "#fb8500", "#ffffff", """
      <polygon points="0,-18 5,-2 14,0 5,2 0,18 -5,2 -14,0 -5,-2" fill="#fff3b0" stroke="#fb8500" stroke-width="1.5" />
      <circle cx="0" cy="0" r="4" fill="#ffb703" />
    """))

    write_svg(ABILITIES_DIR, "luminary_w", ability_svg("#2b1c03", "#ffb703", "#ffd166", """
      <circle cx="0" cy="0" r="10" fill="#4d3002" stroke="#ffb703" stroke-width="2" />
      <path d="M-10,0 C-18,-10 -14,-16 0,-12 C14,-16 18,-10 10,0" fill="none" stroke="#ffd166" stroke-width="2" />
      <circle cx="0" cy="0" r="4" fill="#fff" />
    """))

    write_svg(ABILITIES_DIR, "luminary_e", ability_svg("#211402", "#f4a261", "#fff", """
      <polygon points="0,-14 13,-4 8,13 -8,13 -13,-4" fill="none" stroke="#ffb703" stroke-width="1.5" stroke-dasharray="3 2" />
      <circle cx="0" cy="-14" r="2.5" fill="#fff" /><circle cx="13" cy="-4" r="2.5" fill="#fff" /><circle cx="8" cy="13" r="2.5" fill="#fff" /><circle cx="-8" cy="13" r="2.5" fill="#fff" /><circle cx="-13" cy="-4" r="2.5" fill="#fff" />
    """))

    write_svg(ABILITIES_DIR, "luminary_r", ability_svg("#332103", "#ffb703", "#ffffff", """
      <circle cx="0" cy="0" r="8" fill="#fff" stroke="#ffb703" stroke-width="2" />
      <circle cx="0" cy="0" r="15" fill="none" stroke="#fb8500" stroke-width="2" stroke-dasharray="5 3" />
      <polygon points="0,-19 3,-10 -3,-10" fill="#ffd166" />
      <polygon points="0,19 3,10 -3,10" fill="#ffd166" />
      <polygon points="-19,0 -10,3 -10,-3" fill="#ffd166" />
      <polygon points="19,0 10,3 10,-3" fill="#ffd166" />
    """))

    # --- 14 Items ---
    items_def = {
        "long_sword": ("#2b1b17", "#ff7b54", '<path d="M-12,12 L10,-10 M10,-10 L16,-16 L14,-8 L8,-14 Z M-12,12 L-16,16" stroke="#ffb26b" stroke-width="3" stroke-linecap="round" /><line x1="-15" y1="9" x2="-9" y2="15" stroke="#ffd56b" stroke-width="3" stroke-linecap="round" />'),
        "amp_tome": ("#19152b", "#a06cd5", '<rect x="-14" y="-18" width="28" height="36" rx="3" fill="#6247aa" stroke="#e2afff" stroke-width="2" /><line x1="-8" y1="-8" x2="8" y2="-8" stroke="#fff" stroke-width="2" /><line x1="-8" y1="0" x2="8" y2="0" stroke="#fff" stroke-width="2" /><line x1="-8" y1="8" x2="4" y2="8" stroke="#fff" stroke-width="2" />'),
        "ruby_crystal": ("#330c14", "#ff4d6d", '<polygon points="0,-18 16,-6 10,18 -10,18 -16,-6" fill="#c9184a" stroke="#ff758f" stroke-width="2.5" /><polygon points="0,-12 10,-3 6,12 -6,12 -10,-3" fill="#ff4d6d" />'),
        "sapphire_crystal": ("#0b2239", "#00b4d8", '<polygon points="0,-18 16,-6 10,18 -10,18 -16,-6" fill="#0077b6" stroke="#90e0ef" stroke-width="2.5" /><polygon points="0,-12 10,-3 6,12 -6,12 -10,-3" fill="#00b4d8" />'),
        "dagger": ("#1c2127", "#8ecae6", '<polygon points="0,-18 5,-8 3,10 -3,10 -5,-8" fill="#caf0f8" stroke="#0077b6" stroke-width="1.5" /><rect x="-2" y="10" width="4" height="7" fill="#4a5568" /><line x1="-6" y1="10" x2="6" y2="10" stroke="#ffd166" stroke-width="2" />'),
        "cloth_armor": ("#261c14", "#ddb892", '<path d="M-14,-14 L14,-14 L18,10 C 18,16 0,20 0,20 C 0,20 -18,16 -18,10 Z" fill="#7f5539" stroke="#ede0d4" stroke-width="2" /><line x1="-10" y1="-4" x2="10" y2="-4" stroke="#b08968" stroke-width="2" />'),
        "null_mantle": ("#1b172a", "#9b5de5", '<path d="M-16,-12 C-8,-16 8,-16 16,-12 L18,16 L-18,16 Z" fill="#5c3d75" stroke="#f15bb5" stroke-width="2" /><circle cx="0" cy="-6" r="4" fill="#00f5d4" />'),
        "boots": ("#1f1811", "#cb997e", '<path d="M-8,-16 L2,-16 L4,2 L14,8 L14,16 L-10,16 L-10,-10 Z" fill="#6b4423" stroke="#ddbea9" stroke-width="2" /><line x1="-6" y1="-8" x2="2" y2="-8" stroke="#ffe8d6" stroke-width="2" />'),
        "blade_of_ruin": ("#2e0c18", "#f72585", '<path d="M-12,12 L8,-8 M8,-8 L16,-16 L12,-6 L6,-12 Z" stroke="#f72585" stroke-width="4" stroke-linecap="round" /><line x1="-15" y1="9" x2="-9" y2="15" stroke="#7209b7" stroke-width="3" stroke-linecap="round" /><circle cx="0" cy="0" r="3" fill="#4cc9f0" />'),
        "storm_bow": ("#0e2a38", "#48cae4", '<path d="M-14,14 C-4,-4 4,-10 14,-14" stroke="#00b4d8" stroke-width="3" fill="none" /><line x1="-14" y1="14" x2="14" y2="-14" stroke="#90e0ef" stroke-width="1.5" /><polygon points="4,-4 14,-14 6,-14" fill="#ffd166" />'),
        "archmage_staff": ("#221338", "#b5179e", '<line x1="-12" y1="14" x2="10" y2="-8" stroke="#7209b7" stroke-width="3.5" stroke-linecap="round" /><circle cx="12" cy="-10" r="7" fill="#f72585" stroke="#4895ef" stroke-width="2" />'),
        "crystal_heart": ("#10223b", "#00f5d4", '<path d="M0,16 C-18,2 -16,-14 0,-6 C16,-14 18,2 0,16 Z" fill="#00bbf9" stroke="#00f5d4" stroke-width="2" />'),
        "titan_plate": ("#262626", "#e5e5e5", '<path d="M-14,-14 L14,-14 L16,8 C 16,16 0,20 0,20 C 0,20 -16,16 -16,8 Z" fill="#404040" stroke="#fca311" stroke-width="2.5" /><polygon points="0,-8 8,0 0,8 -8,0" fill="#fca311" />'),
        "spirit_cloak": ("#08261e", "#52b788", '<path d="M-16,-12 C-6,-16 6,-16 16,-12 L16,16 C6,18 -6,18 -16,16 Z" fill="#2d6a4f" stroke="#95d5b2" stroke-width="2" /><circle cx="0" cy="0" r="5" fill="#d8f3dc" />'),
    }

    for item_id, (bg, border, sym) in items_def.items():
        write_svg(ITEMS_DIR, item_id, item_svg(bg, border, sym))

    # --- Recall Icon ---
    write_svg(ABILITIES_DIR, "recall", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <rect width="64" height="64" rx="10" fill="#051923" stroke="#00a6fb" stroke-width="2" />
  <circle cx="32" cy="32" r="18" fill="none" stroke="#0582ca" stroke-width="3" stroke-dasharray="8 4" />
  <polygon points="32,18 42,34 22,34" fill="#00a6fb" />
  <circle cx="32" cy="40" r="4" fill="#b1e5fb" />
</svg>""")

    # --- 6 Stat Icons ---
    write_svg(STATS_DIR, "ad", stat_svg("#ff7b54", "#ffb26b", """
      <path d="M-6,7 L5,-4 M5,-4 L10,-9 L8,-3 L3,-8 Z" stroke="#ff7b54" stroke-width="2.5" stroke-linecap="round"/>
      <line x1="-8" y1="5" x2="-4" y2="9" stroke="#ffd56b" stroke-width="2.5" stroke-linecap="round"/>
    """))

    write_svg(STATS_DIR, "ap", stat_svg("#9d4edd", "#c77dff", """
      <line x1="-6" y1="8" x2="4" y2="-2" stroke="#9d4edd" stroke-width="2.5" stroke-linecap="round"/>
      <circle cx="6" cy="-4" r="4.5" fill="#c77dff" stroke="#fff" stroke-width="1.2"/>
    """))

    write_svg(STATS_DIR, "armor", stat_svg("#ffd166", "#e0a93b", """
      <path d="M-7,-7 L7,-7 L9,2 C9,7 0,10 0,10 C0,10 -9,7 -9,2 Z" fill="#61430e" stroke="#ffd166" stroke-width="1.8"/>
    """))

    write_svg(STATS_DIR, "mr", stat_svg("#48cae4", "#00f5d4", """
      <path d="M-8,-6 C-3,-9 3,-9 8,-6 L7,7 L-7,7 Z" fill="#1b2a4a" stroke="#48cae4" stroke-width="1.8"/>
      <circle cx="0" cy="1" r="2.5" fill="#00f5d4"/>
    """))

    write_svg(STATS_DIR, "as", stat_svg("#ffd166", "#ff9f1c", """
      <polygon points="2,-9 -5,0 0,0 -2,9 6,-1 1,-1" fill="#ffd166" stroke="#ff9f1c" stroke-width="1.2"/>
    """))

    write_svg(STATS_DIR, "ms", stat_svg("#70e000", "#ccff33", """
      <path d="M-6,-6 L-1,-6 L0,4 L6,7 L6,9 L-7,9 L-7,1 Z" fill="#2d6a4f" stroke="#70e000" stroke-width="1.8"/>
      <path d="M1,0 C5,-2 8,1 7,4" fill="none" stroke="#ccff33" stroke-width="1.5"/>
    """))

    # --- Epic Game App Icon (icon.svg) & Main Menu Logo (logo.svg) ---
    app_icon_content = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
  <defs>
    <radialGradient id="bg" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#192438" />
      <stop offset="70%" stop-color="#090d14" />
      <stop offset="100%" stop-color="#030508" />
    </radialGradient>
    <linearGradient id="gold" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fff275" />
      <stop offset="40%" stop-color="#e0a93b" />
      <stop offset="100%" stop-color="#734907" />
    </linearGradient>
    <linearGradient id="blue_flame" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#00f5d4" />
      <stop offset="100%" stop-color="#0077b6" />
    </linearGradient>
  </defs>
  <!-- Base frame -->
  <rect width="128" height="128" rx="28" fill="url(#bg)" stroke="url(#gold)" stroke-width="4" />
  <!-- Crossed Runic Blades -->
  <line x1="26" y1="26" x2="102" y2="102" stroke="#64748b" stroke-width="6" stroke-linecap="round" />
  <line x1="102" y1="26" x2="26" y2="102" stroke="#64748b" stroke-width="6" stroke-linecap="round" />
  <!-- Central Shield Crest -->
  <path d="M 64,22 L 96,36 L 96,72 C 96,92 64,108 64,108 C 64,108 32,92 32,72 L 32,36 Z" fill="#0d1624" stroke="url(#gold)" stroke-width="4" />
  <path d="M 64,32 L 86,42 L 86,68 C 86,82 64,96 64,96 C 64,96 42,82 42,68 L 42,42 Z" fill="#16253d" stroke="#3b82f6" stroke-width="2" />
  <!-- Central Mystic Rift Eye -->
  <polygon points="64,46 78,64 64,82 50,64" fill="url(#blue_flame)" />
  <circle cx="64" cy="64" r="5" fill="#ffffff" />
  <!-- Gold Accents -->
  <polygon points="64,26 69,36 59,36" fill="url(#gold)" />
</svg>"""

    write_svg(os.path.join(os.path.dirname(__file__), ".."), "icon", app_icon_content)
    write_svg(UI_DIR, "logo", app_icon_content)

    print(f"Generated all 25 abilities, 14 items, 5 champions, 6 stats, and app icons into {BASE_DIR}")


if __name__ == "__main__":
    gen_all()
