#!/usr/bin/env python3
"""
Outpost Nova — Galaxy Map Generator
Run: python3 docs/world/generate_map.py
Writes: docs/world/galaxy-map.svg
"""

import math
import os

# ---------------------------------------------------------------------------
# Canvas
# ---------------------------------------------------------------------------
WIDTH = 1400
HEIGHT = 900
BG = "#0d0d1a"

# ---------------------------------------------------------------------------
# Region polygons  (x, y) pairs, drawn as filled SVG polygons
# ---------------------------------------------------------------------------
REGIONS = {
    "federation_core": {
        "label": "Federation Core",
        "color": "#2a4a7f",
        "opacity": 0.55,
        # Coreward arm extends northeast into Keth territory — explains the Fracture Zone
        "points": [
            (50, 360), (50, 630), (300, 670), (510, 615),
            (615, 495), (630, 345), (550, 235), (400, 210),
            (255, 240), (150, 295),
        ],
    },
    "inner_frontier": {
        "label": "Inner Frontier",
        "color": "#3a3a5c",
        "opacity": 0.55,
        # Tentacular — arms reach into Keth Space (north), Fracture Zone (east), Border Zone (southeast)
        "points": [
            (548, 242),   # upper-left, shares boundary with Fed Core coreward arm
            (575, 170),   # NORTH ARM — reaches into Keth Space
            (645, 195),   # north arm, right side
            (650, 295),   # back to body
            (815, 350),   # EAST ARM — reaches into Fracture Zone
            (775, 440),   # east arm returns
            (760, 515),   # body lower-right
            (820, 575),   # SOUTHEAST ARM — reaches into Border Zone
            (740, 625),   # southeast arm returns
            (640, 660),   # body lower
            (510, 615),   # lower-left body
            (615, 495),   # left side mid
            (630, 345),   # upper-left side
        ],
    },
    "keth_space": {
        "label": "Keth Space",
        "color": "#2a5a3a",
        "opacity": 0.55,
        # Rimward arm extends southwest — overlaps Federation coreward arm, creating conflict zone
        "points": [
            (840, 115), (570, 110), (380, 155), (285, 250),
            (400, 340), (545, 415), (700, 455), (920, 450),
            (1110, 385), (1140, 225), (1050, 120),
        ],
    },
    "border_zone": {
        "label": "Border Zone",
        "color": "#4a3a2a",
        "opacity": 0.55,
        "points": [
            (580, 290), (720, 555), (675, 665), (875, 695),
            (1100, 655), (1160, 510), (1060, 372), (935, 295),
            (795, 268), (658, 255),
        ],
    },
    "fracture_zone": {
        "label": "Fracture Zone",
        "color": "#5a2a2a",
        "opacity": 0.70,
        # Sits at the overlap of Federation and Keth arms — the war epicenter
        "points": [
            (535, 308), (668, 270), (808, 316), (828, 422),
            (722, 452), (572, 442), (508, 382),
        ],
    },
    "unmapped": {
        "label": "The Unmapped",
        "color": "#1a1a2a",
        "opacity": 0.70,
        "points": [
            (0, 0), (1400, 0), (1400, 200), (1050, 150),
            (640, 100), (340, 140), (0, 200),
        ],
    },
    "unmapped_south": {
        "label": "",   # no second label — same region
        "color": "#1a1a2a",
        "opacity": 0.70,
        "points": [
            (0, 720), (1400, 720), (1400, 900), (0, 900),
        ],
    },
}

