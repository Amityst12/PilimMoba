#!/usr/bin/env python3
"""Generates SVG portraits and ability icons for the 7 champions:
Erez, Stephen, Amit, Nissim, Rogo, Yakir, Edgy.
"""

import os

BASE_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "icons")
CHAMPS_DIR = os.path.join(BASE_DIR, "champions")
ABILITIES_DIR = os.path.join(BASE_DIR, "abilities")

def write_svg(folder: str, name: str, svg_content: str) -> None:
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, f"{name}.svg")
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg_content.strip())

def ability_svg(bg_dark: str, primary_color: str, accent_color: str, glyph_svg: str) -> str:
    p_safe = primary_color.replace('#','')
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <defs>
    <radialGradient id="bg_glow_{p_safe}" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="{primary_color}" stop-opacity="0.4" />
      <stop offset="85%" stop-color="{bg_dark}" stop-opacity="0.95" />
      <stop offset="100%" stop-color="#040608" stop-opacity="1.0" />
    </radialGradient>
    <linearGradient id="border_grad_{p_safe}" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="{accent_color}" />
      <stop offset="60%" stop-color="{primary_color}" />
      <stop offset="100%" stop-color="#111822" />
    </linearGradient>
  </defs>
  <rect width="64" height="64" rx="8" fill="url(#bg_glow_{p_safe})" />
  <rect x="2" y="2" width="60" height="60" rx="6" fill="none" stroke="url(#border_grad_{p_safe})" stroke-width="2" />
  <path d="M 4,10 L 4,4 L 10,4" stroke="{accent_color}" stroke-width="1.5" fill="none" opacity="0.8" />
  <path d="M 60,10 L 60,4 L 54,4" stroke="{accent_color}" stroke-width="1.5" fill="none" opacity="0.8" />
  <path d="M 4,54 L 4,60 L 10,60" stroke="{accent_color}" stroke-width="1.5" fill="none" opacity="0.8" />
  <path d="M 60,54 L 60,60 L 54,60" stroke="{accent_color}" stroke-width="1.5" fill="none" opacity="0.8" />
  <g transform="translate(32,32)">
    {glyph_svg}
  </g>
