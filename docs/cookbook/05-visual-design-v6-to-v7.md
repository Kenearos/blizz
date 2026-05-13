# Visual design: from v6 to v7

The v6 "Cyan Cyber Tactical" theme that Blizz currently ships is intentionally distinct from the warm-gold streamer aesthetic that dominates Kira, Quazii, Naowh, and most top Plater profiles. This chapter documents the v6 system and lays out v7 — a curated expansion drawn from sci-fi game UIs, tactical-combat HUDs, and terminal dashboards.

## v6 — current shipping theme

The mockup is at [`docs/superpowers/mockups/style-v6.html`](../superpowers/mockups/style-v6.html). The full token table lives in [`ui/theme.lua`](../../ui/theme.lua).

**Identity:** "Information dense, machined, hostile to ornament."

**Palette:**
| Token | Hex | Role |
|---|---|---|
| `bg_primary` | `#02060f` | Frame background |
| `primary` | `#7ed9ff` | Default border/text |
| `primary_hi` | `#d4eef9` | Outer-ring on ready states |
| `alert` | `#ff2966` | Reflect/Aggro-lost alert |
| `info` | `#f0f0f0` | M+/Affix/Kick header text |
| `caster` | `#ff5dc8` | Nameplate kick-priority |
| `frontal` | `#4de0c8` | Nameplate frontal-cone |
| `healer` | `#c5ff2e` | Nameplate priority-kill |
| `cd_border` / `cd_text` | `#2a3a4a` / `#5a7080` | Cooldown state |

**Typography:** JetBrains Mono Bold (bundled, OFL-licensed). Weights 600-900 by element. Uppercase + letter-spacing 0.5-3px.

**Form vocabulary:**
- Hard 1.5px borders, **no border-radius** (4px on container shells only)
- **Color-inversion for ready states** — filled fill + dark text, not outline + light text
- Outer rings (1.5px in `primary_hi`) on ready states as visual "stamps"
- Inset-top-highlight (1px translucent white) for subtle depth
- Subtle text-shadow + box-shadow on ready/alert — no neon bleed
- Reflect-Alert uses clip-path parallelogram (hazard-sign feel)
- L-shaped tech-corner-brackets (`::before` / `::after`) on framed widgets
- Repeating-linear-gradient scanlines (~4.5% opacity)
- Pulse animation 0.9s ease-in-out: background-saturation change + scale 1.0→1.04