# ---------------------------------------------------------------------------
# World / location data
# ---------------------------------------------------------------------------
# symbol: "circle" | "cross" | "hex_ring" | "station"
WORLDS = {
    "earth":            {"label": "Earth (Sol)",      "x": 160,  "y": 490, "symbol": "circle",   "region": "federation_core",  "r": 6},
    "harrow":           {"label": "Harrow",            "x": 250,  "y": 420, "symbol": "circle",   "region": "federation_core",  "r": 5},
    "velan":            {"label": "Velan",             "x": 300,  "y": 530, "symbol": "circle",   "region": "federation_core",  "r": 5},
    "breck":            {"label": "Breck",             "x": 490,  "y": 560, "symbol": "circle",   "region": "inner_frontier",   "r": 5},
    "auren":            {"label": "Auren",             "x": 610,  "y": 490, "symbol": "circle",   "region": "inner_frontier",   "r": 5},
    "surev_prime":      {"label": "Surev Prime",       "x": 560,  "y": 600, "symbol": "circle",   "region": "inner_frontier",   "r": 5},
    "vaedra":           {"label": "Vaedra",            "x": 440,  "y": 510, "symbol": "circle",   "region": "inner_frontier",   "r": 4},
    "ashfeld":          {"label": "Ashfeld",           "x": 510,  "y": 440, "symbol": "circle",   "region": "inner_frontier",   "r": 5},
    "carnach_station":  {"label": "Carnach Station",   "x": 600,  "y": 515, "symbol": "station",  "region": "border_zone",      "r": 5},
    "sundra":           {"label": "Sundra",            "x": 830,  "y": 515, "symbol": "circle",   "region": "border_zone",      "r": 5},
    "outpost_nova":     {"label": "Outpost Nova",      "x": 700,  "y": 460, "symbol": "hex_ring", "region": "border_zone",      "r": 8},
    "thessara":         {"label": "Thessara",          "x": 820,  "y": 430, "symbol": "cross",    "region": "fracture_zone",    "r": 6},
    "vaethos":          {"label": "Vaethos",           "x": 720,  "y": 200, "symbol": "circle",   "region": "keth_space",       "r": 6},
    "korath":           {"label": "Korath",            "x": 640,  "y": 295, "symbol": "circle",   "region": "keth_space",       "r": 5},
}

# Builder secondary sites — no labels, diamond symbol, approximate positions
BUILDER_SECONDARY = [
    (680, 490),
    (760, 420),
    (740, 348),
    (820, 362),
]

# ---------------------------------------------------------------------------
# Trade lanes  (list of (x,y) waypoints)
# ---------------------------------------------------------------------------
# style: "solid" | "dashed" | "dotted"
TRADE_LANES = [
    {
        "label": "Federation Spine",
        "style": "solid",
        "color": "#8ab4f8",
        "width": 2,
        "points": [(160, 490), (300, 490), (440, 490), (580, 490), (600, 515)],
    },
    {
        "label": "Keth Internal Routes",
        "style": "solid",
        "color": "#6abf8a",
        "width": 2,
        "points": [(720, 200), (640, 295), (580, 375), (575, 415)],
    },
    {
        "label": "Emerging Keth Trade Lane",
        "style": "dashed",
        "color": "#6abf8a",
        "width": 2,
        "points": [(575, 415), (610, 490), (600, 515), (700, 460)],
    },
    {
        "label": "Hegemony Extraction Web",
        "style": "dotted",
        "color": "#c8860a",
        "width": 1.5,
        "points": [(600, 515), (580, 490), (560, 600), (490, 560), (440, 510)],
    },
    {
        "label": "Unaligned Passage Routes",
        "style": "dotted",
        "color": "#4a8a7a",
        "width": 1.5,
        "points": [(830, 515), (700, 460), (800, 490), (870, 570)],
    },
]

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
WORLD_COLORS = {
    "federation_core": "#8ab4f8",
    "inner_frontier":  "#a0a0cc",
    "keth_space":      "#6abf8a",
    "border_zone":     "#d4a060",
    "fracture_zone":   "#d06060",
}
OUTPOST_NOVA_COLOR = "#ffb347"
DESTROYED_COLOR    = "#888888"
BUILDER_COLOR      = "#bbbbff"

LABEL_FONT  = "font-family='monospace' font-size='11'"
REGION_FONT = "font-family='monospace' font-size='13' fill='#ffffff' opacity='0.5'"
TITLE_FONT  = "font-family='monospace' fill='#ffb347' font-weight='bold'"


