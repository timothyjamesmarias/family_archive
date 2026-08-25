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

## Up next (in order)

1. **Collection index controls** (screens 3–4) — per-collection search,
   sort, filter pills, Grid/List switcher; needs query/controller support
2. **Article show** — apply the foundations rich-content spec (no page
   mockup; foundations section 08 is the source)
3. **Articles index** — no mockup yet; needs design before code
4. **Family tree page chrome** (screen 6) — island untouched until the
   React rewrite

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
- Search buildout to Tim's architecture
