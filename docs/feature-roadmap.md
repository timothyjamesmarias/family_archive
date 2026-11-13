# Feature Roadmap

The features the original app set out to build (its `docs/overview.md` and
decision log), restated against what this port has today. The earlier plans
in this folder (`*-plan.md`) are finished or in flight; this document is
where the next ones start. Each feature gets its own plan and a page in the
design project ("Archive Pages") before code; nothing below prescribes how.

## Status of the original feature list

| Feature | State |
|---|---|
| Artifact management (upload, types, files, thumbnails) | Done |
| Photo annotation | Done (admin editor + public overlay) |
| Articles with embedded artifacts | Working, unstyled: Lexxy editor and an embed registry; the public embed isn't designed yet |
| Family tree builder, GEDCOM import | Done (server-rendered, edit mode) |
| Transcriptions, translations, commentary | Half: schema and public reader tabs exist, no admin editing |
| Search | Placeholder route only (`/search`, `SearchesController`) |
| Automatic transcription | Not started |
| Biographies | Not started |
| Interactive maps | Not started; `places` already has lat/long columns |
| Quick scan (camera upload) | Not started |

## What each one means

- **Transcription, translation, commentary editing.** Admins can write and
  correct the text the public reader already displays. Production has rows
  from the old app.
- **Search.** Query scanned documents and genealogical records from the
  public site: artifacts, articles, people, places.
- **Automatic transcription.** Uploaded documents, letters and ledgers get a
  machine draft of their transcription for an admin to correct.
- **Biographies.** Written life stories of family members, published on the
  public site and reachable from the tree.
- **Interactive maps.** People, places and narrative journeys across time.
  Imported places mostly lack coordinates.
- **Quick scan.** A phone-first way to photograph a document and file it as
  an artifact.