def pts(points):
    """Convert list of (x,y) tuples to SVG points string."""
    return " ".join(f"{x},{y}" for x, y in points)


def polyline_dasharray(style):
    if style == "dashed":
        return "stroke-dasharray='8,5'"
    if style == "dotted":
        return "stroke-dasharray='2,4'"
    return ""


def world_color(w):
    if w["symbol"] == "hex_ring":
        return OUTPOST_NOVA_COLOR
    if w["symbol"] == "cross":
        return DESTROYED_COLOR
    return WORLD_COLORS.get(w["region"], "#ffffff")


# ---------------------------------------------------------------------------
# SVG element builders
# ---------------------------------------------------------------------------

def svg_regions(lines):
    for key, r in REGIONS.items():
        lines.append(
            f"  <polygon points='{pts(r['points'])}' "
            f"fill='{r['color']}' opacity='{r['opacity']}' stroke='none'/>"
        )
    # Region labels (skip unmapped_south — same label as unmapped)
    for key, r in REGIONS.items():
        if not r["label"]:
            continue
        cx = sum(p[0] for p in r["points"]) / len(r["points"])
        cy = sum(p[1] for p in r["points"]) / len(r["points"])
        lines.append(
            f"  <text x='{cx:.0f}' y='{cy:.0f}' text-anchor='middle' "
            f"{REGION_FONT}>{r['label']}</text>"
        )


def svg_trade_lanes(lines):
    for lane in TRADE_LANES:
        da = polyline_dasharray(lane["style"])
        lines.append(
            f"  <polyline points='{pts(lane['points'])}' "
            f"fill='none' stroke='{lane['color']}' "
            f"stroke-width='{lane['width']}' {da} opacity='0.7'/>"
        )


def svg_builder_secondary(lines):
    s = 7  # half-size of diamond
    for (x, y) in BUILDER_SECONDARY:
        lines.append(
            f"  <polygon points='{x},{y-s} {x+s},{y} {x},{y+s} {x-s},{y}' "
            f"fill='none' stroke='{BUILDER_COLOR}' stroke-width='1.2' opacity='0.6'/>"
        )


def svg_worlds(lines):
    for key, w in WORLDS.items():
        x, y, r = w["x"], w["y"], w["r"]
        col = world_color(w)
        sym = w["symbol"]

        if sym == "circle" or sym == "station":
            stroke = "#ffffff" if sym == "station" else "none"
            sw = 1.5 if sym == "station" else 0
            lines.append(
                f"  <circle cx='{x}' cy='{y}' r='{r}' fill='{col}' "
                f"stroke='{stroke}' stroke-width='{sw}'/>"
            )

        elif sym == "hex_ring":
            # Hexagon outline
            angles = [math.radians(60 * i - 30) for i in range(6)]
            hex_pts = [(x + r * math.cos(a), y + r * math.sin(a)) for a in angles]
            lines.append(
                f"  <polygon points='{pts(hex_pts)}' fill='none' "
                f"stroke='{col}' stroke-width='2'/>"
            )
            # Inner dot
            lines.append(f"  <circle cx='{x}' cy='{y}' r='3' fill='{col}'/>")

        elif sym == "cross":
            # × marker for destroyed world
            d = r
            lines.append(
                f"  <line x1='{x-d}' y1='{y-d}' x2='{x+d}' y2='{y+d}' "
                f"stroke='{col}' stroke-width='2'/>"
            )
            lines.append(
                f"  <line x1='{x+d}' y1='{y-d}' x2='{x-d}' y2='{y+d}' "
                f"stroke='{col}' stroke-width='2'/>"
            )

        # Label — offset slightly so it doesn't overlap the symbol
        lx = x + r + 4
        ly = y + 4
        fw = "font-weight='bold'" if sym == "hex_ring" else ""
        fc = OUTPOST_NOVA_COLOR if sym == "hex_ring" else "#cccccc"
        lines.append(
            f"  <text x='{lx}' y='{ly}' {LABEL_FONT} "
            f"fill='{fc}' {fw}>{w['label']}</text>"
        )


