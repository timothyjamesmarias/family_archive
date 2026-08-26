# Design System Port — Plan

Tracks the port of the public UI to the claude.ai/design spec ("Archive
Foundations" / "Archive Pages"). The design files are the spec — follow
them literally; when they are silent or impossible to follow, ask, don't
invent (see CLAUDE.md, "Design System").

## Done

- Foundations palette in `public.css` (verdigris, heather, paper pair, ink,
  functional colours, mono token)
- Recipe classes + ViewComponent primitives (`Ui::` Button, TypeChip,
  StatusChip, Link, Field) with tests and previews
- Record/list patterns: ArtifactCard, ArtifactRow, ArtifactThumbnail,
  MetadataList, `Ui::` EmptyState, Pagination, Tabs, Message, Breadcrumbs
- Public chrome: masthead (active underline, mono Dark/Light toggle,
  Search button, Sign in), breadcrumb slot, footer with holdings line
- Pages: home (four bands, search form, no Try links for now), collection
  hub (preview-strip cards), collection indexes (grid/list split)
- `/search` placeholder endpoint only — feature architected separately
- Written-record reader (screen 5) for letters/documents/ledgers: scan
  pane with leaf switcher, transcription/translation/commentary/details
  tabs. Drawn elements with no backing data are omitted, pending
  decisions: people/places tags, medium field, review dates, Cite this
  item, zoom/fullscreen, prev/next ordering, article↔artifact links

- Collection index controls (screens 3–4): collection search (plain
  ILIKE finding aid), auto-submitting sort, data-backed filter pills,
  Grid/List switcher. The 1940s and Has-people pills are omitted until
  parsed dates and people tagging exist

- Article show styled to foundations 08: prose recipes, specimen header
  (mono kicker, excerpt as standfirst, mono dateline), class hooks for
  editor's note and notes. Byline/source counts omitted — no data

## Up next (in order)

Screens 9–15 landed in "Archive Pages (standalone)" (export/
pages-standalone-src.html is the readable source). Screens 1–8 are
unchanged except the masthead, unified to the implemented chrome. The
hero Try links remain in the design but stay out of the code by Tim's
instruction until they can be built dynamically.

Done from this batch: empty states (screen 15), articles index (9),
login (13), 404/500 via exceptions_app (14, static pages deleted),
photo detail (10), and audio detail (11 — media-player Stimulus controller around a native audio element; timestamped transcript still waits on data).

1. **Video detail** (screen 12) — dark player band; description/metadata
   blocked

## Data model needs the new screens surfaced (Tim's call)

- Person/place tagging on artifacts and annotations
- Medium and description fields on artifacts
- Timestamped transcripts; audio/video durations
- Article↔artifact source associations; citation format
- Annotation attributions ("identified by …")

## Blocked / waiting on decisions

- **Search results + empty state** (screens 7–8): waiting on Tim's search
  architecture; do not build ahead of his plan
- **Design-sync back-edits**: Try links removed in code; masthead variants
  merged (Search + divider + Dark + Sign in); focus ring shipped verdigris
  (prose said terracotta); sage/dusty dark chip tints shipped as color-mix
  — all need mirroring or ruling in the design file
- **Undesigned surfaces**: photo/audio/video/document/ledger detail beyond
  the letter pattern, login, 404/500 — design first, then code

## Later

- React twins of the component library when the family-tree rewrite starts
- Family tree page chrome (screen 6) — agreed to do it after the React
  rewrite of the island, which makes it easier
- Search buildout to Tim's architecture
