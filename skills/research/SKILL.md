---
name: research
description: "Academic research: paper discovery, citation analysis, knowledge base management, and paper writing."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Research, Papers, Arxiv, Academic, Wiki, Knowledge-Base, Citations, Paper-Writing, NeurIPS, ICML]
    related_skills: [ocr-and-documents, writing-plans]
---

# Research

End-to-end academic research workflow: discover papers, build knowledge bases, and write publication-ready papers.

---

## §1 — Paper Discovery (arxiv + Semantic Scholar)

Search and retrieve academic papers from arXiv and Semantic Scholar.

### arXiv Search

```bash
curl -s "https://export.arxiv.org/api/query?search_query=all:QUERY&max_results=5"
```

Helper script (no dependencies):
```bash
python scripts/search_arxiv.py "GRPO reinforcement learning"
python scripts/search_arxiv.py --author "Yann LeCun" --max 5
python scripts/search_arxiv.py --category cs.AI --sort date
python scripts/search_arxiv.py --id 2402.03300
```

### Search Query Syntax

| Prefix | Searches | Example |
|--------|----------|---------|
| `all:` | All fields | `all:transformer+attention` |
| `ti:` | Title | `ti:large+language+models` |
| `au:` | Author | `au:vaswani` |
| `cat:` | Category | `cat:cs.AI` |

Boolean: `AND` (default), `OR`, `ANDNOT`. Exact phrase: `ti:"chain+of+thought"`

### Semantic Scholar (Citations, Related Papers)

```bash
# Paper details + citations
curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:2402.03300?fields=title,authors,citationCount"

# Citations OF a paper
curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:2402.03300/citations?fields=title,authors,year&limit=10"

# References FROM a paper
curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:2402.03300/references?fields=title,citationCount&limit=10"

# Search (JSON alternative to arXiv)
curl -s "https://api.semanticscholar.org/graph/v1/paper/search?query=GRPO&limit=5&fields=title,citationCount"

# Recommendations
curl -s -X POST "https://api.semanticscholar.org/recommendations/v1/papers/" \
  -H "Content-Type: application/json" \
  -d '{"positivePaperIds": ["arXiv:2402.03300"], "negativePaperIds": []}'
```

### Reading Papers

```
# Abstract (fast)
web_extract(urls=["https://arxiv.org/abs/2402.03300"])

# Full paper (PDF → markdown)
web_extract(urls=["https://arxiv.org/pdf/2402.03300"])
```

### BibTeX Generation

```bash
curl -s "https://export.arxiv.org/api/query?id_list=1706.03762" | python3 -c "
import sys, xml.etree.ElementTree as ET
ns = {'a': 'http://www.w3.org/2005/Atom', 'arxiv': 'http://arxiv.org/schemas/atom'}
root = ET.parse(sys.stdin).getroot()
entry = root.find('a:entry', ns)
title = entry.find('a:title', ns).text.strip().replace('\n', ' ')
authors = ' and '.join(a.find('a:name', ns).text for a in entry.findall('a:author', ns))
year = entry.find('a:published', ns).text[:4]
raw_id = entry.find('a:id', ns).text.strip().split('/abs/')[-1]
cat = entry.find('arxiv:primary_category', ns)
primary = cat.get('term') if cat is not None else 'cs.LG'
last_name = entry.find('a:author', ns).find('a:name', ns).text.split()[-1]
print(f'@article{{{last_name}{year}_{raw_id.replace(\".\", \"\")},')
print(f'  title     = {{{title}}},')
print(f'  author    = {{{authors}}},')
print(f'  year      = {{{year}}},')
print(f'  eprint    = {{{raw_id}}},')
print(f'  archivePrefix = {{arXiv}},')
print(f'  primaryClass  = {{{primary}}}')
print('}')
"
```

### Common Categories

| Category | Field |
|----------|-------|
| `cs.AI` | Artificial Intelligence |
| `cs.CL` | NLP / Computation and Language |
| `cs.CV` | Computer Vision |
| `cs.LG` | Machine Learning |
| `stat.ML` | ML (Statistics) |

### Complete Research Workflow

1. **Discover**: search arXiv by topic
2. **Assess impact**: check citation count on Semantic Scholar
3. **Read**: abstract first, then full paper
4. **Find related work**: Semantic Scholar references endpoint
5. **Get recommendations**: positive/negative paper IDs

Rate limits: arXiv ~1 req/3s, Semantic Scholar 1 req/s (100/s with API key).

---

## §2 — Knowledge Base (LLM Wiki)

Build and maintain a persistent, compounding knowledge base as interlinked markdown files. Based on Karpathy's LLM Wiki pattern.

Unlike traditional RAG (rediscovers knowledge per query), the wiki compiles knowledge once and keeps it current.

### Wiki Structure

