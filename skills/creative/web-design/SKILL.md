---
name: web-design
description: "Web/UI design: process, design systems, token specs, and rapid prototyping."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [design, html, css, ui, ux, prototype, design-system, tokens, mockup, web-development]
    related_skills: [excalidraw, architecture-diagram]
---

# Web Design

Four complementary skills for web/UI design work. Load the right one (or combine them) based on what the user needs.

## Quick Decision

| User wants... | Load | What it gives you |
|---|---|---|
| A from-scratch designed artifact (landing, prototype, deck) | §1 — Design Process | How to scope a brief, produce variants, avoid AI slop |
| A page styled after a known brand (Stripe, Linear, Vercel) | §2 — Design Systems | 54 ready-to-paste design systems with exact CSS values |
| A formal, machine-readable design token spec file | §3 — DESIGN.md Tokens | Google's DESIGN.md spec format for persistent token files |
| Quick visual exploration before committing | §4 — Sketch | 2-3 throwaway HTML mockups to compare directions |

**These compose:** Use §2 for the visual vocabulary, §1 for the design process, §3 when the output is a token file, and §4 for early exploration.

---

## §1 — Design Process (claude-design)

Design one-off HTML artifacts with genuine design quality. Covers landing pages, prototypes, decks, component explorations, and motion studies.

### Core Principles

- **Start from context, not vibes** — look for brand docs, screenshots, repo components, design tokens before inventing
- **Three variants minimum** — Conservative, Strong-fit, Divergent
- **Anti-slop rules** — no aggressive gradients, glassmorphism by default, generic SaaS cards, fake dashboards, rainbow palettes
- **Content discipline** — no filler content, fake metrics, or placeholder testimonials

### Workflow

1. **Understand the brief** — what, who, what artifact, what constraints
2. **Gather context** — read supplied docs, screenshots, repo files
3. **Define the design system** — colors, type, spacing, radii, shadows, motion
4. **Choose format** — static comparison, clickable prototype, slide deck, component lab
5. **Build** — single self-contained HTML file, embedded CSS/JS
6. **Verify** — confirm file exists, check syntax, inspect in browser if possible

### Artifact Rules

- Default: self-contained HTML with embedded `<style>` and `<script>`
- Responsive unless intentionally fixed-size
- Preserve previous versions for major revisions
- Mobile hit targets: minimum 44px
- Slide decks: 1920×1080, keyboard navigation, visible slide count

### Typography

- Editorial: serif or humanist headline + restrained sans body
- Software/product: precise sans with strong numeric treatment
- Deck: large, clear, high contrast
- Use type as hierarchy before adding boxes, icons, or color

### Color

- Define a small system: neutrals, surface, ink, muted text, border, accent
- One primary accent unless the assignment calls for more
- Prefer oklch for harmonious invented palettes
- Check contrast for important text

---

## §2 — Design Systems (popular-web-designs)

54 real-world design systems ready for use. Each captures a site's complete visual language: colors, typography, components, spacing, shadows.

### Using a Template

```
skill_view(name="web-design", file_path="templates/<site>.md")
```

### Design Catalog

**AI & ML:** claude, cohere, elevenlabs, minimax, mistral.ai, ollama, opencode.ai, replicate, runwayml, together.ai, voltagent, x.ai

**Developer Tools:** cursor, expo, linear.app, lovable, mintlify, posthog, raycast, resend, sentry, supabase, superhuman, vercel, warp, zapier

**Infrastructure:** clickhouse, composio, hashicorp, mongodb, sanity, stripe

**Design & Productivity:** airtable, cal, clay, figma, framer, intercom, miro, notion, pinterest, webflow

**Fintech:** coinbase, kraken, revolut, wise

**Enterprise & Consumer:** airbnb, apple, bmw, ibm, nvidia, spacex, spotify, uber

### Font Substitution

