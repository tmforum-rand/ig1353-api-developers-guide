## Executive Summary: `api` Node Consistency Across Rules Files

**Scope:** 86 rules files analyzed across 82 distinct APIs (some have multiple versioned sub-folders, e.g., TMF677 v5.0 and v5.1, TMF935 proper/DCS variants).

---

### `tmfId` — Highly Consistent ✅

All 86 files have a `tmfId` present. Every value matches the pattern `TMF` + 3–4 digits (e.g., `TMF620`, `TMF921`). All values are consistent with the parent folder and filename. This is the most reliable field across the corpus.

---

### `name` — Partially Consistent, Several Patterns in Conflict ⚠️

The majority of names follow Title Case with spaces, but there are significant exceptions:

| Pattern | Examples | Count |
|---|---|---|
| Title Case with spaces (canonical) | `Product Catalog Management`, `Alarm` | ~70 |
| CamelCase compound (no spaces) | `ProductOrdering`, `ServiceOrdering`, `ProductInventory`, `GeographicAddress`, `CustomerBill`, `Customer360`, `ProductConfiguration`, `PartnerBill` | 8 |
| Includes the word "API" | `Communication Management API`, `User Role Permission Management API`, `Digital Identity Management API`, `Incident Management API`, `Resource Role Management API`, `Open Gateway Operate API - Product Catalog` | 7 |
| Includes a hyphen/punctuation | `Open Gateway Operate API - Product Catalog` | 1 |

No clear rule governs whether to append "Management" (compare `Alarm` vs. `Alarm Management`; `Quote` vs. `Agreement Management`).

---

### `shortName` — Almost Always a Copy of `name`, Mostly Redundant ⚠️

82 of 86 files have `name == shortName` exactly. Only four files differentiate them:

| File | `name` | `shortName` |
|---|---|---|
| TMF724 | `Incident Management API` | `Incident` |
| TMF768 | `Resource Role Management API` | `Resource Role` |
| TMF935 (×2 variants) | `Wholesale Carrier Ethernet Proper` | `WholesaleCarrierEthernetProper` |

The TMF724 and TMF768 pattern (full descriptive name vs. concise label) is clearly the intent of the field. The TMF935 variant uses an undocumented camelCase convention for shortName.

---

### `description` — Highly Inconsistent, Multiple Quality Problems ❌

| Issue | Files Affected |
|---|---|
| **Copyright notice embedded** (`Copyright © TM Forum …`) | 15 |
| **Version/date embedded in prose** (`June 2023`, `Release: 5.0`, `Final: 5.0`) | 13 |
| **"Swagger UI environment generated for…" boilerplate** | 3 (TMF657, TMF685, TMF921) |
| **TODO/placeholder content** (`Work order description -> to be added`) | 1 (TMF697) |
| **Non-ASCII characters** (curly quotes `"`, en dash `–`, horizontal ellipsis `…`, `©`) | 20 |
| **Extremely short / stub** (< 60 chars, adding no value beyond the name) | 7 (TMF628, TMF629, TMF642, TMF658, TMF664, TMF666, TMF728) |

Length ranges from 20 characters (TMF642: `"Alarm Management API"`) to 3,683 characters (TMF782), with a median of 544 and a mean of 864. 

Markdown style is inconsistent: 19/86 use `### Resources` / `### Operations` structure; 19/86 open with a bold `**TMF API Reference : TMF-xxx…**` banner; the rest use free prose or other patterns. Many descriptions have been copy-pasted from the OAS `info.description` field verbatim (including dates, copyright, Swagger boilerplate), rather than being purpose-written for the rules file.

---

## Best Practice Guidelines

### 1. Programmatic Validation Rules (CI-enforceable)

These can be implemented as schema checks or linting rules:

**`tmfId`**
- Regex: `^TMF\d{3,4}$` — must match exactly.
- Must equal the `TMF\d{3,4}` prefix extracted from the rules file's own filename.
- Must be a YAML string, not an integer (YAML may silently parse `TMF921` as a string, but bare `921` would be an integer).

**`name`**
- Must be present and non-empty.
- Must not contain the word `API` (the meta-context already implies this is an API name).
- Must not use CamelCase: all words must be space-separated (regex: must not match `[a-z][A-Z]`).
- Printable ASCII only: must match `^[\x20-\x7E]+$`.
- Must not be identical to the formatted API folder name with underscores replaced by spaces (i.e., it must be human-authored, not machine-derived).

**`shortName`**
- Must be present and non-empty.
- Must be ≤ `name` in length (it is a *short* name).
- Must not contain the word `API`.
- Must not use CamelCase (same rule as `name`).
- Printable ASCII only.