```
wiki/
├── SCHEMA.md           # Conventions, tag taxonomy
├── index.md            # Content catalog with summaries
├── log.md              # Chronological action log
├── raw/                # Layer 1: Immutable source material
│   ├── articles/
│   ├── papers/
│   └── transcripts/
├── entities/           # Layer 2: Entity pages
├── concepts/           # Layer 2: Concept pages
├── comparisons/        # Layer 2: Side-by-side analyses
└── queries/            # Layer 2: Filed query results
```

### Session Start (always do this first)

```bash
WIKI="${WIKI_PATH:-$HOME/wiki}"
read_file "$WIKI/SCHEMA.md"
read_file "$WIKI/index.md"
read_file "$WIKI/log.md"  # last 20-30 entries
```

### Ingesting a Source

1. **Capture raw**: URL → `web_extract` → save to `raw/articles/`. Add frontmatter with `sha256`.
2. **Check existing**: search index.md and `search_files` for mentioned entities
3. **Write/update pages**: new entities if they meet thresholds (2+ source mentions or central to one source)
4. **Cross-reference**: every page must link to ≥2 other pages via `[[wikilinks]]`
5. **Update index.md and log.md**

### Querying

1. Read `index.md` for relevant pages
2. `search_files` across wiki `.md` files for key terms
3. Read relevant pages
4. Synthesize answer citing wiki pages: "Based on [[page-a]] and [[page-b]]..."
5. File valuable answers back to `queries/`

### Linting

Check for: orphan pages, broken wikilinks, index completeness, frontmatter validation, stale content, contradictions, page size (>200 lines = split candidate).

### Rules

- Never modify files in `raw/` — sources are immutable
- Always orient first (SCHEMA + index + log) before any operation
- Every page needs frontmatter, tags from taxonomy, and ≥2 cross-references
- Don't create pages for passing mentions

---

## §3 — Paper Writing Pipeline

End-to-end pipeline for producing publication-ready ML/AI research papers targeting NeurIPS, ICML, ICLR, ACL, AAAI, COLM.

### Pipeline Phases

```
PLAN → BASELINE → EXPERIMENTS → ANALYSIS → WRITE → REVIEW → SUBMIT
```

This is **iterative, not linear** — results trigger new experiments, reviews trigger new analysis.

### Phase 1: Planning & Literature Review

1. Search arXiv and Semantic Scholar for related work
2. Read 5-10 most relevant papers
3. Identify gap/novelty
4. Define research question and hypothesis
5. Design experiment plan with success criteria
6. Write `plan.md` with: question, hypothesis, methods, experiments, expected results

### Phase 2: Baseline & Setup

1. Set up project structure: `experiments/`, `results/`, `paper/`, `scripts/`
2. Implement baseline on a standard benchmark
3. Verify baseline matches published numbers (±2%)
4. If baseline doesn't match: debug before proceeding

### Phase 3: Experiments

1. Run ablation studies (one variable at a time)
2. Multiple seeds (3-5 minimum for statistical significance)
3. Log everything: W&B, TensorBoard, or CSV
4. Monitor for: convergence issues, overfitting, data leakage

### Phase 4: Statistical Analysis

```python
from scipy import stats
import numpy as np

# Compare two methods
t_stat, p_value = stats.ttest_ind(method_a_scores, method_b_scores)
print(f"t={t_stat:.3f}, p={p_value:.4f}")

# Effect size (Cohen's d)
d = (np.mean(method_a) - np.mean(method_b)) / np.sqrt((np.std(method_a)**2 + np.std(method_b)**2) / 2)
print(f"Cohen's d = {d:.3f}")

# Bootstrap confidence interval
bootstrap_means = [np.mean(np.random.choice(scores, len(scores), replace=True)) for _ in range(10000)]
ci = np.percentile(bootstrap_means, [2.5, 97.5])
```

### Phase 5: Writing

Standard ML paper structure:
1. **Abstract** (150-250 words): problem → method → results → impact
2. **Introduction** (1-1.5 pages): problem, motivation, contributions
3. **Related Work** (1-2 pages): positioned by contribution area
4. **Method** (2-4 pages): formal definition, algorithm, architecture
5. **Experiments** (2-3 pages): setup, baselines, results, ablations
6. **Conclusion** (0.5 pages): summary, limitations, future work

### Phase 6: Review & Revision

1. Self-review against conference checklist
2. Check: figures readable at print size? All claims supported? Limitations discussed?
3. Verify: all experiments reproducible? Code available? Hyperparameters documented?

### Key Principles

- **Baseline first** — verify you can reproduce existing work before claiming improvement
- **Ablate, don't just compare** — understand WHY your method works
- **Statistical rigor** — report confidence intervals, not just means
- **Reproducibility** — seed everything, document hyperparameters, release code
