#!/usr/bin/env python3
"""Generates SVG portraits and ability icons for all 7 champions:
Erez, Stephen, Amit, Nissim, Rogo, Yakir, Lior (and Edgy as fallback).
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
    print(f"Wrote {path}")

def ability_svg(bg_dark: str, primary_color: str, accent_color: str, glyph_svg: str) -> str:
    p_safe = primary_color.replace('#','').replace(',','_').replace('(','_').replace(')','_')
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <defs>
    <radialGradient id="bg_glow_{p_safe}" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="{primary_color}" stop-opacity="0.45" />
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
    # =========================================================================
    # 1. EREZ - The Beast Vanguard (Melee Fighter with Animal Companions)
    # =========================================================================
    write_svg(CHAMPS_DIR, "erez", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#0b172a" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#172b4d" stroke="#3b82f6" stroke-width="3" />
  <!-- Shield with wolf paw & sword -->
  <path d="M 40,14 L 62,25 L 62,48 C 62,62 40,70 40,70 C 40,70 18,62 18,48 L 18,25 Z" fill="#1e3a8a" stroke="#fbbf24" stroke-width="2.5" />
  <line x1="28" y1="28" x2="52" y2="52" stroke="#93c5fd" stroke-width="3" stroke-linecap="round" />
  <!-- Beast Paw Silhouette -->
  <ellipse cx="40" cy="45" rx="7" ry="6" fill="#f59e0b" />
  <circle cx="33" cy="35" r="3" fill="#f59e0b" />
  <circle cx="40" cy="32" r="3" fill="#f59e0b" />
  <circle cx="47" cy="35" r="3" fill="#f59e0b" />
</svg>""")
    write_svg(ABILITIES_DIR, "erez_p", ability_svg("#0f1f3d", "#3b82f6", "#fbbf24", """
      <ellipse cx="0" cy="3" rx="8" ry="6" fill="#fbbf24" />
      <circle cx="-8" cy="-8" r="3.5" fill="#fbbf24" />
      <circle cx="0" cy="-11" r="3.5" fill="#fbbf24" />
      <circle cx="8" cy="-8" r="3.5" fill="#fbbf24" />
    """))
    write_svg(ABILITIES_DIR, "erez_q", ability_svg("#112447", "#60a5fa", "#ffffff", """
      <line x1="-15" y1="15" x2="15" y2="-15" stroke="#93c5fd" stroke-width="4" stroke-linecap="round" />
      <!-- Claw scratches -->
      <path d="M-8,-10 L-2,-16 M0,-4 L6,-10 M8,2 L14,-4" stroke="#facc15" stroke-width="2.5" stroke-linecap="round" />
    """))
    write_svg(ABILITIES_DIR, "erez_w", ability_svg("#162e3b", "#38bdf8", "#67e8f9", """
      <path d="M-14,-14 L14,-14 L16,6 C16,16 0,20 0,20 C0,20 -16,16 -16,6 Z" fill="#0284c7" stroke="#38bdf8" stroke-width="2" />
      <circle cx="0" cy="2" r="5" fill="#e0f2fe" />
    """))
    write_svg(ABILITIES_DIR, "erez_e", ability_svg("#1e293b", "#f59e0b", "#fbbf24", """
      <circle cx="0" cy="0" r="15" fill="none" stroke="#f59e0b" stroke-width="2" stroke-dasharray="4,3" />
      <circle cx="0" cy="0" r="8" fill="none" stroke="#fbbf24" stroke-width="2" />
      <circle cx="0" cy="0" r="3" fill="#fef08a" />
    """))
    write_svg(ABILITIES_DIR, "erez_r", ability_svg("#2e1065", "#ec4899", "#f43f5e", """
      <polygon points="0,-16 5,-5 16,-5 8,4 11,15 0,8 -11,15 -8,4 -16,-5 -5,-5" fill="#f43f5e" stroke="#fbbf24" stroke-width="2" />
    """))

    # =========================================================================
    # 2. STEPHEN - The Radiant Spirit (Petite Filipino Support)
    # =========================================================================
    write_svg(CHAMPS_DIR, "stephen", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#172554" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#1e3a8a" stroke="#facc15" stroke-width="3" />
  <!-- Filipino Golden Sun with 8 rays -->
  <circle cx="40" cy="40" r="14" fill="#fbbf24" stroke="#f59e0b" stroke-width="2" />
  <line x1="40" y1="16" x2="40" y2="22" stroke="#facc15" stroke-width="3" stroke-linecap="round" />
  <line x1="40" y1="58" x2="40" y2="64" stroke="#facc15" stroke-width="3" stroke-linecap="round" />
  <line x1="16" y1="40" x2="22" y2="40" stroke="#facc15" stroke-width="3" stroke-linecap="round" />
  <line x1="58" y1="40" x2="64" y2="40" stroke="#facc15" stroke-width="3" stroke-linecap="round" />
  <line x1="23" y1="23" x2="28" y2="28" stroke="#facc15" stroke-width="2.5" stroke-linecap="round" />
  <line x1="57" y1="23" x2="52" y2="28" stroke="#facc15" stroke-width="2.5" stroke-linecap="round" />
  <line x1="23" y1="57" x2="28" y2="52" stroke="#facc15" stroke-width="2.5" stroke-linecap="round" />
  <line x1="57" y1="57" x2="52" y2="52" stroke="#facc15" stroke-width="2.5" stroke-linecap="round" />
  <!-- Pocket heart emblem inside sun -->
  <path d="M 40,36 C 38,33 34,33 34,37 C 34,42 40,46 40,46 C 40,46 46,42 46,37 C 46,33 42,33 40,36 Z" fill="#ef4444" />
</svg>""")
    write_svg(ABILITIES_DIR, "stephen_p", ability_svg("#1e1b4b", "#facc15", "#ef4444", """
      <circle cx="0" cy="0" r="9" fill="#facc15" />
      <path d="M0,-2 C-3,-5 -7,-5 -7,-1 C-7,4 0,8 0,8 C0,8 7,4 7,-1 C7,-5 3,-5 0,-2 Z" fill="#ef4444" />
    """))
    write_svg(ABILITIES_DIR, "stephen_q", ability_svg("#1e1b4b", "#fbbf24", "#fef08a", """
      <circle cx="0" cy="0" r="10" fill="#fde047" />
      <line x1="0" y1="-17" x2="0" y2="-12" stroke="#fbbf24" stroke-width="3" stroke-linecap="round" />
      <line x1="0" y1="17" x2="0" y2="12" stroke="#fbbf24" stroke-width="3" stroke-linecap="round" />
      <line x1="-17" y1="0" x2="-12" y2="0" stroke="#fbbf24" stroke-width="3" stroke-linecap="round" />
      <line x1="17" y1="0" x2="12" y2="0" stroke="#fbbf24" stroke-width="3" stroke-linecap="round" />
    """))
    write_svg(ABILITIES_DIR, "stephen_w", ability_svg("#0f172a", "#38bdf8", "#fbbf24", """
      <circle cx="0" cy="0" r="14" fill="none" stroke="#38bdf8" stroke-width="3" />
      <circle cx="0" cy="0" r="6" fill="#facc15" />
    """))
    write_svg(ABILITIES_DIR, "stephen_e", ability_svg("#064e3b", "#10b981", "#34d399", """
      <circle cx="0" cy="0" r="15" fill="none" stroke="#34d399" stroke-width="2" stroke-dasharray="3,3" />
      <rect x="-3" y="-10" width="6" height="20" rx="2" fill="#10b981" />
      <rect x="-10" y="-3" width="20" height="6" rx="2" fill="#10b981" />
    """))
    write_svg(ABILITIES_DIR, "stephen_r", ability_svg("#312e81", "#f59e0b", "#fde047", """
      <circle cx="0" cy="0" r="16" fill="#fde047" opacity="0.4" />
      <circle cx="0" cy="0" r="10" fill="#f59e0b" />
      <line x1="-20" y1="0" x2="20" y2="0" stroke="#fde047" stroke-width="2.5" />
      <line x1="0" y1="-20" x2="0" y2="20" stroke="#fde047" stroke-width="2.5" />
    """))

    # =========================================================================
    # 3. AMIT - The Maestro of Stances (Rock / White Girl / Mizrahit)
    # =========================================================================
    write_svg(CHAMPS_DIR, "amit", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#1a102f" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#2e1065" stroke="#ec4899" stroke-width="3" />
  <!-- Electric Guitar Body & Neck -->
  <path d="M 30,55 C 20,48 24,35 34,42 C 37,44 42,38 46,45 C 52,55 42,62 30,55 Z" fill="#ef4444" stroke="#fbbf24" stroke-width="2" />
  <line x1="36" y1="42" x2="60" y2="18" stroke="#f59e0b" stroke-width="3" stroke-linecap="round" />
  <!-- Musical 8th notes -->
  <circle cx="22" cy="26" r="4" fill="#38bdf8" />
  <circle cx="32" cy="22" r="4" fill="#38bdf8" />
  <line x1="26" y1="26" x2="26" y2="14" stroke="#38bdf8" stroke-width="2" />
  <line x1="36" y1="22" x2="36" y2="10" stroke="#38bdf8" stroke-width="2" />
  <line x1="26" y1="14" x2="36" y2="10" stroke="#38bdf8" stroke-width="2.5" />
</svg>""")
    write_svg(ABILITIES_DIR, "amit_p", ability_svg("#2e1065", "#ec4899", "#38bdf8", """
      <!-- Equalizer soundbars -->
      <rect x="-14" y="0" width="4" height="14" rx="1" fill="#ec4899" />
      <rect x="-6" y="-10" width="4" height="24" rx="1" fill="#38bdf8" />
      <rect x="2" y="-16" width="4" height="30" rx="1" fill="#facc15" />
      <rect x="10" y="-4" width="4" height="18" rx="1" fill="#10b981" />
    """))
    write_svg(ABILITIES_DIR, "amit_q", ability_svg("#450a0a", "#ef4444", "#fbbf24", """
      <!-- Rock Lightning Guitar Pick -->
      <polygon points="0,-16 14,12 -14,12" fill="#ef4444" stroke="#fbbf24" stroke-width="2" />
      <path d="M-2,-8 L4,-2 L-1,-1 L3,6" stroke="#ffffff" stroke-width="2" fill="none" stroke-linecap="round" />
    """))
    write_svg(ABILITIES_DIR, "amit_w", ability_svg("#3b0764", "#ec4899", "#f472b6", """
      <!-- Pop Star Sparkling Heart Note -->
      <path d="M0,-5 C-4,-11 -12,-11 -12,-4 C-12,4 0,12 0,12 C0,12 12,4 12,-4 C12,-11 4,-11 0,-5 Z" fill="#ec4899" />
      <circle cx="-2" cy="-2" r="1.5" fill="#ffffff" />
    """))
    write_svg(ABILITIES_DIR, "amit_e", ability_svg("#422006", "#d97706", "#fbbf24", """
      <!-- Mizrahit Oud & Melody Wave -->
      <ellipse cx="-4" cy="4" rx="10" ry="8" fill="#b45309" stroke="#fbbf24" stroke-width="1.5" />
      <line x1="2" y1="-2" x2="16" y2="-14" stroke="#fbbf24" stroke-width="2" stroke-linecap="round" />
      <path d="M-14,-8 Q-4,-16 6,-8 T16,-4" stroke="#fde68a" stroke-width="2" fill="none" />
    """))
    write_svg(ABILITIES_DIR, "amit_r", ability_svg("#1e1b4b", "#8b5cf6", "#f43f5e", """
      <!-- Grand Concert Sonic Blast -->
      <circle cx="0" cy="0" r="15" fill="none" stroke="#ec4899" stroke-width="2.5" />
      <circle cx="0" cy="0" r="9" fill="none" stroke="#38bdf8" stroke-width="2.5" />
      <circle cx="0" cy="0" r="4" fill="#fbbf24" />
    """))

    # =========================================================================
    # 4. NISSIM - The Grandfather Strategist ("אבא של כולם")
    # =========================================================================
    write_svg(CHAMPS_DIR, "nissim", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#0c1e19" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#132e27" stroke="#10b981" stroke-width="3" />
  <!-- Reading Glasses -->
  <circle cx="32" cy="30" r="7" fill="none" stroke="#fbbf24" stroke-width="2.5" />
  <circle cx="48" cy="30" r="7" fill="none" stroke="#fbbf24" stroke-width="2.5" />
  <line x1="39" y1="30" x2="41" y2="30" stroke="#fbbf24" stroke-width="2.5" />
  <!-- Steaming Coffee Cup -->
  <rect x="30" y="44" width="20" height="18" rx="4" fill="#047857" stroke="#34d399" stroke-width="2" />
  <path d="M 50,48 C 55,48 55,58 50,58" fill="none" stroke="#34d399" stroke-width="2" />
  <!-- Steam lines -->
  <path d="M 35,41 Q 33,37 36,34" stroke="#a7f3d0" stroke-width="1.5" fill="none" />
  <path d="M 45,41 Q 43,37 46,34" stroke="#a7f3d0" stroke-width="1.5" fill="none" />
</svg>""")
    write_svg(ABILITIES_DIR, "nissim_p", ability_svg("#064e3b", "#10b981", "#fbbf24", """
      <!-- Reading Glasses -->
      <circle cx="-8" cy="0" r="6" fill="none" stroke="#fbbf24" stroke-width="2" />
      <circle cx="8" cy="0" r="6" fill="none" stroke="#fbbf24" stroke-width="2" />
      <line x1="-2" y1="0" x2="2" y2="0" stroke="#fbbf24" stroke-width="2" />
    """))
    write_svg(ABILITIES_DIR, "nissim_q", ability_svg("#0f2922", "#34d399", "#ffffff", """
      <!-- Tactical Decree Arrow -->
      <polygon points="0,-16 12,4 4,4 4,14 -4,14 -4,4 -12,4" fill="#34d399" stroke="#fbbf24" stroke-width="1.5" />
    """))
    write_svg(ABILITIES_DIR, "nissim_w", ability_svg("#1e293b", "#0284c7", "#38bdf8", """
      <!-- Tactical Time-Out Barrier -->
      <rect x="-14" y="-14" width="28" height="28" rx="4" fill="none" stroke="#38bdf8" stroke-width="2.5" />
      <line x1="-8" y1="-8" x2="8" y2="8" stroke="#38bdf8" stroke-width="2" />
    """))
    write_svg(ABILITIES_DIR, "nissim_e", ability_svg("#451a03", "#d97706", "#fef3c7", """
      <!-- Steaming Coffee Cup -->
      <rect x="-8" y="-4" width="16" height="16" rx="3" fill="#b45309" stroke="#fbbf24" stroke-width="1.5" />
      <path d="M 8,0 C 13,0 13,8 8,8" fill="none" stroke="#fbbf24" stroke-width="1.5" />
      <path d="M-4,-8 Q-6,-12 -3,-15" stroke="#fef3c7" stroke-width="1.5" fill="none" />
      <path d="M3,-8 Q1,-12 4,-15" stroke="#fef3c7" stroke-width="1.5" fill="none" />
    """))
    write_svg(ABILITIES_DIR, "nissim_r", ability_svg("#022c22", "#10b981", "#facc15", """
      <!-- Master Plan Blueprint Grid -->
      <rect x="-15" y="-15" width="30" height="30" rx="3" fill="#065f46" stroke="#facc15" stroke-width="2" />
      <line x1="-15" y1="0" x2="15" y2="0" stroke="#34d399" stroke-width="1.5" />
      <line x1="0" y1="-15" x2="0" y2="15" stroke="#34d399" stroke-width="1.5" />
      <circle cx="0" cy="0" r="4" fill="#facc15" />
    """))

    # =========================================================================
    # 5. ROGO - The Heavy Smasher (Colossal Tank)
    # =========================================================================
    write_svg(CHAMPS_DIR, "rogo", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#2d0a0a" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#4c0d0d" stroke="#ef4444" stroke-width="3" />
  <!-- Massive Crushing Fist / Anvil -->
  <path d="M 22,34 L 58,34 L 52,58 L 28,58 Z" fill="#991b1b" stroke="#f87171" stroke-width="3" />
  <rect x="25" y="24" width="30" height="12" rx="4" fill="#dc2626" stroke="#fca5a5" stroke-width="2" />
  <!-- Shockwave ripples -->
  <path d="M 16,64 Q 40,54 64,64" stroke="#fbbf24" stroke-width="3" fill="none" stroke-linecap="round" />
</svg>""")
    write_svg(ABILITIES_DIR, "rogo_p", ability_svg("#450a0a", "#ef4444", "#f87171", """
      <!-- Colossal Armor Mass -->
      <polygon points="0,-16 16,-6 16,10 0,16 -16,10 -16,-6" fill="#991b1b" stroke="#f87171" stroke-width="2" />
      <circle cx="0" cy="0" r="4" fill="#fca5a5" />
    """))
    write_svg(ABILITIES_DIR, "rogo_q", ability_svg("#3b0707", "#dc2626", "#fbbf24", """
      <!-- Heavy Fist Slam -->
      <rect x="-10" y="-15" width="20" height="16" rx="4" fill="#b91c1c" stroke="#fbbf24" stroke-width="2" />
      <line x1="-12" y1="8" x2="12" y2="8" stroke="#f87171" stroke-width="3" />
    """))
    write_svg(ABILITIES_DIR, "rogo_w", ability_svg("#4c0519", "#f43f5e", "#fda4af", """
      <!-- Iron Belly Bounce -->
      <circle cx="0" cy="0" r="14" fill="#be123c" stroke="#f43f5e" stroke-width="2.5" />
      <path d="M-8,0 Q0,8 8,0" stroke="#ffffff" stroke-width="2.5" fill="none" />
    """))
    write_svg(ABILITIES_DIR, "rogo_e", ability_svg("#2e1065", "#c026d3", "#f0abfc", """
      <!-- Belly Flop Dash -->
      <ellipse cx="0" cy="0" rx="16" ry="10" fill="#9333ea" stroke="#f0abfc" stroke-width="2" />
      <polygon points="8,-4 14,0 8,4" fill="#ffffff" />
    """))
    write_svg(ABILITIES_DIR, "rogo_r", ability_svg("#500724", "#e11d48", "#fbbf24", """
      <!-- Cataclysmic Crater -->
      <circle cx="0" cy="0" r="16" fill="none" stroke="#fbbf24" stroke-width="3" stroke-dasharray="4,2" />
      <polygon points="0,-10 8,-2 14,-8 10,4 16,8 6,10 0,16 -6,10 -16,8 -10,4 -14,-8 -8,-2" fill="#be123c" />
    """))

    # =========================================================================
    # 6. YAKIR - The Refreshment Specialist (Energy Drinks & Food Support)
    # =========================================================================
    write_svg(CHAMPS_DIR, "yakir", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#042f2e" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#064e3b" stroke="#10b981" stroke-width="3" />
  <!-- Energy Drink Can (XL / Monster) -->
  <rect x="22" y="22" width="16" height="36" rx="4" fill="#0f172a" stroke="#22c55e" stroke-width="2" />
  <path d="M 28,30 L 34,38 L 30,38 L 36,48" stroke="#22c55e" stroke-width="2" fill="none" />
  <!-- Hot Pizza / Shawarma Slice -->
  <polygon points="56,22 42,56 68,52" fill="#f59e0b" stroke="#fbbf24" stroke-width="2" />
  <circle cx="54" cy="40" r="2.5" fill="#ef4444" />
  <circle cx="50" cy="48" r="2" fill="#ef4444" />
</svg>""")
    write_svg(ABILITIES_DIR, "yakir_p", ability_svg("#022c22", "#10b981", "#86efac", """
      <!-- Energy Boost Sneakers -->
      <path d="M-12,4 L0,-6 L12,4 L8,10 L-8,10 Z" fill="#10b981" stroke="#86efac" stroke-width="2" />
      <path d="M-2,-12 L4,-6 L0,-6 L3,0" stroke="#facc15" stroke-width="2" fill="none" />
    """))
    write_svg(ABILITIES_DIR, "yakir_q", ability_svg("#064e3b", "#22c55e", "#86efac", """
      <!-- Flying Energy Drink Can -->
      <rect x="-6" y="-14" width="12" height="28" rx="3" fill="#0f172a" stroke="#22c55e" stroke-width="2" />
      <path d="M-2,-6 L2,0 L-1,0 L3,6" stroke="#22c55e" stroke-width="2" fill="none" />
    """))
    write_svg(ABILITIES_DIR, "yakir_w", ability_svg("#451a03", "#f59e0b", "#fef08a", """
      <!-- Hot Snack / Shawarma Wrap -->
      <ellipse cx="0" cy="0" rx="14" ry="8" fill="#d97706" stroke="#fde047" stroke-width="2" />
      <circle cx="-4" cy="0" r="2" fill="#ef4444" />
      <circle cx="4" cy="0" r="2" fill="#10b981" />
    """))
    write_svg(ABILITIES_DIR, "yakir_e", ability_svg("#1e1b4b", "#6366f1", "#a5b4fc", """
      <!-- Sugar / Caffeine Surge -->
      <polygon points="0,-16 5,-3 16,0 6,6 8,16 0,9 -8,16 -6,6 -16,0 -5,-3" fill="#818cf8" stroke="#c7d2fe" stroke-width="1.5" />
    """))
    write_svg(ABILITIES_DIR, "yakir_r", ability_svg("#14532d", "#22c55e", "#facc15", """
      <!-- The Grand Picnic Feast -->
      <ellipse cx="0" cy="4" rx="16" ry="10" fill="#166534" stroke="#facc15" stroke-width="2" />
      <rect x="-4" y="-8" width="8" height="12" rx="2" fill="#f59e0b" />
      <circle cx="-8" cy="2" r="3" fill="#ef4444" />
      <circle cx="8" cy="2" r="3" fill="#22c55e" />
    """))

    # =========================================================================
    # 7. LIOR - The Graceful Vanguard (Feminine / Effeminate Male Tank)
    # =========================================================================
    write_svg(CHAMPS_DIR, "lior", """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <rect width="80" height="80" rx="12" fill="#2a1222" />
  <rect x="3" y="3" width="74" height="74" rx="10" fill="#4a1d3c" stroke="#f472b6" stroke-width="3" />
  <!-- Elegant Prismatic Mirror Shield -->
  <path d="M 40,16 L 62,28 C 62,50 40,68 40,68 C 40,68 18,50 18,28 Z" fill="#ec4899" stroke="#fbcfe8" stroke-width="2.5" />
  <!-- Crystal mirror facet reflection -->
  <polygon points="40,24 52,34 40,54 28,34" fill="#fdf2f8" opacity="0.85" />
  <!-- Rose-gold delicate floral embellishment -->
  <circle cx="40" cy="38" r="4" fill="#fb7185" />
  <circle cx="40" cy="32" r="2" fill="#f43f5e" />
  <circle cx="40" cy="44" r="2" fill="#f43f5e" />
  <circle cx="34" cy="38" r="2" fill="#f43f5e" />
  <circle cx="46" cy="38" r="2" fill="#f43f5e" />
</svg>""")
    write_svg(ABILITIES_DIR, "lior_p", ability_svg("#3b0724", "#ec4899", "#fbcfe8", """
      <!-- Prismatic Glamour Sparkle -->
      <polygon points="0,-15 4,-4 15,0 4,4 0,15 -4,4 -15,0 -4,-4" fill="#f472b6" stroke="#ffffff" stroke-width="1.5" />
      <circle cx="-8" cy="-8" r="2" fill="#fbcfe8" />
      <circle cx="8" cy="8" r="2" fill="#fbcfe8" />
    """))
    write_svg(ABILITIES_DIR, "lior_q", ability_svg("#4c0519", "#f43f5e", "#fda4af", """
      <!-- Graceful Mirror Lunge -->
      <line x1="-12" y1="12" x2="12" y2="-12" stroke="#fda4af" stroke-width="3" stroke-linecap="round" />
      <polygon points="12,-12 4,-12 12,-4" fill="#f43f5e" />
      <circle cx="-6" cy="6" r="3" fill="#fbcfe8" />
    """))
    write_svg(ABILITIES_DIR, "lior_w", ability_svg("#3b0724", "#db2777", "#fdf2f8", """
      <!-- Mirror Sheen Reflection Barrier -->
      <path d="M-14,-14 L14,-14 L16,6 C16,16 0,20 0,20 C0,20 -16,16 -16,6 Z" fill="#ec4899" stroke="#fdf2f8" stroke-width="2" />
      <line x1="-6" y1="-4" x2="6" y2="8" stroke="#ffffff" stroke-width="2" stroke-linecap="round" />
    """))
    write_svg(ABILITIES_DIR, "lior_e", ability_svg("#4a044e", "#c026d3", "#f5d0fe", """
      <!-- Charming Step Swirl -->
      <circle cx="0" cy="0" r="14" fill="none" stroke="#f5d0fe" stroke-width="2" stroke-dasharray="4,3" />
      <polygon points="0,-8 6,0 0,8 -6,0" fill="#e879f9" />
    """))
    write_svg(ABILITIES_DIR, "lior_r", ability_svg("#2a1222", "#f472b6", "#fef08a", """
      <!-- Dazzling Pavilion Dome -->
      <path d="M-16,10 C-16,-8 16,-8 16,10 Z" fill="#db2777" stroke="#fef08a" stroke-width="2.5" />
      <circle cx="0" cy="-10" r="4" fill="#fef08a" />
      <line x1="-16" y1="10" x2="16" y2="10" stroke="#fef08a" stroke-width="2" />
    """))

    print("All SVGs successfully written!")

if __name__ == "__main__":
    gen()
