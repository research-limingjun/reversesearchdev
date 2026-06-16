---
name: ascii-art
description: "ASCII art and video: text banners, image conversion, decorative borders, and video production."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [ASCII, Art, Video, Banners, Text-Art, pyfiglet, cowsay, boxes, creative]
    related_skills: [excalidraw]
---

# ASCII Art & Video

Static ASCII art (banners, image conversion, decorative text) and animated ASCII video production.

---

## §1 — Static ASCII Art

Multiple tools for different needs. All local CLI or free REST APIs — no API keys.

### Text Banners (pyfiglet — local)

```bash
pip install pyfiglet --break-system-packages -q
python3 -m pyfiglet "YOUR TEXT" -f slant
python3 -m pyfiglet "TEXT" -f doom -w 80
python3 -m pyfiglet --list_fonts  # 571 fonts
```

Recommended fonts: `slant` (clean), `doom` (blocky), `big` (readable), `cyberlarge` (cyberpunk), `3-d` (3D effect)

### Text Banners (asciified API — remote, no install)

```bash
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=Hello+World&font=Slant"
curl -s "https://asciified.thelicato.io/api/v2/fonts"  # list 250+ fonts
```

### Cowsay (Message Art)

```bash
sudo apt install cowsay -y  # or: brew install cowsay
cowsay "Hello World"
cowsay -f tux "Linux rules"
cowsay -f dragon "Rawr!"
cowthink "Hmm..."
```

### Boxes (Decorative Borders)

```bash
sudo apt install boxes -y  # or: brew install boxes
echo "Hello World" | boxes -d stone
echo "Hello World" | boxes -d parchment
echo "Hello World" | boxes -d cat
```

### Image to ASCII

```bash
# ascii-image-converter (recommended)
go install github.com/TheZoraiz/ascii-image-converter@latest
ascii-image-converter image.png -C -d 60,30

# jp2a (lightweight, JPEG only)
sudo apt install jp2a -y
jp2a --width=80 --colors image.jpg
```

### Pre-Made ASCII Art

Fetch from ascii.co.uk:
```bash
curl -s 'https://ascii.co.uk/art/cat' -o /tmp/ascii_art.html
# Extract from <pre> tags with Python
```

Subjects: cat, dog, dragon, rocket, guitar, computer, skull, robot, wizard, christmas, halloween

### Fun Utilities

```bash
curl -s "qrenco.de/Hello+World"     # QR code as ASCII
curl -s "wttr.in/London"            # Weather as ASCII art
```

### Decision Flow

1. Text as banner → pyfiglet (local) or asciified API (remote)
2. Wrap message in character art → cowsay
3. Decorative border → boxes
4. Specific thing (cat, rocket) → ascii.co.uk
5. Convert image → ascii-image-converter or jp2a
6. QR code → qrenco.de
7. Custom/creative → LLM generation with Unicode palette

---

## §2 — ASCII Video Production

Production pipeline for ASCII art video. Converts video/audio/images into colored ASCII character video output (MP4, GIF). No GPU required.

### Modes

| Mode | Input | Output |
|------|-------|--------|
| **Video-to-ASCII** | Video file | ASCII recreation of source |
| **Audio-reactive** | Audio file | Generative visuals driven by audio |
| **Generative** | None | Procedural ASCII animation |
| **Hybrid** | Video + audio | ASCII video with audio-reactive overlays |
| **Lyrics/text** | Audio + text | Timed text with visual effects |

### Pipeline

```
INPUT → ANALYZE → SCENE_FN → TONEMAP → SHADE → ENCODE
```

1. **INPUT** — Load/decode source material
2. **ANALYZE** — Extract per-frame features (audio bands, video luminance)
3. **SCENE_FN** — Scene function renders to pixel canvas
4. **TONEMAP** — Adaptive brightness normalization
5. **SHADE** — Post-processing via ShaderChain + FeedbackBuffer
6. **ENCODE** — Pipe raw frames to ffmpeg for H.264/GIF encoding

### Creative Standard

This is visual art. ASCII characters are the medium; cinema is the standard.

- **First-render excellence** — output must be visually striking without revision rounds
- **Per-section variation** — different background, palette, color, shader per scene
- **Dense, layered, considered** — every frame should reward viewing
- **Cohesive aesthetic** — all scenes connected by shared visual language

### Critical: Brightness

ASCII on black is inherently dark. **Never use `canvas * N` multipliers** — use adaptive tonemap:

```python
def tonemap(canvas, gamma=0.75):
    f = canvas.astype(np.float32)
    lo, hi = np.percentile(f[::4, ::4], [1, 99.5])
    if hi - lo < 10: hi = lo + 10
    f = np.clip((f - lo) / (hi - lo), 0, 1) ** gamma
    return (f * 255).astype(np.uint8)
```

### Stack

Python 3.10+, NumPy, SciPy (FFT), Pillow (font rendering), ffmpeg (encoding)

### References

The ASCII video skill has extensive reference files for advanced work:
- `references/architecture.md` — grid system, palettes, color system
- `references/effects.md` — effect building blocks, particles, transforms
- `references/shaders.md` — shader pipeline, transitions
- `references/scenes.md` — scene protocol, design patterns
- `references/composition.md` — blend modes, feedback, masking
- `references/inputs.md` — audio analysis, video sampling, TTS
- `references/optimization.md` — hardware detection, parallel rendering
- `references/troubleshooting.md` — common pitfalls
