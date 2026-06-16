---
name: ai-music
description: "AI music generation: songwriting craft, Suno prompts, and HeartMuLa open-source generation."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [music, audio, songwriting, suno, heartmula, lyrics, generation, ai]
    related_skills: [songsee]
---

# AI Music Generation

Two approaches to AI music: craft-based (Suno prompts) and open-source (HeartMuLa).

For audio analysis/spectrograms, see the `songsee` skill.

---

## §1 — Songwriting Craft & Suno Prompts

Everything here is a GUIDELINE, not a rule. Art breaks rules on purpose.

### Song Structure

```
ABABCB  Verse/Chorus/Verse/Chorus/Bridge/Chorus    (most pop/rock)
AABA    Verse/Verse/Bridge/Verse                    (jazz standards, ballads)
AAA     Verse/Verse/Verse (strophic, no chorus)     (folk, storytelling)
```

Building blocks: Intro, Verse, Pre-Chorus, Chorus, Bridge, Outro. You don't need all of them.

### Rhyme, Meter, and Sound

- Mix rhyme types: perfect, family, assonance, consonance, near/slant
- Internal rhyme: rhyming within a line, not just at ends
- Meter: matching stressed syllables matters more than total count
- Say it out loud. If you stumble, the meter needs work.

### Emotional Arc

```
Intro: 2-3  |  Verse: 5-6  |  Pre-Chorus: 7
Chorus: 8-9  |  Bridge: varies  |  Final Chorus: 9-10
```

The most powerful trick: CONTRAST. Whisper before a scream. Sparse before dense.

### Writing Lyrics

- **Show, don't tell:** "Your hoodie's still on the hook by the door" > "I was sad"
- **The hook:** the line people remember. Place it where it lands hardest.
- **Prosody:** stable feelings → settled melodies, perfect rhymes. Unstable → wandering melodies, near-rhymes.

### Parody and Adaptation

1. Map original structure: syllables per line, rhyme scheme, stressed syllables
2. Match stressed syllables to same beats
3. On held notes, match the VOWEL SOUND
4. Monosyllabic swaps in hooks keep rhythm intact
5. Keep some original lines for recognizability

### Suno Prompt Engineering

**Style field formula:** Genre + Mood + Era + Instruments + Vocal Style + Production + Dynamics

```
BAD:  "sad rock song"
GOOD: "Cinematic orchestral spy thriller, 1960s Cold War era, smoky
       sultry female vocalist, big band jazz, brass section with
       trumpets and french horns, sweeping strings, minor key"
```

Describe the JOURNEY, not just the genre.

**Metatags** (in lyrics field):
- Structure: `[Intro]` `[Verse]` `[Chorus]` `[Bridge]` `[Outro]`
- Vocal: `[Whispered]` `[Belted]` `[Falsetto]` `[Powerful]`
- Dynamics: `[High Energy]` `[Building Energy]` `[Explosive]`
- Gender: `[Female Vocals]` `[Male Vocals]`

### Phonetic Tricks for AI Singers

- Spell as they SOUND: "through" → "thru"
- "Nous" → "Noose" (forces correct pronunciation)
- ALL CAPS = louder. Vowel extension: "lo-o-o-ove" = sustained
- Spell out numbers: "24/7" → "twenty four seven"
- Space acronyms: "AI" → "A I"

### Workflow

1. Write concept/hook — what's the emotional core?
2. If adapting, map original structure
3. Generate raw material — brainstorm freely
4. Draft lyrics into structure
5. Read/sing aloud — catch stumbles
6. Build Suno style description — paint the dynamic journey
7. Add metatags for performance direction
8. Generate 3-5 variations minimum

Expect ~3-5 generations per 1 good result.

---

## §2 — HeartMuLa (Open-Source Music Generation)

Open-source music foundation model (Apache-2.0) that generates full songs from lyrics + tags. Comparable to Suno.

### Hardware Requirements

- **Minimum:** 8GB VRAM with `--lazy_load true`
- **Recommended:** 16GB+ VRAM
- **No GPU?** CPU mode works but extremely slow (30-60+ minutes per song)

### Installation

```bash
cd ~/
git clone https://github.com/HeartMuLa/heartlib.git
cd heartlib
uv venv --python 3.10 .venv
. .venv/bin/activate
uv pip install -e .
uv pip install --upgrade datasets transformers  # fix dependency conflicts
```

**Required patches** (as of Feb 2026):

1. In `modeling_heartmula.py`, add RoPE reinitialization after `reset_caches` in `setup_caches`
2. In `music_generation.py`, add `ignore_mismatched_sizes=True` to all `HeartCodec.from_pretrained()` calls

### Download Models

```bash
hf download --local-dir './ckpt' 'HeartMuLa/HeartMuLaGen'
hf download --local-dir './ckpt/HeartMuLa-oss-3B' 'HeartMuLa/HeartMuLa-oss-3B-happy-new-year'
hf download --local-dir './ckpt/HeartCodec-oss' 'HeartMuLa/HeartCodec-oss-20260123'
```

### Generation

```bash
python ./examples/run_music_generation.py \
  --model_path=./ckpt \
  --version="3B" \
  --lyrics="./assets/lyrics.txt" \
  --tags="./assets/tags.txt" \
  --save_path="./assets/output.mp3" \
  --lazy_load true
```

**Tags** (comma-separated): `piano,happy,wedding,synthesizer,romantic`

**Lyrics** (bracketed structural tags):
```
[Intro]
[Verse]
Your lyrics here...
[Chorus]
Chorus lyrics...
```

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--max_audio_length_ms` | 240000 | Max length (240s = 4 min) |
| `--lazy_load` | false | Load/unload models on demand (saves VRAM) |
| `--mula_dtype` | bfloat16 | bf16 recommended for MuLa |
| `--codec_dtype` | float32 | fp32 for HeartCodec (bf16 degrades quality) |

### Pitfalls

- Do NOT use bf16 for HeartCodec — degrades audio quality
- Tags may be ignored (known issue) — lyrics tend to dominate
- Triton not available on macOS — Linux/CUDA only
- RTF ≈ 1.0 — 4-minute song takes ~4 minutes to generate