**What v6 deliberately is not:**
- Not warm (no gold/amber — that's Quazii/Kira/Method territory)
- Not rounded (no soft pills — that's Linear/Apple territory)
- Not noisy (no rainbow neons — that's Vegas casino UI)
- Not 3D (no glossy buttons — that's Aero/Win10 era)

## v7 — moodboard and expansion

The goal of v7 is to **push identity** further without sacrificing combat readability. The pattern catalog below was synthesized from a deep-dive across game UIs, sci-fi cinema, and terminal dashboards.

### Reference sources

| Domain | Reference | What we steal |
|---|---|---|
| Game UI | Cyberpunk 2077 (Quickhack/Scanner) | Diagonal frame cuts, segmented progress pips, glitch decals |
| Game UI | Deus Ex: Mankind Divided (Augmentations) | ID-code strips per frame, 0.5px connector hairlines |
| Game UI | Helldivers 2 (Stratagem Wheel) | Vertical hatch-strip as frame-side decorator |
| Game UI | Death Stranding (Cargo/Tactical Map) | Fake-telemetry footer strip, geo-coord atmosphere |
| Game UI | Star Citizen MFD | Chromatic-aberration on alert pulse, target-brackets |
| Game UI | Detroit: Become Human | Typewriter-reveal on combat-enter |
| Game UI | Control | Redacted-bar on disabled slots, `MASA-1934`-style identifiers |
| Game UI | ARMA 3 / Squad / Ready or Not | 8-point compass strip, status stamps |
| Cinema | The Expanse (Territory Studio) | Numeric+bar redundancy, 8px-grid snap |
| Cinema | Blade Runner 2049 | Optional CRT-curvature, noise-texture overlay |
| Cinema | Mr. Robot | Prefix glyphs `[+] [!] [~] [·]` for state |
| Cinema | Westworld | Mega-spaced section headers (`M · I · T · I · G · A · T · I · O · N`) |
| Web/Term | btop / k9s | ANSI box-drawing headers, sparklines from Unicode blocks |
| Web/Term | Linear / Tailscale | Edge-fade gradients, status-pip system |
| Web/Term | Datadog / Grafana | Threshold-coloring on values, heatmap cells |

### Concrete v7 pattern catalog

Ranked by identity impact ÷ readability cost. Highest first.

#### Tier 1 — Identity-Core (essentials, no animation overhead)

**1. Vertical hatch-strip (left side, 6px wide, 45° diagonal lines)**

Source: Helldivers 2 Stratagem-card decorator.
Implementation: Single 6×64 tiled texture file. `Texture:SetTexture("Interface\\AddOns\\Blizz\\textures\\hatch.tga")`, `SetVertexColor` to theme primary at 35% alpha.
Readability impact: neutral (peripheral). Identity impact: massive.

**2. ID-code strip per frame** — `[ MIT-01 ]`, `[ RFL-02 ]`, `[ CDS-03 ]`

Source: Deus Ex MD + The Expanse Roci consoles.
Implementation: JetBrains Mono 9px uppercase FontString at 60% alpha, top-left anchored.
Readability impact: neutral. Identity impact: establishes "machined precision."

**3. Status-pip system** — 4×4px dot in top-right of every frame, color-encoded

Source: Tailscale Admin + Roci MFD displays.
States: ready (primary), casting (frontal/teal), alert (red), idle (cd_text dim).
Implementation: 1 texture per frame, `SetVertexColor` swaps the color.
Readability impact: strong positive — centralizes status reading to one pixel region per frame.

**4. ANSI box-drawing header** — `┌─[ MITIGATION ]─────────────┐`

Source: btop / k9s terminal dashboards.
Implementation: FontString with Unicode box-drawing characters. JetBrains Mono renders all of them pixel-perfect.
Readability impact: positive — header hierarchy is unambiguous.

#### Tier 2 — Geometry pass

**5. Diagonal frame corner cuts** (top-left + bottom-right at 45°, ~8px)

Source: Cyberpunk 2077 mission-ready UI.
Implementation: Two 8×8 black triangle textures as corner masks, or border drawn as four line segments instead of one rectangle.
Readability impact: positive — asymmetry makes frames orientable at a glance.

**6. Segmented CD bar** (8-12 pips instead of smooth fill)

Source: Cyberpunk 2077 + Expanse Roci.
Implementation: Pip = 1 texture, replicated. Per frame: `for i = 1, 12 do pip[i]:SetAlpha(i <= count and 1 or 0.2) end`.
Readability impact: strong positive — Helldivers' research shows segmented bars are ~80ms faster to read at a glance than smooth fills.

**7. Mega-spaced section headers** — `M · I · T · I · G · A · T · I · O · N`

Source: Westworld + brutalist web design.
Implementation: One FontString per character with fixed x-offset, or single FontString with character padding hack.
Readability impact: neutral. Editorial-grade identity.

#### Tier 3 — Atmospheric / Animated (with settings toggles)

**8. Scanline-sweep animation on defensive-ready**

Source: Star Citizen MFD + Death Stranding interfaces.
Implementation: 1px bright line traveling top-to-bottom over the frame in 200ms when a CD finishes. `Texture:SetGradient` with animated `SetTexCoord` Y-shift via `OnUpdate`.
Readability impact: positive — three combined signals (glow + sweep + color-inversion) make "ready" unmistakable. Cap duration at 200ms to avoid clutter.

**9. Chromatic-aberration on alert pulse**

Source: Star Citizen + Blade Runner 2049.
Implementation: Two additional FontStrings at 40% alpha, position-offset by ±1px in cyan/magenta. Active only during first 200ms of an alert.
Readability impact: neutral. Communicates "system stress" semantically without permanent eye-strain.

**10. Fake-telemetry footer strip** — 10px high under combat frame: `T+02:18 · DTPS 84k · TGT 04 · IRQ 0`

Source: Death Stranding + The Expanse Roci dashboards.
Implementation: One FontString refreshed every 0.5s via OnUpdate. Mostly cosmetic; partial real values (combat timer, DTPS calc, current target count).
Readability impact: neutral peripheral. Off-toggle for combat hardliners.

**11. Sparkline DTPS** under tank frame — 8 Unicode blocks `▁▂▃▄▅▆▇█` showing last 8 damage buckets

Source: btop + Grafana.
Implementation: FontString updated 4Hz, tail damage history array, map to 1-8 height tier.
Readability impact: strong positive — trend detection in peripheral vision without bar-chart overhead.

#### Tier 4 — Polish / Niche

**12. Side-slash decorations** — `///` as module-group separators

Source: eSports broadcast overlays.
Implementation: FontString `/// ///` italic, primary at 25% alpha.
Readability impact: neutral. Pure deco.

**13. Holographic-flicker on alert pulse** (frame alpha briefly 0.4 → 1.0 → 0.7 → 1.0 in 120ms)

Source: Star Citizen + Cyberpunk Quickhack.
Implementation: SetAlpha tween via AnimationGroup.
Readability impact: warning — flicker can cause eye-strain. Only on Reflect-critical alerts, max 1× per alert.

**14. Redacted-bar on disabled slots** — black 50%-alpha bar + diagonal white hatches

Source: Control + Mr. Robot.
Implementation: Texture-overlay activated via `frame:SetEnabled(false)`.
Readability impact: strong positive — disabled state reads instantly, not just "dim."

**15. Status stamps** — `// COOLDOWN`, `// ARMED` rotated 5°

Source: Ready or Not + Control briefings.
Implementation: FontString with `SetRotation(0.087)`. All other elements remain orthogonal, so the stamp pops out.
Readability impact: neutral. Identity-strong but use sparingly (1 per frame max).

## Anti-patterns — what NOT to take

- **Cyberpunk 2077 cluttered-HUD-mode** — too much info per square millimeter, unreadable under raid stress
- **Death Stranding maximal whitespace** — WoW needs density
- **Westworld blueprint connector-lines across the whole screen** — would collide with nameplates
- **CRT curvature in default** — eye-fatigue over 60-minute sessions. Toggle-only.
- **Permanent animation** (rotating sweeps, idle pulses) during combat — costs attention. Animation only as state-change signal.

## v7 rollout roadmap

**v7.0 — Identity-Core (essentials, low-risk):**
- #1 hatch-strip, #2 ID-codes, #3 status-pips, #4 ANSI headers
- These four alone establish "machined cyberpunk tactical" unmistakably without a single animation loop.

**v7.1 — Geometry pass:**
- #5 diagonal corner cuts, #6 segmented CD bars, #7 mega-spaced headers
- Frame-shape and bar-reading-speed gains.

**v7.2 — Atmospheric & animated (every toggle off-default):**
- #8 scanline sweep, #9 chromatic-aberration, #10 telemetry footer, #11 sparkline DTPS
- All as settings-toggles with "combat hardline mode" disabling them.

**v7.3 — Polish/niche:**
- #12 slash decorations, #13 holo-flicker, #14 redacted bars, #15 status stamps

## Token additions for `ui/theme.lua`

Suggested additions (purely additive, won't break v6 consumers):

```lua
Theme.colors.hatch       = { 0.494, 0.851, 1.000, 0.35 } -- primary @ 35%
Theme.colors.id_label    = { 0.494, 0.851, 1.000, 0.60 }
Theme.colors.pip_ready   = { 0.494, 0.851, 1.000, 1.00 }
Theme.colors.pip_cast    = { 0.302, 0.878, 0.784, 1.00 } -- = frontal
Theme.colors.pip_alert   = { 1.000, 0.161, 0.400, 1.00 } -- = alert
Theme.colors.pip_idle    = { 0.353, 0.439, 0.502, 0.40 }
Theme.colors.telemetry   = { 0.353, 0.439, 0.502, 0.70 }
Theme.colors.chrom_cyan  = { 0.494, 0.851, 1.000, 0.40 }
Theme.colors.chrom_mag   = { 1.000, 0.365, 0.784, 0.40 }

Theme.layout.hatch_strip_w     = 6
Theme.layout.id_label_offset_y = -2
Theme.layout.pip_size          = 4
Theme.layout.corner_cut_size   = 8
Theme.layout.segment_count_cd  = 12
```

## Why bother with v7?

A counter-argument: combat-readable, working UI is more important than aesthetic distinction. True. But:

1. **Distinct visual identity is how addons get discovered.** Wago listing screenshots are the discovery vector. v6 already differs from the gold-streamer consensus; v7 makes it unmistakable.
2. **Every Tier-1 v7 addition is also a readability gain.** Status-pips centralize status. ID-codes label frames so users learn the system faster. Segmented bars are quantifiably faster to parse.
3. **The expensive parts (animations, atmospheric strips) are all toggle-off** by default. The base look gets sharper; the optional layer can be added per user taste.

The cost is meaningful (Tier-1 alone is ~150 lines of Lua + 2 small texture files). The reward is the addon being recognizable from across the screen — and an aesthetic worth screenshotting.