| Proprietary | CDN Substitute | Character |
|---|---|---|
| Geist | Geist (Google Fonts) | Geometric, compressed |
| sohne-var (Stripe) | Source Sans 3 | Light elegance |
| Circular (Spotify) | DM Sans | Geometric, warm |
| Airbnb Cereal | DM Sans | Rounded, friendly |

### Choosing a Design

- **Developer tools:** Linear, Vercel, Supabase, Raycast, Sentry
- **Documentation:** Mintlify, Notion, Sanity, MongoDB
- **Marketing:** Stripe, Framer, Apple, SpaceX
- **Dark mode:** Linear, Cursor, ElevenLabs, Warp
- **Playful:** PostHog, Figma, Lovable, Zapier, Miro
- **Premium:** Apple, BMW, Stripe, Superhuman, Revolut

---

## §3 — DESIGN.md Tokens (design-md)

Google's open spec for describing a visual identity to coding agents. YAML front matter (tokens) + markdown body (rationale).

### File Anatomy

```md
---
version: alpha
name: Heritage
colors:
  primary: "#1A1C1E"
  secondary: "#6C7278"
  tertiary: "#B8422E"
typography:
  h1:
    fontFamily: Public Sans
    fontSize: 3rem
    fontWeight: 700
rounded:
  sm: 4px
  md: 8px
components:
  button-primary:
    backgroundColor: "{colors.tertiary}"
    textColor: "#FFFFFF"
---

## Overview
Architectural Minimalism meets Journalistic Gravitas...

## Colors
- **Primary (#1A1C1E):** Deep ink for headlines...
```

### Token Types

| Type | Format | Example |
|------|--------|---------|
| Color | `#` + hex | `"#1A1C1E"` |
| Dimension | number + unit | `48px`, `-0.02em` |
| Reference | `{path.to.token}` | `{colors.primary}` |

### CLI Commands

```bash
npx -y @google/design.md lint DESIGN.md           # Validate + WCAG contrast
npx -y @google/design.md diff DESIGN.md v2.md     # Compare versions
npx -y @google/design.md export --format tailwind DESIGN.md  # Tailwind JSON
npx -y @google/design.md export --format dtcg DESIGN.md      # W3C DTCG JSON
```

### Pitfalls

- Don't nest component variants: `button-primary-hover` as sibling, not `button-primary.hover`
- Hex colors must be quoted strings
- Negative dimensions need quotes: `letterSpacing: "-0.02em"`
- Section order is enforced (Overview → Colors → Typography → Layout → Elevation → Shapes → Components → Do's/Don'ts)

---

## §4 — Sketch (Rapid Prototyping)

Throwaway HTML mockups: 2-3 design variants to compare before committing to a direction.

### When to Use

- "Sketch this screen"
- "Show me what X could look like"
- "Compare layout A vs B"
- "Give me 2-3 takes on this UI"
- "Mockup this before I build"

### When NOT to Use

- User wants a shippable artifact → §1 Design Process
- User already knows the direction → just build it
- Pure data/table layout → not a design problem

### Workflow

1. **Understand the constraint** — what must be on screen, what's flexible
2. **Generate 2-3 variants** — different layout, hierarchy, or visual treatment
3. **Each variant is a self-contained HTML file** — no build step, openable in browser
4. **Present side by side** — let the user compare and pick
5. **Discard the losers** — the chosen direction informs the real implementation

### Variant Guidelines

- Each variant should be meaningfully different, not just color swaps
- Explore: layout (grid vs list vs card), hierarchy (what's prominent), density (sparse vs data-dense)
- Use real-ish content, not "Lorem ipsum"
- Include at least one unexpected direction the user might not have considered

### Output

```
Created 3 variants:
- /tmp/sketch-variant-a.html — Sidebar navigation, card grid content
- /tmp/sketch-variant-b.html — Top nav, list view with filters
- /tmp/sketch-variant-c.html — Command palette driven, minimal chrome

Pick a direction and I'll build the real version.
```
