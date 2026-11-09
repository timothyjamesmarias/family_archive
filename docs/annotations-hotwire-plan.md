# Annotations Editor → Hotwire — Plan

Replaces the React + MUI annotations island (`app/frontend/apps/annotations`)
with server-rendered ERB, Turbo and one Stimulus controller. It is the pilot
for retiring the JS-app/Rails split described in the architecture discussion:
Rails owns every form, list and modal; JavaScript owns only continuous
spatial interaction (here, nothing — a click on an image is a form).

## Why annotations first

- Smallest island (~700 lines TS + ~400 lines tests) and the only React user,
  so finishing it drops react, react-dom, @mui/material, @mui/icons-material,
  @emotion/react, @emotion/styled and @vitejs/plugin-react outright.
- Its hard part (place a dot where you clicked, edit it in a popover) is
  already solved server-side on the public photo reader, whose
  `photo-annotations` Stimulus controller is auto-registered in the admin
  bundle too.
- Proves the pattern the tree migration will reuse: frame for the popover
  form, redirect + morph for everything else.

## Behaviour change (deliberate)

Edits persist immediately, one annotation per request. Gone: in-memory dirty
tracking, "Save annotations" / "Discard changes", the beforeunload warning,
and the replace-the-whole-set endpoint whose footgun both sides of the code
carry comments about. Single admin, one photo at a time — batching bought
nothing.

## Target design

### Routes

```ruby
# replaces: put "artifact-files/:file_id/annotations", to: "annotations#replace"
namespace :admin do
  resources :artifact_files, only: [] do
    resources :annotations, only: %i[new create edit update destroy]
  end
end
```

`annotations_admin_artifact_path` stays as the page; it gains a `file`
query param selecting the current file (defaults to the first).

### Controller: `Admin::AnnotationsController`

Thin. Finds the file, builds/finds the annotation, saves, redirects to the
annotations page for that file. Validation failure re-renders the form
partial with 422 so the frame shows errors in place. No JSON, no streams.

```ruby
def create
  @annotation = file.annotations.build(annotation_params)
  if @annotation.save
    redirect_to editor_path, notice: "Annotation added."
  else
    render :new, status: :unprocessable_entity
  end
end
```

`Annotation` gains `validates :x_coord, :y_coord, numericality: { in: 0..1 }`,
replacing the hand-rolled range checks in the API controller.

### Turbo mechanism

- **Page re-render is a redirect + morph.** Admin layout gets
  `turbo_refreshes_with method: :morph, scroll: :preserve`. After
  create/update/destroy the page redirects to itself and Turbo morphs: new dot
  appears, list updates, scroll and selected file survive, flash shows.
- **The form is the only frame.** `<turbo-frame id="annotation_form">` sits
  absolutely positioned over the stage. Marker links and the Stimulus
  controller load `new`/`edit` into it. Its forms carry
  `data-turbo-frame="_top"` so a successful submit's redirect morphs the
  whole page, while a 422 (rendered with the frame tag) stays in the frame.
- **No stream templates.** If a second region ever needs a different
  response than a morph gives, that is the moment to add one — not before.

### Views (`app/views/admin/annotations/`, page stays in `admin/artifacts/`)

| File | Contents |
|---|---|
| `artifacts/annotations.html.erb` | header, file tabs (links with `?file=`), stage + list via partials, the empty `annotation_form` frame, `data-controller="photo-annotations annotation-editor"` |
| `annotations/_stage.html.erb` | `<img>` plus one marker per annotation. Marker = `link_to edit_…, data: { turbo_frame: "annotation_form", photo_annotations_target: "marker", annotation_id: }` positioned with `left/top` percentages |
| `annotations/_list.html.erb` | sidebar rows, same `photo-annotations` row targets as the public reader |
| `annotations/_form.html.erb` | `form_with model: [:admin, file, annotation]`, text field, hidden `x_coord`/`y_coord`, Save, Cancel (clears the frame), Delete via `button_to … method: :delete, data: { turbo_confirm: }` on edit |
| `annotations/new.html.erb`, `edit.html.erb` | wrap `_form` in `turbo_frame_tag "annotation_form"` |

All partials use strict locals (`<%# locals: (file:, annotations:) %>`).
Admin loads `application.css`, not `public.css`, so markers use plain
Tailwind classes here rather than the public `.annotation-dot` recipe.
Markup stays within what the admin layout already does (slate palette,
existing button classes); nothing new is invented.

### Stimulus: `annotation_editor_controller.ts` (~50 lines)

- `place(event)` on image click: convert to a 0–1 fraction (port of
  `coordinates.ts`, clamped), position the popover at the click, set the
  frame `src` to `new_admin_artifact_file_annotation_path(x:, y:)`.
- `anchor(event)` on marker click: position the popover beside the marker;
  Turbo loads `edit` via the link's `data-turbo-frame`.
- `close()` on Escape / outside click / Cancel: empty the frame.
- Highlighting marker ↔ row is the existing `photo-annotations` controller,
  untouched.

Nothing in it generates HTML. Nothing in it fetches. Under 50 lines or
something is wrong.

## Steps

1. **Layout + model.** `turbo_refreshes_with` in `layouts/admin`;
   coordinate validations on `Annotation`. Run existing tests — the public
   reader must not change.
2. **Routes + controller + views.** Build the page server-side first with
   plain links (no popover): markers link to `edit`, "Add annotation" is a
   form. Everything must work with JavaScript disabled. Integration tests
   for create/update/destroy/422 land here.
3. **Frame + Stimulus.** Wrap the form in the frame, add the controller,
   popover placement. System test: click marker → popover → Delete →
   confirm → one marker left (deletion-only, to dodge the chromedriver
   keystroke flake; typing is covered by the integration tests).
4. **Delete.** `apps/annotations/`, `entrypoints/admin_annotations.tsx`,
   `Api::AnnotationsController` + route, `ReplaceAnnotations`,
   `annotations_payload` in the admin controller, the React tests, the
   `vite_react_refresh_tag` + `turbo-visit-control` head block, `react()`
   in `vite.config.ts`, and the seven npm packages. Remove the stale
   `admin_annotations.tsx` mention from CLAUDE.md's Frontend section.
5. **Verify.** `bin/ci` green; `npm ls react` finds nothing; the admin
   page works with JS off (steps 2 markup) and on.

Each step is a commit; 1–3 are shippable without 4.

## Tests

- Keep: public reader tests, `artifact_admin_pages_test` entries that do not
  touch the payload or the PUT endpoint.
- Replace: "the annotations page embeds the editor payload" → asserts
  server-rendered markers and list rows. "replacing a file's annotations…" and
  "an out-of-range coordinate is rejected" → `Admin::Annotations` create /
  update / destroy / 422 tests. System test rewritten against real markup.
- Delete: `apps/annotations/__tests__/*`.

## Out of scope

- Herb linter/engine setup — separate PR, applies to the whole app.
- Family-tree migration — follows this pattern once it has landed.
- Realtime broadcasts, multi-user editing, undo.

## Open questions

- Keyboard placement (place a dot without a mouse) — not in the current
  island either; note it, don't build it.
- Whether `turbo_refreshes_with` morph should be admin-wide from day one or
  scoped to this page via `content_for :head`. Default: admin-wide; the
  admin has no islands left once the Uppy uploader is checked for morph
  safety (it mounts on `DOMContentLoaded` — may need `data-turbo-permanent`
  or a Stimulus wrapper; verify in step 1).