**`description`**
- Must be present and non-empty.
- Minimum length: 100 characters (stub descriptions like `"Alarm Management API"` are insufficient).
- Must not contain `©`, `Copyright`, or `All Rights Reserved` (copyright belongs in the OAS `info` block or a dedicated `license` node, not the description).
- Must not contain Unicode characters outside the Basic Latin and Latin-1 Supplement ranges that are not semantic (specifically flag: curly/smart quotes `\u201C\u201D\u2018\u2019`, en/em dashes `\u2013\u2014` when an ASCII hyphen would do, horizontal ellipsis `\u2026`).
- Must not match the Swagger boilerplate pattern: `This is Swagger UI environment generated for`.
- Must not contain version/date noise patterns: `\b(January|February|…|December)\s+\d{4}\b`, `Release\s*:\s*\d`, `version\s*:?\s*\d+\.\d+`, `Final\s*:\s*\d`.

---

### 2. Author Guidelines (High-Level Do's and Don'ts)

**`tmfId`**
- **Do** use the format `TMF` followed by the three- or four-digit number exactly (e.g., `TMF621`). No spaces, no lowercase.
- **Don't** derive this from memory — verify it against the folder name.

**`name`**
- **Do** use Title Case with spaces: `Service Activation and Configuration`, `Geographic Address`.
- **Do** decide deliberately whether to include "Management" in the name. The convention should match the formal document title. Use it when the API is primarily a management plane (CRUD lifecycle); omit it when the API name is a noun-of-domain (e.g., `Quote`, `Alarm`).
- **Don't** include the word "API" — it is implied by the field's context.
- **Don't** use CamelCase (`ProductOrdering`) — this is a display name, not an identifier.
- **Don't** use punctuation other than spaces, ampersands, and hyphens where necessary.

**`shortName`**
- **Do** treat this as a concise label for use in tooling, table headings, and breadcrumbs — typically 1–3 words.
- **Do** differ it from `name` when `name` is longer than two words (e.g., `name: Agreement Management`, `shortName: Agreement`).
- **Don't** simply copy `name` into `shortName` — if they are truly the same, the author should re-examine whether `name` is already short enough, or whether `shortName` should be abbreviated.
- **Don't** use CamelCase or include "API".

**`description`**
- **Do** write the description as plain narrative prose that a developer could read to understand the API's purpose in 30 seconds. Cover: what domain problem it solves, what the primary resources are, and what high-level operations are supported.
- **Do** use CommonMark Markdown: `###` headings for sections (e.g., `### Resources`, `### Operations`), backticks for resource names, bullet lists for resource/operation enumerations.
- **Don't** copy-paste the OAS `info.description` field verbatim — the rules file description may share substance but should be curated and free of OAS-specific artefacts (version lines, tool boilerplate).
- **Don't** embed a copyright notice, release date, or version number — these are metadata that belong elsewhere (OAS `info.version`, `info.license`, Git history).
- **Don't** leave placeholder text (`to be added`, `TBD`, `This is Swagger UI environment generated for…`).
- **Don't** use "smart" or "curly" typographic characters — use only ASCII punctuation. Specifically: use `"..."` not `"..."`, use `-` not `–` or `—`, use `...` not `…`.
- **Don't** start the description by restating the API name (e.g., `"Alarm Management API"` as the entire description adds nothing).

---

### 3. Proposed SKILL.md — Agent Semantic Review

The following categories of check require language understanding and are well-suited to an agent:

**Scope and Purpose Quality**
- Does the description explain *what problem the API solves* and *for whom*, or does it only list operations?
- Is the description self-contained — i.e., could a developer unfamiliar with TMF Forum understand it without prior context?
- Does the description avoid circular definitions (e.g., "The Foo Management API manages Foo")?

**Linguistic Quality**
- Is the English grammatically correct, using standard British/American conventions consistently within the file?
- Are sentences complete and not mid-thought truncations (a sign of copy-paste from another document)?
- Is passive voice used where active voice would be clearer?
- Are there malapropisms or informal language inappropriate for a technical specification (`"vague request"`, `"in a nutshell"`)?

**Markdown Quality**
- Is Markdown CommonMark compliant — e.g., no HTML tags, no trailing spaces used for line breaks?
- Are heading levels used consistently and hierarchically (`###` not `##` where `###` is used elsewhere in the file)?
- Are inline code spans (backticks) used for resource names and field names rather than bold or plain text?
- Are bullet list items parallel in grammatical structure?

**Semantic Coherence**
- Does the `name` accurately reflect the domain described in the `description`?
- Does the `shortName` appear to be a genuine abbreviation/condensation of the `name`, rather than an unrelated string?
- Does the `tmfId` mentioned anywhere in the description body match the `tmfId` field value?
- Does the description mention any other TMF API numbers (cross-references), and if so, are those consistent with known TMF API names?

**Content Hygiene**
- Does the description contain any legal language (copyright, "All Rights Reserved", "No part of this document")?
- Does the description embed dates, release numbers, or version strings that should be managed as metadata instead?
- Does the description reference internal tooling or processes by name (e.g., Jira ticket numbers, internal team names, Swagger UI)?
- Does the description contain any text that reads like a marketing claim or promotional language rather than technical description?