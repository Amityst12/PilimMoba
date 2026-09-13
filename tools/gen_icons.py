#!/usr/bin/env python3
"""Generates clean, modern SVG icons for MOBA items, champions, and abilities."""

import os

BASE_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "icons")
ITEMS_DIR = os.path.join(BASE_DIR, "items")
CHAMPS_DIR = os.path.join(BASE_DIR, "champions")
ABILITIES_DIR = os.path.join(BASE_DIR, "abilities")


def write_svg(folder: str, name: str, svg_content: str) -> None:
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, f"{name}.svg")
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg_content.strip())


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


def gen_all():
    # --- Champion Portraits ---
    # Arcanist (Mage, Violet / Cyan mystical orb and runes)
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

    # Warden (Tank, Golden fortress shield and lion core)
    write_svg(CHAMPS_DIR, "warden", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#120e06" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#2b200b" stroke="#e0a93b" stroke-width="3" />
  <path d="M 40,14 L 62,22 L 62,45 C 62,58 40,68 40,68 C 40,68 18,58 18,45 L 18,22 Z" fill="#61430e" stroke="#ffc043" stroke-width="2.5" />
  <path d="M 40,24 L 54,30 L 54,44 C 54,52 40,59 40,59 C 40,59 26,52 26,44 L 26,30 Z" fill="#c48a1d" />
  <circle cx="40" cy="40" r="6" fill="#fff275" />
</svg>""")

    # Ranger (Marksman, Emerald swift bow and feather)
    write_svg(CHAMPS_DIR, "ranger", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#06140d" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#102e1c" stroke="#38b000" stroke-width="3" />
  <path d="M 22,58 C 28,34 50,22 58,22 C 58,30 46,52 22,58 Z" fill="#2d6a4f" stroke="#70e000" stroke-width="2" />
  <line x1="20" y1="60" x2="60" y2="20" stroke="#ccff33" stroke-width="3" stroke-linecap="round" />
  <polygon points="60,20 48,23 57,32" fill="#ffff3f" />
  <line x1="20" y1="60" x2="28" y2="58" stroke="#70e000" stroke-width="2" />
  <line x1="20" y1="60" x2="22" y2="52" stroke="#70e000" stroke-width="2" />
</svg>""")

    # Wraith (Assassin, Dark hood with glowing red eyes and dual blades)
    write_svg(CHAMPS_DIR, "wraith", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#0a0508" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#1c0a12" stroke="#e63946" stroke-width="3" />
  <path d="M 40,16 C 26,24 24,48 24,62 L 56,62 C 56,48 54,24 40,16 Z" fill="#2b0914" stroke="#ff4d6d" stroke-width="2" />
  <polygon points="32,38 38,40 33,42" fill="#ff0054" />
  <polygon points="48,38 42,40 47,42" fill="#ff0054" />
  <line x1="22" y1="64" x2="36" y2="48" stroke="#ff758f" stroke-width="3" stroke-linecap="round" />
  <line x1="58" y1="64" x2="44" y2="48" stroke="#ff758f" stroke-width="3" stroke-linecap="round" />
</svg>""")

    # Luminary (Support, Radiant golden sunburst halo)
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

    # --- Recall & Spell Icons ---
    write_svg(ABILITIES_DIR, "recall", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <rect width="64" height="64" rx="10" fill="#051923" stroke="#00a6fb" stroke-width="2" />
  <circle cx="32" cy="32" r="18" fill="none" stroke="#0582ca" stroke-width="3" stroke-dasharray="8 4" />
  <polygon points="32,18 42,34 22,34" fill="#00a6fb" />
  <circle cx="32" cy="40" r="4" fill="#b1e5fb" />
</svg>""")

    print(f"Generated all icons into {BASE_DIR}")


if __name__ == "__main__":
    gen_all()
