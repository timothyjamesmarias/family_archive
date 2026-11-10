# Generic TS Scripts → Stimulus — Plan

Moves the page-level scripts that aren't the family-tree island onto
Stimulus controllers, behaviour unchanged. Afterwards every non-island
script on the site is a controller the bundles register; no page loads its
own entrypoint, and no page needs `turbo-visit-control: reload` to survive a
Turbo visit.

## Inventory

| Script | Loaded by | Fate |
|---|---|---|
| `shared/mobileMenu.ts` (95 lines, `window.mobileMenu`, inline `onclick=`) | `public.ts` | → `mobile_menu_controller.ts` |
| `shared/uppyFormPicker.ts` + `entrypoints/admin_gedcom_upload.ts` + `entrypoints/admin_artifact_files.ts` | own `vite_javascript_tag` per page | → `uppy_picker_controller.ts` |
| `entrypoints/admin_artifact_upload.ts` (JSON `fetch`, toast, "add another") | own tag on `admin/artifacts/new` | → `artifact_upload_controller.ts` |
| `shared/uploads.ts` (upload limits) | the upload scripts | stays |
| `components/toast.ts` | island + upload scripts | stays |
| `family_tree.ts`, `shared/store.ts`, `components/modal.ts`, `escape_html.ts`, `csrf.ts` | family-tree island | untouched — the island rewrite owns them |

## 1. `mobile_menu_controller.ts` (public)

Same behaviour as today: the button toggles the menu and swaps the
hamburger/close icons; a click outside the menu and button, or Escape,
closes it.

```erb
<div data-controller="mobile-menu"
     data-action="click@document->mobile-menu#closeOutside keydown.esc@document->mobile-menu#close">
  …
  <button data-mobile-menu-target="button" data-action="mobile-menu#toggle"
          aria-expanded="false" aria-controls="mobile-menu" aria-label="Toggle menu" …>
    <span data-mobile-menu-target="openIcon"><%= icon_tag "hamburger" %></span>
    <span data-mobile-menu-target="closeIcon" class="hidden"><%= icon_tag "close" %></span>
  </button>
  …
  <div id="mobile-menu" data-mobile-menu-target="menu" class="hidden md:hidden">…</div>
</div>
```

- `data-controller` goes on the nearest element wrapping both the button
  and `#mobile-menu` in `layouts/public.html.erb`.
- Controller is ~30 lines: `toggle`, `open`, `close`, `closeOutside` (ignores
  clicks inside `menu`/`button`). `open`/`close` also set `aria-expanded` —
  not visible, an accessibility basic the current script lacks.
- Register it in `public.ts`; the admin glob picks it up automatically
  (unused there, harmless).
- Delete `shared/mobileMenu.ts`, its import, the `onclick`, and the
  `mobile-menu-button` / `hamburger-icon` / `close-icon` ids.

## 2. Shared Uppy mount: `shared/uppy.ts`

Both upload controllers mount an Uppy dashboard the same way, so that part
is one small function (replacing the mount half of `uppyFormPicker.ts`):

```ts
export async function mountDashboard(target: HTMLElement, options: DashboardOptions): Promise<Uppy>
```

- Dynamically imports `@uppy/core`, `@uppy/dashboard` and their CSS, so Uppy
  downloads only on the three pages that use it even though the admin
  bundle registers every controller eagerly.
- `target.replaceChildren()` first — a Turbo snapshot restore brings back
  Uppy's stale DOM.
- Applies `pageTheme()` (moves here from `uppyFormPicker.ts`).

Each controller calls it in `connect()`, calls `uppy.destroy()` in
`disconnect()`, and guards against `disconnect()` landing before the
import resolves.

## 3. `uppy_picker_controller.ts` (GEDCOM import, add files)

A port of `mountUppyFormPicker`: Uppy only picks files; the button copies
them into the form's hidden file input and submits the form natively
(`data: { turbo: false }`), so redirect + flash work unchanged.

```erb
<%= form_with url: …, multipart: true,
      data: { turbo: false, controller: "uppy-picker",
              uppy_picker_max_files_value: 1,
              uppy_picker_max_file_size_value: Admin::GedcomImportsController::MAX_GEDCOM_BYTES,
              uppy_picker_allowed_types_value: [".ged"],
              uppy_picker_note_value: "A single GEDCOM (.ged) file, up to 50MB",
              uppy_picker_empty_message_value: "Choose a .ged file to import",
              uppy_picker_height_value: 300 } do %>
  <%= file_field_tag :file, accept: ".ged", class: "hidden", data: { uppy_picker_target: "input" } %>
  <div data-uppy-picker-target="dashboard"></div>
  <button type="button" data-uppy-picker-target="submit" data-action="uppy-picker#submit" …>Import</button>
<% end %>
```

- Values carry what each entrypoint passes today: `maxFiles`, `maxFileSize`
  (defaults to `MAX_FILE_SIZE` from `uploads.ts`), `allowedTypes`, `note`,
  `height`, `emptyMessage`.
- `submit()`: no files → `showToast` with the empty message; otherwise copy
  files into `inputTarget` via `DataTransfer`, disable the button,
  `form.requestSubmit()` — exactly what `uppyFormPicker.ts` does now.
- The add-files page's note moves into its ERB as literal text:
  "Up to 10 files, 150MB each. They continue the sequence."