def svg_legend(lines):
    lx, ly = 30, 730
    lines.append(f"  <rect x='{lx-8}' y='{ly-18}' width='320' height='155' "
                 f"fill='#0d0d1a' opacity='0.8' rx='4'/>")
    lines.append(f"  <text x='{lx}' y='{ly}' {TITLE_FONT} font-size='16'>Legend</text>")

    entries = [
        ("circle",    "#8ab4f8",     "World / Station"),
        ("station",   "#d4a060",     "Orbital Station (ring)"),
        ("hex_ring",  OUTPOST_NOVA_COLOR, "Outpost Nova (Builder primary node)"),
        ("cross",     DESTROYED_COLOR,   "Destroyed world (×)"),
        ("diamond",   BUILDER_COLOR,     "Builder secondary site (◇)"),
    ]
    for i, (sym, col, label) in enumerate(entries):
        ey = ly + 20 + i * 18
        ex = lx + 10
        if sym == "circle":
            lines.append(f"  <circle cx='{ex}' cy='{ey-4}' r='5' fill='{col}'/>")
        elif sym == "station":
            lines.append(f"  <circle cx='{ex}' cy='{ey-4}' r='5' fill='{col}' "
                         f"stroke='#ffffff' stroke-width='1.5'/>")
        elif sym == "hex_ring":
            angs = [math.radians(60*i-30) for i in range(6)]
            hp = [(ex + 6*math.cos(a), ey-4 + 6*math.sin(a)) for a in angs]
            lines.append(f"  <polygon points='{pts(hp)}' fill='none' "
                         f"stroke='{col}' stroke-width='2'/>")
            lines.append(f"  <circle cx='{ex}' cy='{ey-4}' r='2' fill='{col}'/>")
        elif sym == "cross":
            d = 5
            lines.append(f"  <line x1='{ex-d}' y1='{ey-9}' x2='{ex+d}' y2='{ey+1}' "
                         f"stroke='{col}' stroke-width='2'/>")
            lines.append(f"  <line x1='{ex+d}' y1='{ey-9}' x2='{ex-d}' y2='{ey+1}' "
                         f"stroke='{col}' stroke-width='2'/>")
        elif sym == "diamond":
            s = 6
            lines.append(f"  <polygon points='{ex},{ey-10} {ex+s},{ey-4} "
                         f"{ex},{ey+2} {ex-s},{ey-4}' fill='none' "
                         f"stroke='{col}' stroke-width='1.2'/>")
        lines.append(f"  <text x='{ex+14}' y='{ey}' {LABEL_FONT} fill='#cccccc'>{label}</text>")

    # Trade lane styles
    lane_entries = [
        ("solid",  "#8ab4f8",     "Federation Spine"),
        ("solid",  "#6abf8a",     "Keth Internal / Emerging Lane"),
        ("dotted", "#c8860a",     "Hegemony Extraction Web"),
        ("dotted", "#4a8a7a",     "Unaligned Passage Routes"),
    ]
    for i, (style, col, label) in enumerate(lane_entries):
        ey = ly + 118 + i * 14
        da = polyline_dasharray(style)
        lines.append(f"  <line x1='{lx}' y1='{ey}' x2='{lx+22}' y2='{ey}' "
                     f"stroke='{col}' stroke-width='2' {da}/>")
        lines.append(f"  <text x='{lx+28}' y='{ey+4}' {LABEL_FONT} fill='#cccccc'>{label}</text>")

    # Faction / region colors — second box to the right
    rx, ry = 370, 730
    lines.append(f"  <rect x='{rx-8}' y='{ry-18}' width='265' height='122' "
                 f"fill='#0d0d1a' opacity='0.8' rx='4'/>")
    lines.append(f"  <text x='{rx}' y='{ry}' {TITLE_FONT} font-size='16'>Factions</text>")
    faction_entries = [
        ("#2a4a7f", 0.55, "Federation Core"),
        ("#3a3a5c", 0.55, "Inner Frontier"),
        ("#4a3a2a", 0.55, "Border Zone (Unaligned)"),
        ("#5a2a2a", 0.70, "Fracture Zone (contested frontier)"),
        ("#2a5a3a", 0.55, "Keth Space"),
        ("#1a1a2a", 0.70, "The Unmapped"),
    ]
    for i, (col, op, label) in enumerate(faction_entries):
        ey = ry + 16 + i * 17
        ex = rx + 8
        lines.append(f"  <rect x='{ex-6}' y='{ey-10}' width='14' height='12' "
                     f"fill='{col}' opacity='{op}' stroke='#555566' stroke-width='0.5'/>")
        lines.append(f"  <text x='{ex+13}' y='{ey}' {LABEL_FONT} fill='#cccccc'>{label}</text>")


