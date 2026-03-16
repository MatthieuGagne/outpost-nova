# Outpost Nova — Engine Choice

**Date:** 2026-03-15

## Decision: Godot 4

**Rationale:** Best-in-class 2D tooling, zero license risk (MIT), lightweight editor, exports to Windows/Mac/Linux/Web from one codebase. Ideal for a solo developer building a cozy 2D simulation game. Post-Unity exodus has made Godot the de facto indie standard.

## Key Facts

- **Language:** GDScript (Python-like, picks up fast) or C# — GDScript recommended for solo dev
- **Export targets:** Windows, macOS, Linux, Web (HTML5) — all from one project
- **Editor size:** ~120MB, launches instantly
- **License:** MIT — no runtime fees, no revenue sharing, terms cannot be changed unilaterally
- **2D pipeline:** Dedicated, pixel-perfect, not bolted onto a 3D engine
- **Claude Code compatibility:** Works well with GDScript and C#

## Rejected Options

| Engine | Reason Rejected |
|---|---|
| Unity | Licensing uncertainty, 3D-first architecture, runtime fee risk |
| Phaser (JS) | Framework not engine, no visual editor, Electron packaging friction, weak for simulation scope |

## Setup Notes

- Download: https://godotengine.org/
- Version to use: Godot 4.x (latest stable)
- Project structure: Use Godot's built-in scene/node system — each station module, character, and UI element as its own scene