</svg>"""

def gen():
    # --- 1. Erez ---
    write_svg(CHAMPS_DIR, "erez", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#0b172a" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#172b4d" stroke="#3b82f6" stroke-width="3" />
  <path d="M 40,16 L 60,26 L 60,48 C 60,60 40,68 40,68 C 40,68 20,60 20,48 L 20,26 Z" fill="#1e3a8a" stroke="#fbbf24" stroke-width="2.5" />
  <line x1="28" y1="28" x2="52" y2="52" stroke="#93c5fd" stroke-width="3" stroke-linecap="round" />
  <line x1="52" y1="28" x2="28" y2="52" stroke="#93c5fd" stroke-width="3" stroke-linecap="round" />
  <polygon points="40,32 44,42 36,42" fill="#f59e0b" />
</svg>""")
    write_svg(ABILITIES_DIR, "erez_p", ability_svg("#0f1f3d", "#3b82f6", "#fbbf24", """
      <path d="M-12,-12 L12,-12 L15,6 C15,14 0,18 0,18 C0,18 -15,14 -15,6 Z" fill="#1e3a8a" stroke="#fbbf24" stroke-width="2" />
      <polygon points="0,-8 3,0 -3,0" fill="#facc15" />
    """))
    write_svg(ABILITIES_DIR, "erez_q", ability_svg("#112447", "#60a5fa", "#ffffff", """
      <line x1="-14" y1="14" x2="14" y2="-14" stroke="#93c5fd" stroke-width="3.5" stroke-linecap="round" />
      <polygon points="14,-14 6,-14 14,-6" fill="#facc15" />
      <path d="M-8,-14 C4,-14 14,-4 14,8" fill="none" stroke="#60a5fa" stroke-width="2" stroke-linecap="round" />
    """))
    write_svg(ABILITIES_DIR, "erez_w", ability_svg("#0c1b33", "#2563eb", "#fbbf24", """
      <path d="M-14,-14 L14,-14 L16,8 C16,16 0,20 0,20 C0,20 -16,16 -16,8 Z" fill="#1d4ed8" stroke="#fbbf24" stroke-width="2" />
      <circle cx="0" cy="0" r="5" fill="#facc15" />
    """))
    write_svg(ABILITIES_DIR, "erez_e", ability_svg("#0d182b", "#3b82f6", "#93c5fd", """
      <ellipse cx="0" cy="4" rx="16" ry="7" fill="none" stroke="#60a5fa" stroke-width="2" />
      <ellipse cx="0" cy="4" rx="9" ry="4" fill="none" stroke="#93c5fd" stroke-width="1.5" />
      <line x1="0" y1="-14" x2="0" y2="4" stroke="#fbbf24" stroke-width="3" stroke-linecap="round" />
    """))
    write_svg(ABILITIES_DIR, "erez_r", ability_svg("#172554", "#fbbf24", "#ffffff", """
      <polygon points="0,-18 7,-4 16,-2 8,6 10,16 0,9 -10,16 -8,6 -16,-2 -7,-4" fill="#fbbf24" stroke="#fff" stroke-width="1.5" />
      <circle cx="0" cy="0" r="4" fill="#ffffff" />
    """))

    # --- 2. Stephen ---
    write_svg(CHAMPS_DIR, "stephen", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#100720" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#241242" stroke="#a855f7" stroke-width="3" />
  <ellipse cx="40" cy="40" rx="20" ry="12" fill="#3b0764" stroke="#c084fc" stroke-width="2" />
  <circle cx="40" cy="40" r="7" fill="#06b6d4" />
  <circle cx="40" cy="40" r="3" fill="#ffffff" />
  <polygon points="40,14 43,24 40,21 37,24" fill="#a855f7" />
  <polygon points="40,66 43,56 40,59 37,56" fill="#a855f7" />
</svg>""")
    write_svg(ABILITIES_DIR, "stephen_p", ability_svg("#1a082b", "#a855f7", "#06b6d4", """
      <circle cx="0" cy="0" r="14" fill="none" stroke="#c084fc" stroke-width="2" stroke-dasharray="4 3" />
      <circle cx="0" cy="0" r="7" fill="#a855f7" stroke="#06b6d4" stroke-width="1.5" />
      <circle cx="0" cy="0" r="3" fill="#ffffff" />
    """))
    write_svg(ABILITIES_DIR, "stephen_q", ability_svg("#1f0b36", "#c084fc", "#06b6d4", """
      <polygon points="0,-16 8,2 0,-1 -8,2" fill="#06b6d4" stroke="#c084fc" stroke-width="1.5" />
      <line x1="0" y1="4" x2="0" y2="18" stroke="#a855f7" stroke-width="2.5" stroke-linecap="round" />
    """))
    write_svg(ABILITIES_DIR, "stephen_w", ability_svg("#17092c", "#7e22ce", "#38bdf8", """
      <ellipse cx="0" cy="0" rx="16" ry="8" fill="#3b0764" stroke="#c084fc" stroke-width="2" transform="rotate(-30)" />
      <circle cx="0" cy="0" r="4" fill="#06b6d4" />
    """))
    write_svg(ABILITIES_DIR, "stephen_e", ability_svg("#1c0936", "#9333ea", "#f43f5e", """
      <path d="M-14,0 C-14,-9 0,-15 11,-11 C17,-8 15,5 7,11 C0,16 -13,11 -11,1" fill="none" stroke="#a855f7" stroke-width="2.5" stroke-linecap="round" />
      <circle cx="0" cy="0" r="4" fill="#c084fc" />
    """))
    write_svg(ABILITIES_DIR, "stephen_r", ability_svg("#2a084d", "#06b6d4", "#f43f5e", """
      <rect x="-5" y="-18" width="10" height="36" rx="4" fill="#06b6d4" stroke="#ffffff" stroke-width="1.5" />
      <ellipse cx="0" cy="-4" rx="14" ry="5" fill="none" stroke="#c084fc" stroke-width="2" />
      <ellipse cx="0" cy="8" rx="17" ry="6" fill="none" stroke="#a855f7" stroke-width="2" />
    """))

    # --- 3. Amit ---
    write_svg(CHAMPS_DIR, "amit", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#0c131f" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#1e293b" stroke="#f59e0b" stroke-width="3" />
  <circle cx="40" cy="40" r="22" fill="none" stroke="#38bdf8" stroke-width="2" stroke-dasharray="5 3" />
  <line x1="40" y1="18" x2="40" y2="62" stroke="#f59e0b" stroke-width="2" />
  <line x1="18" y1="40" x2="62" y2="40" stroke="#f59e0b" stroke-width="2" />
  <circle cx="40" cy="40" r="6" fill="#f59e0b" stroke="#ffffff" stroke-width="1.5" />
</svg>""")
    write_svg(ABILITIES_DIR, "amit_p", ability_svg("#111827", "#f59e0b", "#38bdf8", """
      <circle cx="0" cy="0" r="14" fill="none" stroke="#f59e0b" stroke-width="2" />
      <line x1="0" y1="-18" x2="0" y2="18" stroke="#38bdf8" stroke-width="1.5" />
      <line x1="-18" y1="0" x2="18" y2="0" stroke="#38bdf8" stroke-width="1.5" />
      <circle cx="0" cy="0" r="3" fill="#ef4444" />
    """))
    write_svg(ABILITIES_DIR, "amit_q", ability_svg("#172033", "#38bdf8", "#f59e0b", """
      <line x1="-16" y1="16" x2="16" y2="-16" stroke="#f59e0b" stroke-width="3.5" stroke-linecap="round" />
      <polygon points="16,-16 8,-14 14,-8" fill="#38bdf8" />
      <line x1="-10" y1="10" x2="-4" y2="4" stroke="#ffffff" stroke-width="2" />
    """))
    write_svg(ABILITIES_DIR, "amit_w", ability_svg("#0f172a", "#10b981", "#38bdf8", """
      <path d="M-15,-8 C-5,-16 5,-4 15,-10" fill="none" stroke="#10b981" stroke-width="2.5" stroke-linecap="round" />
      <polygon points="15,-10 9,-8 13,-4" fill="#38bdf8" />
      <path d="M-15,8 C-5,0 5,12 15,6" fill="none" stroke="#34d399" stroke-width="1.5" stroke-linecap="round" />
    """))
    write_svg(ABILITIES_DIR, "amit_e", ability_svg("#1a1f2c", "#f59e0b", "#ef4444", """
      <circle cx="0" cy="0" r="8" fill="#1e293b" stroke="#f59e0b" stroke-width="2" />
      <line x1="-12" y1="-12" x2="12" y2="12" stroke="#ef4444" stroke-width="2.5" />
      <line x1="12" y1="-12" x2="-12" y2="12" stroke="#ef4444" stroke-width="2.5" />
    """))
    write_svg(ABILITIES_DIR, "amit_r", ability_svg("#1f1a14", "#f59e0b", "#ffffff", """
      <line x1="-12" y1="-16" x2="-4" y2="14" stroke="#f59e0b" stroke-width="2.5" />
      <line x1="0" y1="-18" x2="0" y2="16" stroke="#38bdf8" stroke-width="3" />
      <line x1="12" y1="-16" x2="4" y2="14" stroke="#f59e0b" stroke-width="2.5" />
      <polygon points="0,16 -3,8 3,8" fill="#fff" />
    """))

    # --- 4. Nissim ---
    write_svg(CHAMPS_DIR, "nissim", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#041f1e" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#0f443b" stroke="#10b981" stroke-width="3" />
  <circle cx="40" cy="40" r="20" fill="#064e3b" stroke="#34d399" stroke-width="2" />
  <path d="M 36,24 L 44,24 L 44,36 L 56,36 L 56,44 L 44,44 L 44,56 L 36,56 L 36,44 L 24,44 L 24,36 L 36,36 Z" fill="#facc15" />
  <circle cx="40" cy="40" r="4" fill="#ffffff" />
</svg>""")
    write_svg(ABILITIES_DIR, "nissim_p", ability_svg("#05221d", "#10b981", "#facc15", """
      <circle cx="0" cy="0" r="10" fill="none" stroke="#10b981" stroke-width="2.5" />
      <circle cx="0" cy="0" r="4" fill="#facc15" />
      <line x1="0" y1="-15" x2="0" y2="-11" stroke="#34d399" stroke-width="2" />
      <line x1="0" y1="15" x2="0" y2="11" stroke="#34d399" stroke-width="2" />
      <line x1="-15" y1="0" x2="-11" y2="0" stroke="#34d399" stroke-width="2" />
      <line x1="15" y1="0" x2="11" y2="0" stroke="#34d399" stroke-width="2" />
    """))
    write_svg(ABILITIES_DIR, "nissim_q", ability_svg("#072b25", "#34d399", "#ffffff", """
      <polygon points="0,-16 5,-2 14,0 5,2 0,16 -5,2 -14,0 -5,-2" fill="#facc15" stroke="#34d399" stroke-width="1.5" />
      <circle cx="0" cy="0" r="3.5" fill="#ffffff" />
    """))
    write_svg(ABILITIES_DIR, "nissim_w", ability_svg("#06241e", "#10b981", "#facc15", """
      <circle cx="0" cy="0" r="15" fill="#0f443b" stroke="#10b981" stroke-width="2" />
      <path d="M-4,-9 L4,-9 L4,-4 L9,-4 L9,4 L4,4 L4,9 L-4,9 L-4,4 L-9,4 L-9,-4 L-4,-4 Z" fill="#facc15" />
    """))
    write_svg(ABILITIES_DIR, "nissim_e", ability_svg("#092b23", "#059669", "#6ee7b7", """
      <circle cx="-6" cy="-4" r="5" fill="#10b981" /><circle cx="7" cy="-3" r="4" fill="#34d399" /><circle cx="0" cy="7" r="5" fill="#facc15" />
      <line x1="-6" y1="-4" x2="7" y2="-3" stroke="#fff" stroke-width="1.5" />
      <line x1="7" y1="-3" x2="0" y2="7" stroke="#fff" stroke-width="1.5" />
      <line x1="0" y1="7" x2="-6" y2="-4" stroke="#fff" stroke-width="1.5" />
    """))
    write_svg(ABILITIES_DIR, "nissim_r", ability_svg("#0a382e", "#facc15", "#ffffff", """
      <rect x="-6" y="-18" width="12" height="36" rx="4" fill="#facc15" stroke="#ffffff" stroke-width="2" />
      <circle cx="0" cy="0" r="8" fill="#10b981" opacity="0.8" />
      <line x1="-16" y1="0" x2="16" y2="0" stroke="#fff" stroke-width="2" />
    """))

    # --- 5. Rogo ---
    write_svg(CHAMPS_DIR, "rogo", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#200606" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#450a0a" stroke="#ef4444" stroke-width="3" />
  <path d="M 22,24 L 36,20 L 40,32 L 28,40 Z" fill="#b91c1c" stroke="#f87171" stroke-width="2" />
  <path d="M 58,24 L 44,20 L 40,32 L 52,40 Z" fill="#b91c1c" stroke="#f87171" stroke-width="2" />
  <line x1="26" y1="58" x2="54" y2="26" stroke="#f97316" stroke-width="3" stroke-linecap="round" />
  <polygon points="40,42 46,58 34,58" fill="#facc15" />
</svg>""")
    write_svg(ABILITIES_DIR, "rogo_p", ability_svg("#2a0808", "#ef4444", "#f97316", """
      <path d="M0,-14 C-10,-4 -10,8 0,16 C10,8 10,-4 0,-14 Z" fill="#dc2626" stroke="#f87171" stroke-width="2" />
      <circle cx="0" cy="6" r="3" fill="#facc15" />
    """))
    write_svg(ABILITIES_DIR, "rogo_q", ability_svg("#330a0a", "#f97316", "#ffffff", """
      <path d="M-14,-10 C-4,-16 8,-12 14,0 C8,-6 -4,-4 -14,-10 Z" fill="#ef4444" stroke="#f97316" stroke-width="2" />
      <line x1="-12" y1="12" x2="12" y2="-8" stroke="#ffffff" stroke-width="2.5" />
    """))
    write_svg(ABILITIES_DIR, "rogo_w", ability_svg("#2e0707", "#b91c1c", "#facc15", """
      <circle cx="0" cy="0" r="14" fill="none" stroke="#ef4444" stroke-width="2" />
      <circle cx="0" cy="0" r="8" fill="none" stroke="#f97316" stroke-width="2" />
      <polygon points="0,-6 6,4 -6,4" fill="#facc15" />
    """))
    write_svg(ABILITIES_DIR, "rogo_e", ability_svg("#280808", "#ea580c", "#fca5a5", """
      <line x1="-16" y1="10" x2="16" y2="10" stroke="#ef4444" stroke-width="3" />
      <line x1="-10" y1="10" x2="-6" y2="-8" stroke="#f97316" stroke-width="2" />
      <line x1="0" y1="10" x2="4" y2="-12" stroke="#f97316" stroke-width="2" />
      <line x1="10" y1="10" x2="8" y2="-6" stroke="#f97316" stroke-width="2" />
    """))
    write_svg(ABILITIES_DIR, "rogo_r", ability_svg("#3b0606", "#ef4444", "#facc15", """
      <polygon points="0,-16 12,-6 14,8 0,16 -14,8 -12,-6" fill="#b91c1c" stroke="#f97316" stroke-width="2" />
      <polygon points="0,-8 6,-2 6,4 0,8 -6,4 -6,-2" fill="#facc15" />
    """))

    # --- 6. Yakir ---
    write_svg(CHAMPS_DIR, "yakir", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#0b1320" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#1e293b" stroke="#38bdf8" stroke-width="3" />
  <path d="M 40,16 L 60,24 L 56,54 C 56,62 40,68 40,68 C 40,68 24,62 24,54 L 20,24 Z" fill="#334155" stroke="#7dd3fc" stroke-width="2.5" />
  <circle cx="40" cy="42" r="8" fill="#0284c7" stroke="#e0f2fe" stroke-width="2" />
  <line x1="40" y1="26" x2="40" y2="34" stroke="#e0f2fe" stroke-width="2.5" />
  <line x1="40" y1="50" x2="40" y2="58" stroke="#e0f2fe" stroke-width="2.5" />
</svg>""")
    write_svg(ABILITIES_DIR, "yakir_p", ability_svg("#0f172a", "#38bdf8", "#94a3b8", """
      <polygon points="0,-15 13,-6 13,8 0,16 -13,8 -13,-6" fill="#1e293b" stroke="#38bdf8" stroke-width="2" />
      <circle cx="0" cy="0" r="4" fill="#7dd3fc" />
    """))
    write_svg(ABILITIES_DIR, "yakir_q", ability_svg("#131e33", "#0284c7", "#ffffff", """
      <path d="M-8,-14 L8,-14 L12,8 C12,14 0,18 0,18 C0,18 -12,14 -12,8 Z" fill="#0369a1" stroke="#38bdf8" stroke-width="2" />
      <path d="M8,-16 C15,-8 15,8 8,16" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" />
    """))
    write_svg(ABILITIES_DIR, "yakir_w", ability_svg("#0d1b2e", "#0ea5e9", "#7dd3fc", """
      <rect x="-14" y="-12" width="28" height="24" rx="4" fill="#1e293b" stroke="#38bdf8" stroke-width="2" />
      <line x1="-10" y1="0" x2="10" y2="0" stroke="#7dd3fc" stroke-width="2" />
      <line x1="0" y1="-8" x2="0" y2="8" stroke="#7dd3fc" stroke-width="2" />
    """))
    write_svg(ABILITIES_DIR, "yakir_e", ability_svg("#111e30", "#38bdf8", "#e0f2fe", """
      <circle cx="0" cy="0" r="14" fill="none" stroke="#0ea5e9" stroke-width="2" stroke-dasharray="6 3" />
      <rect x="-4" y="-10" width="8" height="20" rx="2" fill="#38bdf8" stroke="#fff" stroke-width="1.5" />
    """))
    write_svg(ABILITIES_DIR, "yakir_r", ability_svg("#152438", "#38bdf8", "#facc15", """
      <polygon points="0,-18 16,-8 16,10 0,18 -16,10 -16,-8" fill="#0369a1" stroke="#facc15" stroke-width="2.5" />
      <polygon points="0,-10 9,-4 9,6 0,11 -9,6 -9,-4" fill="#38bdf8" stroke="#fff" stroke-width="1.5" />
    """))

    # --- 7. Edgy ---
    write_svg(CHAMPS_DIR, "edgy", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#080005" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#1f020f" stroke="#f43f5e" stroke-width="3" />
  <path d="M 40,16 C 26,22 22,46 22,60 L 58,60 C 58,46 54,22 40,16 Z" fill="#3f071b" stroke="#fb7185" stroke-width="2" />
  <polygon points="30,36 38,38 32,41" fill="#ff0055" />
  <polygon points="50,36 42,38 48,41" fill="#ff0055" />
  <line x1="20" y1="62" x2="36" y2="48" stroke="#ff0055" stroke-width="2.5" stroke-linecap="round" />
  <line x1="60" y1="62" x2="44" y2="48" stroke="#ff0055" stroke-width="2.5" stroke-linecap="round" />
</svg>""")
    write_svg(ABILITIES_DIR, "edgy_p", ability_svg("#1f030d", "#f43f5e", "#ff0055", """
      <path d="M0,-14 C-10,-8 -10,8 0,16 C10,8 10,-8 0,-14 Z" fill="#3f071b" stroke="#f43f5e" stroke-width="2" />
      <polygon points="-6,-2 -2,0 -4,2" fill="#ff0055" /><polygon points="6,-2 2,0 4,2" fill="#ff0055" />
    """))
    write_svg(ABILITIES_DIR, "edgy_q", ability_svg("#260410", "#ff0055", "#ffffff", """
      <line x1="-15" y1="-15" x2="15" y2="15" stroke="#f43f5e" stroke-width="3.5" stroke-linecap="round" />
      <polygon points="15,15 7,15 15,7" fill="#ff0055" />
      <line x1="15" y1="-15" x2="-15" y2="15" stroke="#fb7185" stroke-width="3.5" stroke-linecap="round" />
      <polygon points="-15,15 -7,15 -15,7" fill="#ff0055" />
    """))
    write_svg(ABILITIES_DIR, "edgy_w", ability_svg("#1a020d", "#881337", "#f43f5e", """
      <circle cx="-6" cy="-4" r="8" fill="#3f071b" opacity="0.85" />
      <circle cx="6" cy="-4" r="9" fill="#1f020f" opacity="0.95" />
      <circle cx="0" cy="5" r="10" fill="#4c0519" opacity="0.9" />
      <path d="M-15,10 C-6,6 6,14 15,8" fill="none" stroke="#f43f5e" stroke-width="2" stroke-linecap="round" />
    """))
    write_svg(ABILITIES_DIR, "edgy_e", ability_svg("#21030e", "#f43f5e", "#22c55e", """
      <polygon points="0,-16 6,-2 2,12 -2,12 -6,-2" fill="#f43f5e" stroke="#fb7185" stroke-width="1.5" />
      <circle cx="0" cy="15" r="2.5" fill="#22c55e" />
    """))
    write_svg(ABILITIES_DIR, "edgy_r", ability_svg("#330014", "#ff0055", "#ffffff", """
      <line x1="-14" y1="-14" x2="14" y2="14" stroke="#ff0055" stroke-width="4" stroke-linecap="round" />
      <line x1="14" y1="-14" x2="-14" y2="14" stroke="#ff0055" stroke-width="4" stroke-linecap="round" />
      <circle cx="0" cy="0" r="5" fill="#ffffff" />
    """))

    print("Generated 7 portraits and 35 ability SVGs successfully!")

if __name__ == "__main__":
    gen()
