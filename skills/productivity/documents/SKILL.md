---
name: documents
description: "Document handling: PDF extraction (OCR, text), editing, and format conversion."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [PDF, Documents, OCR, Text-Extraction, Editing, Productivity]
    related_skills: [powerpoint, research]
---

# Documents

PDF extraction, editing, and format conversion. Covers text extraction, OCR for scanned documents, and natural-language PDF editing.

For PowerPoint: see the `powerpoint` skill (uses python-pptx).
For Word docs: `pip install python-docx` (parses actual structure, better than OCR).

---

## §1 — PDF Text Extraction

### Step 1: Remote URL? Use web_extract First

```
web_extract(urls=["https://arxiv.org/pdf/2402.03300"])
web_extract(urls=["https://example.com/report.pdf"])
```

Handles PDF-to-markdown via Firecrawl with no local dependencies. Only use local extraction when: file is local, web_extract fails, or batch processing needed.

### Step 2: Choose Local Extractor

| Feature | pymupdf (~25MB) | marker-pdf (~3-5GB) |
|---------|-----------------|---------------------|
| Text-based PDF | ✅ | ✅ |
| Scanned PDF (OCR) | ❌ | ✅ (90+ languages) |
| Tables | ✅ (basic) | ✅ (high accuracy) |
| Equations / LaTeX | ❌ | ✅ |
| Code blocks | ❌ | ✅ |
| Headers/footers removal | ❌ | ✅ |
| Images extraction | ✅ (embedded) | ✅ (with context) |
| Speed | Instant | ~1-14s/page (CPU) |
| Install size | ~25MB | ~3-5GB (PyTorch) |

**Decision:** Use pymupdf unless you need OCR, equations, forms, or complex layout analysis.

### pymupdf (lightweight)

```bash
pip install pymupdf pymupdf4llm
```

```bash
python scripts/extract_pymupdf.py document.pdf              # Plain text
python scripts/extract_pymupdf.py document.pdf --markdown    # Markdown
python scripts/extract_pymupdf.py document.pdf --tables      # Tables
python scripts/extract_pymupdf.py document.pdf --images out/ # Extract images
python scripts/extract_pymupdf.py document.pdf --metadata    # Title, author, pages
python scripts/extract_pymupdf.py document.pdf --pages 0-4   # Specific pages
```

### marker-pdf (high-quality OCR)

```bash
pip install marker-pdf
```

```bash
python scripts/extract_marker.py document.pdf                # Markdown
python scripts/extract_marker.py document.pdf --json         # JSON with metadata
python scripts/extract_marker.py scanned.pdf                 # Scanned PDF (OCR)
python scripts/extract_marker.py document.pdf --use_llm      # LLM-boosted accuracy
```

CLI: `marker_single document.pdf --output_dir ./output`

### Split, Merge & Search (pymupdf)

```python
# Split: extract pages 1-5
import pymupdf
doc = pymupdf.open("report.pdf")
new = pymupdf.open()
for i in range(5):
    new.insert_pdf(doc, from_page=i, to_page=i)
new.save("pages_1-5.pdf")

# Merge multiple PDFs
result = pymupdf.open()
for path in ["a.pdf", "b.pdf", "c.pdf"]:
    result.insert_pdf(pymupdf.open(path))
result.save("merged.pdf")

# Search for text
doc = pymupdf.open("report.pdf")
for i, page in enumerate(doc):
    results = page.search_for("revenue")
    if results:
        print(f"Page {i+1}: {len(results)} match(es)")
```

---

## §2 — PDF Editing (nano-pdf)

Edit PDFs using natural-language instructions.

### Prerequisites

```bash
uv pip install nano-pdf
```

### Usage

```bash
nano-pdf edit <file.pdf> <page_number> "<instruction>"
```

### Examples

```bash
nano-pdf edit deck.pdf 1 "Change the title to 'Q3 Results' and fix the typo"
nano-pdf edit report.pdf 3 "Update the date from January to February 2026"
nano-pdf edit contract.pdf 2 "Change client name from 'Acme Corp' to 'Acme Industries'"
```

### Notes

- Page numbers may be 0-based or 1-based — retry with ±1 if wrong page
- Uses an LLM under the hood — requires API key
- Works well for text changes; complex layout needs different approach
- Always verify the output PDF after editing