**GEDCOM limit fix (the only behaviour change):** the picker currently
allows 150MB while `Admin::GedcomImportsController` rejects anything over
50MB. The page passes `MAX_GEDCOM_BYTES` as `maxFileSize`, and the note says
50MB.

## 4. `artifact_upload_controller.ts` (upload artifact)

A port of `admin_artifact_upload.ts`, same behaviour: JSON `POST` to the
create endpoint, error box + toast on failure, "Save and add another" keeps
the type and clears everything else, "Upload" goes to the new artifact.

- Targets: `dashboard`, `type`, `title`, `date`, `error`, `button` (both
  buttons, for busy state). Values: `createUrl`, `artifactsUrl`.
- Two actions, `upload` and `addAnother`, both calling a private
  `send()` and differing only in what happens after a successful save — no
  boolean parameter.
- Uppy restrictions and note stay in TS, from `uploads.ts`, as today.
- Markup changes in `admin/artifacts/new`: `data-*` hooks become
  `data-artifact-upload-target`/`-value`/`data-action`. Nothing visible changes.

## Turbo cleanup

- Remove the three `vite_javascript_tag` lines and the three
  `turbo-visit-control: reload` metas (`admin/artifacts/new`,
  `admin/artifacts/show`, `admin/gedcom_imports/show`); delete the three
  entrypoints and `uppyFormPicker.ts`.
- The picker forms keep `data: { turbo: false }` — the redirect/flash
  reasoning in their comments still holds. Update the comment above the
  file Delete button on `admin/artifacts/show`, which cites the reload meta.
- Update CLAUDE.md's Frontend section: replace the `admin_artifact_upload.ts`
  entry with the two upload controllers, and note that
  `turbo-visit-control: reload` now applies only to `/family-tree`.

## Steps

1. **Mobile menu.** Controller, layout markup, delete `mobileMenu.ts`.
   Add a system test: at phone width, open the menu, press Escape, menu is
   hidden (none covers it today).
2. **`shared/uppy.ts` + `uppy_picker`.** Swap GEDCOM and add-files over,
   including the GEDCOM limit fix. Existing system tests
   (`gedcom_import_test`, "adding a file through the details page") pass
   unchanged — `attach_to_uppy` targets `.uppy-Dashboard`, which still
   renders.
3. **`artifact_upload`.** Swap the upload page over. Existing system test
   "uploading through the Uppy dashboard, then saving and adding another"
   passes unchanged.
4. **Turbo visit check.** System test: reach an upload page via a Turbo
   link (no reload meta), go back, go forward — exactly one dashboard.
5. **Verify.** `bin/ci` green; `grep -r vite_javascript_tag app/views` shows
   only the layouts and `/family-tree`.

Each step is a commit.

## Out of scope

- Family-tree island, toast and modal elements — the tree rewrite.
- Turbo-driven uploads (dropping `turbo: false`) — the flash issue in the
  existing comments is real; revisit with the tree work if ever.

## Later (separate changes)

- **Upload limits from Ruby.** `uploads.ts` duplicates
  `Artifact::MAX_FILE_SIZE_BYTES`, and the 10-file limit exists only in TS
  (`validate_upload` doesn't check a count). Pass limits and allowed types
  from Ruby as controller values, add `Artifact::MAX_FILES` with a server
  check, delete `uploads.ts`.
- **Upload page as a plain form post.** `create` already has an HTML branch;
  the upload page could use `uppy_picker` like the others and the JSON branch
  could go. Costs the files surviving a server-side rejection.

## As built

Where the shipped code differs from the plan above. The code and CLAUDE.md
are current; this plan is the record of intent.

- **Cleanup rode with each swap.** Each page lost its `vite_javascript_tag`
  and reload meta in the step that moved it to a controller (steps 2–3), so
  there is no separate cleanup commit.
- **No page uses `turbo-visit-control: reload` now, `/family-tree`
  included.** It never set the meta: the public bundle carries no Turbo.
  CLAUDE.md says so instead of "applies only to /family-tree".
- **The mobile menu controller sits on a new wrapper** inside the masthead's
  full-chrome branch. The nearest existing element wrapping the button and
  `#mobile-menu` also wraps the wordmark-only masthead, where the targets
  don't exist; the wrapped markup re-indents. `open`/`close` are spelled out
  rather than sharing a boolean helper.
- **The mobile menu test** is its own file, driven at 390×844; it dispatches
  Escape from script because of the chromedriver keystroke flake.
- **`uppy_picker` defaults `maxFiles` to `MAX_FILES`** as well as
  `maxFileSize` to `MAX_FILE_SIZE`, so the add-files page sets neither and
  its limits stay in `uploads.ts`. An empty `allowedTypes` reaches Uppy as
  `null`, since Uppy rejects every file given an empty list.
- **`destroy()` on disconnect is what keeps a restored page to one
  dashboard**, not `replaceChildren()`: Turbo clones the page for its cache a
  tick after the visit starts, by which time Stimulus has disconnected and
  Uppy has removed its DOM. The step 4 test fails without `destroy()` and
  passes without `replaceChildren()`, which stays as a guard.
- **The step 4 test** covers the upload page (admin artifacts → "Upload
  artifact" → back → forward) and sets a `window` marker to prove no visit
  fell back to a full load.
- `artifact_upload` uses `disableButtons`/`enableButtons` instead of
  `setBusy(boolean)`.
- **Verification** ran `bin/ci`'s steps individually against a separate test
  database rather than `bin/ci` itself, whose setup step touches the shared
  development database.