def svg_inset(lines):
    """Galactic context inset — top-right corner."""
    ix, iy, iw, ih = WIDTH - 180, 20, 160, 120
    lines.append(f"  <rect x='{ix}' y='{iy}' width='{iw}' height='{ih}' "
                 f"fill='#050510' rx='4' stroke='#333355' stroke-width='1'/>")
    lines.append(f"  <text x='{ix+iw//2}' y='{iy+14}' text-anchor='middle' "
                 f"font-family='monospace' font-size='10' fill='#666688'>Milky Way — Orion Arm</text>")

    # Simplified spiral: two arms as cubic bezier paths
    cx, cy = ix + iw // 2, iy + ih // 2 + 8
    arm_color = "#334466"
    # Arm 1
    lines.append(
        f"  <path d='M {cx} {cy} C {cx+30},{cy-20} {cx+50},{cy+10} {cx+60},{cy+30}' "
        f"fill='none' stroke='{arm_color}' stroke-width='6' opacity='0.7'/>"
    )
    # Arm 2
    lines.append(
        f"  <path d='M {cx} {cy} C {cx-30},{cy+20} {cx-50},{cy-10} {cx-60},{cy-30}' "
        f"fill='none' stroke='{arm_color}' stroke-width='6' opacity='0.7'/>"
    )
    # Galactic core glow
    lines.append(
        f"  <circle cx='{cx}' cy='{cy}' r='6' fill='#aaaadd' opacity='0.6'/>"
    )
    # Known-space bubble marker
    bx, by = cx + 22, cy - 10
    lines.append(
        f"  <circle cx='{bx}' cy='{by}' r='8' fill='none' "
        f"stroke='#ffb347' stroke-width='1' opacity='0.8'/>"
    )
    lines.append(
        f"  <circle cx='{bx}' cy='{by}' r='2' fill='#ffb347' opacity='0.9'/>"
    )
    lines.append(
        f"  <text x='{bx+10}' y='{by+4}' font-family='monospace' font-size='9' "
        f"fill='#ffb347' opacity='0.9'>known space</text>"
    )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def generate():
    lines = []
    lines.append(
        f"<svg xmlns='http://www.w3.org/2000/svg' "
        f"width='{WIDTH}' height='{HEIGHT}' viewBox='0 0 {WIDTH} {HEIGHT}'>"
    )
    lines.append(f"  <rect width='{WIDTH}' height='{HEIGHT}' fill='{BG}'/>")

    svg_regions(lines)
    svg_trade_lanes(lines)
    svg_builder_secondary(lines)
    svg_worlds(lines)
    svg_legend(lines)
    svg_inset(lines)

    # Title
    lines.append(
        f"  <text x='30' y='36' {TITLE_FONT} font-size='20'>"
        f"Outpost Nova — Known Space</text>"
    )
    lines.append(
        f"  <text x='30' y='54' font-family='monospace' font-size='10' "
        f"fill='#555577'>~2,000 ly radius · Orion Arm · canonical lore reference</text>"
    )

    lines.append("</svg>")

    out_path = os.path.join(os.path.dirname(__file__), "galaxy-map.svg")
    with open(out_path, "w") as f:
        f.write("\n".join(lines))
    print(f"Written: {out_path}")


if __name__ == "__main__":
    generate()
