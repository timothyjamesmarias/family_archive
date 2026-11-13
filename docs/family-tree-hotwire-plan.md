# Family Tree → Hotwire — Plan

Replaces the TypeScript family-tree island (`app/frontend/apps/family-tree`,
~6,700 lines with tests, plus dagre and four d3 packages) with server-rendered
ERB, Turbo Frames, two small Stimulus controllers and a Ruby layout engine.
Same pattern the annotations migration proved: Rails owns every form, list and
menu; JavaScript owns only continuous spatial interaction (here: zoom and
drag-to-pan).

## Chunks

Each chunk is one PR. The island keeps working until the last one.

1. **Layout engine** (this document's second half). `FamilyTree::Layout`:
   pure Ruby, no views, no routes, tests only. Positions people on a grid
   from the `{individuals, families}` shape the Builder already produces.
2. **Read-only chart.** A parallel route renders the chart from the layout:
   absolutely positioned person cards over an SVG edge layer, inside one
   sized wrapper in a scrollable container. Expansion state lives in the
   URL (`?up[]=12&down[]=87`, Rails array params); every expand button is a
   plain link into the same Turbo Frame, so back/forward and bookmarks work
   for free. A `zoom` Stimulus controller sets the CSS `zoom` property
   (scroll extents follow) and handles drag-to-pan. Person card and expand
   button, edges and the chart assembly are ViewComponents under
   `FamilyTree::`. Needs a design page for the tree — the design project is
   the spec and currently has none. The queries and the Builder are finished
   and stay as they are: `FamilyTree::Chart` composes `initial_tree` and
   `expand_tree` the way the island's store does and decorates the result
   with the order the layout reads as meaning (father first by sex, children
   by `child_order`, families by id).
3. **Edit mode.** `?edit=1` for a signed-in user. Per-card action menu as a
   native `<details>` (a `popover` would need anchor positioning to sit on
   its card), forms in a `<dialog>` holding a Turbo Frame (one small Stimulus
   controller opens it when the frame loads). The controllers reuse
   `Individual::Editor` and `FamilyTree::Mutations` and redirect back to the
   tree URL; the controller replays that redirect as a replace visit, so the
   chart and flash update in place.
4. **Cutover.** Route swap, delete the island, its Vitest suite, dagre and
   d3, and the `/api/family-tree` JSON endpoints. Update CLAUDE.md.

Status: all four chunks landed (chunk 3 before chunk 4, so editing never
left the public page). `docs/family-tree-architecture.md` describes the
result; this document is the record of how it got there.

## Why not port dagre

Dagre is Sugiyama: rank assignment, crossing minimisation, Brandes–Köpf
coordinate assignment. Weeks of work, and the island already spends two
post-passes (`spaceFamilyGroups`, `centerParentsOverChildren`) undoing what
it does to a genealogy. Family data has a structure dagre cannot see: it is
*almost* a tree of family units. The engine below exploits that and treats
the rare non-tree cases (both spouses have loaded parents, cousin marriage,
a child listed in two families) as explicit "cross-links" drawn over a tree
layout, instead of paying the general-DAG price everywhere.

---

# Layout engine design

## Contract

```ruby
layout = FamilyTree::Layout.new(individual_ids:, units:)
layout.positions   # { individual_id => Position(x:, generation:) }, memoised
layout.width       # slots (max x + 1)
layout.height      # rows  (max generation + 1)
layout.sketch      # ASCII picture, for tests, the console and the curious
```

- `units` are `FamilyTree::Layout::Unit = Data.define(:id, :parent_ids,
  :child_ids)`. **Order is meaning**: `parent_ids[0]` is drawn left in a
  single-marriage block (the Builder will put the FATHER role first),
  `child_ids` is left-to-right (the Builder will sort by `child_order`),
  and units are chronological (a remarried person's first marriage is the
  first unit listing them). The layout never reorders siblings — birth
  order is a convention genealogists expect, and we trade crossing
  minimisation for it deliberately. A child listed twice in a unit, and ids
  outside the loaded set, are ignored.
- `individual_ids` is the full loaded set; its first id seeds the packing
  order (the Builder lists roots first). Ids in units that are not in this
  set are ignored.
- Coordinates are **unitless**. `x` is a card centre measured in slots (one
  slot = one card plus its gutter), leftmost card centre at 0; `generation`
  is an integer row, top row 0. The view multiplies by pixel constants.
  Edge geometry (marriage line, drop, sibling bus, stubs) is derived by the
  view from positions plus units; the layout emits none.

## Model

**Block.** People connected by marriage form one block — one walk over
co-parent edges from each unit's first parent, seating every newly met
spouse beside the person they marry (on the right, or after turning the row
around when that person is at its left end). A block is one layout node;
its width is its member count. A couple is a block of width 2; a remarried
person sits between their spouses, first marriage on the left: `S1 P S2`,
`H1 W H2`. That keeps every marriage line between adjacent cards. The first
child-bearing marriage decides the block's centre; later broods are pushed
right until their drop falls within their own children, so with uneven
broods a later drop sits at the left edge of its children rather than
centred over them.

**Parent unit** of a person listed as a child in several units: the unit
whose parents sit deepest (longest parent→child path from a parentless
person), so a grandchild also recorded in the grandparents' family hangs
under the parents, and a unit with loaded parents beats a parentless one.
Ties go to input order.

**Anchor** of a block: the first member with a parent unit, scanning the
block's units in input order and each unit's parents in order. With the
Builder's FATHER-first convention this makes the surname line the spine and
wives' families side trees — the right default for an archive organised by
surname, and a one-line change if it ever is not.

**Tree edge.** A block hangs under the block holding its anchor's parent
unit. A unit with loaded children but no loaded parents gets a **phantom**
block (width 0, never rendered) so the siblings still hang together.

**Children order** under a block: by unit (ordered by the unit's midpoint
within the block, then input order), then by `child_ids` order. A child
block is placed under the unit its anchor is a child of.

**Cross-link.** Every (person, parent unit) pair that is not a tree edge:
the non-anchor spouse whose parents are loaded, a person's second parent
unit. Cross-links never influence the tidy tree; they influence generation
alignment and packing below, and the view draws them with the same
bus-and-stub geometry as any other child.

**Generation** = depth within a tree, then reconciled across trees (below).
Spouses share a generation by construction.

## Algorithm

1. **Blocks and trees** as above. A cycle guard breaks a tree edge that
   would revisit a block (someone listed as their own ancestor) and treats
   the block as a root.
2. **Tidy tree per tree.** Buchheim, Jünger & Leipert 2002 ("Improving
   Walker's Algorithm to Run in Linear Time"), ported from d3-hierarchy's
   `tree.js`, with the separation function

       separation(a, b) = (a.width + b.width) / 2 + (siblings?(a, b) ? 0 : 1)

   so siblings sit in adjacent slots, anything else (cousins, strangers)
   gets one empty slot between, and a parent block is centred over its
   children's *own cards* (each child block counted at its anchor), so a
   married child sits under the marriage and the in-law hangs beside them.
   An ancestor line with no loaded siblings therefore steps half a slot
   sideways per generation. Local coordinates: root at 0.
3. **Forest packing.** Trees are placed one at a time:
   - Order: the tree holding `individual_ids.first`; then breadth-first
     over cross-links, each tree's links taken in x-order of their placed
     endpoint; then unlinked trees by size, largest first.
   - Generation offset of a linked tree comes from the link that discovered
     it: `generation(child) = generation(unit's block) + 1`. Unlinked trees
     put their first *real* row on the top row (a phantom root sits above
     it). A second link with a conflicting offset is left as a long edge.
   - Horizontal offset: *desired* aligns the link (child centre under the
     unit's midpoint); *clearing* is the nearest offset on each side that
     keeps every shared row at least `gap` away from what is placed (0 for
     linked trees, 1 for unlinked). Clear towards the side the link child
     sits on within their block — a wife's parents go out past the wife —
     and only when the child is centred in their block take whichever side
     is nearer to desired. Per-row extents only — a tree lands outside the
     placed hull in every row it shares, never inside it.
4. **Normalise**: shift so the leftmost real card is at x = 0 and the top
   real row is generation 0 (phantoms may sit at −1; the view never sees
   them).

## What this gives up, on purpose

- No crossing minimisation beyond the packing heuristics. Birth order wins.
- A person with three or more spouses gets the extras appended on the
  right; those marriage lines pass behind a card. Spouse chains (S1
  remarried T) stay adjacent by turning the row around, which can put the
  shared person's first marriage on the right: `S2 P S1 T`.
- A child of two families is drawn once, under the deeper; the other is a
  long edge, possibly spanning rows.
- Buses of two units on one row may overlap (an in-law bus reaching back to
  a spouse passes over her husband's siblings). Laning them is the view's
  job in chunk 2, as is drawing a link whose rows do not differ by one
  (uncle marrying niece) as a routed edge instead of bus-and-stub.
- Two trees linked twice (brothers marrying sisters) are aligned on the
  first link only.

Each is a `ponytail:` comment in the code with the upgrade path.

## Files

```
app/models/family_tree/layout.rb              entry point (the instance is the result), Unit, Position
app/models/family_tree/layout/forest.rb       blocks, anchors, tree edges, cross-links
app/models/family_tree/layout/tidy_tree.rb    Buchheim port
app/models/family_tree/layout/packing.rb      generation reconciliation + forest packing
test/models/family_tree/layout_test.rb
```

## Tests first

Exact positions for the small shapes (they *are* the spec), properties for
the big ones. Every failure message carries the ASCII sketch.

- single person; couple; couple with one child (child centred under the
  marriage); couple with three children (parents centred, children in
  adjacent slots)
- parentless siblings stay adjacent (phantom)
- birth order preserved left-to-right
- cousins get one empty slot, siblings none; grandparents centred over both
  families (exact values worked by hand)
- remarriage: `P S1 S2`, first marriage's children left of the second's
- both spouses have loaded parents: all four grandparents on one row, the
  couple adjacent, the wife's parents packed on her side, no overlaps
- wife's siblings end up adjacent to her; her parents clear his parents by
  a slot
- in-laws pack on their own child's side even when the other side is nearer
- a married only child sits under the marriage, the in-law beside them
- a child of the second marriage is not drawn under the first spouse
- a grandchild also recorded in the grandparents' family hangs under the
  parents; a child in a parentless unit and a unit with parents hangs under
  the parents
- a parked parentless sibling group starts on the top row
- three contour shapes that exercise threads, spreading and the carried
  offset (exact values worked by hand; each kills a mutant the simple
  shapes let through)
- isolated person and unlinked components placed to the right with a gap,
  starting at row 0
- child in two families positioned once; cycle in the data terminates
- property run over 200 seeded random forests whose brides come from
  another root's tree: every person positioned once; no two cards in a row
  closer than one slot; every parent-child pair exactly one row apart,
  across trees too; sibling order preserved; a couple is centred over its
  first and last tree child
