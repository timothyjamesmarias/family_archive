# Family Tree — Architecture

Mermaid diagrams of the family-tree subsystem as it is today. The migration
plan (`family-tree-hotwire-plan.md`) says where it is going; when a chunk
lands, its diagram moves from "Planned" to "Current" here, in the same PR.

## Current

### Layout engine (`FamilyTree::Layout`, chunk 1)

Pure Ruby. Ordered units in, slot positions out. Nothing here knows about
pixels or the database.

```mermaid
flowchart TD
    IN["individual_ids + Unit[] (id, parent_ids, child_ids)<br/>order is meaning: first parent left, children in birth order"]
    IN --> F

    subgraph F["Forest"]
        direction TB
        P["prune: drop ids outside the loaded set,<br/>duplicate children"]
        B["blocks: walk co-parent edges, seat spouses<br/>S1 P S2 / H1 W H2"]
        PU["parent unit per child: deepest listing unit"]
        A["anchor per block: first member with loaded parents<br/>→ tree edge to its parent unit (phantom for parentless units)"]
        CY["cut cycles"]
        T["trees + groups (children by unit seat)<br/>links = every other parent→child relation"]
        P --> B --> PU --> A --> CY --> T
    end

    F -->|"one tree at a time"| TT["TidyTree<br/>Buchheim/Walker port from d3-hierarchy<br/>separation = half-widths + (siblings ? 0 : 1)<br/>centre over children's cards, per marriage group"]
    TT -->|"local x per block, depth"| PK

    subgraph PK["Packing"]
        direction TB
        O["order: tree holding the first id,<br/>then BFS over links, then largest unlinked"]
        G["row offset from the discovering link<br/>(child = unit row + 1)"]
        X["column offset: child under unit midpoint,<br/>cleared to the side the linked spouse sits on"]
        O --> G --> X
    end

    PK --> N["normalise: leftmost card x = 0, top real row = 0"]
    N --> OUT["positions {id => (x, generation)}, width, height, sketch"]
```

### Island (to be replaced)

```mermaid
flowchart LR
    Page["/family-tree<br/>turbo-visit-control: reload"] --> Island["family_tree.ts island<br/>(web components, d3-zoom, dagre)"]
    Island -->|"GET /api/family-tree/initial, /expand"| API["Api::FamilyTreeController"]
    API --> Builder["FamilyTree::Builder<br/>loaded set → {individuals, families}"]
    Builder --> Q["Individual::Queries (recursive CTEs)<br/>FamilyTree::Metadata"]
    Island -->|"POST/PUT/DELETE /api/family-tree/…"| Edits["Api::FamilyTreeEditsController"]
    Edits --> Mut["FamilyTree::Mutations"]
```

## Planned

### Read-only chart (chunk 2)

```mermaid
flowchart TD
    URL["GET /family-tree/chart?up[]=12&down[]=87#person-12"] --> C["FamilyTreeChartsController#show"]
    C --> Chart

    subgraph Chart["FamilyTree::Chart (PORO)"]
        direction TB
        L["loaded set: roots → 1 gen up → siblings → spouses,<br/>then ancestors(12), descendants(87)<br/>(Builder, Individual::Queries)"]
        U["units, ordered: FATHER then MOTHER,<br/>children by child_order, units by marriage date"]
        LY["FamilyTree::Layout → positions"]
        E["Chart::Edges: positions + units → segments<br/>marriage, drop, bus, stubs; lanes; routed long edges"]
        M["expand flags: Metadata.relationship_metadata_for"]
        L --> U --> LY --> E
        L --> M
    end

    Chart --> V["FamilyTree::ChartComponent"]
    V --> Ed["EdgesComponent (SVG)"]
    V --> Cards["PersonCardComponent × people<br/>absolute: x·SLOT, generation·ROW"]
    V --> Ex["ExpandButtonComponent × flags<br/>link: same URL + one more id + #anchor"]

    V -->|HTML| Frame["turbo-frame#chart in the public layout"]
    Frame --> Z["tree-zoom Stimulus controller<br/>CSS zoom on the wrapper, drag pans the scroll container"]
    Ex -.->|"click → frame fetch"| URL
```

### Edit mode (chunk 3)

```mermaid
flowchart LR
    Card["PersonCardComponent"] --> Menu["popover action menu<br/>(native, links only)"]
    Menu --> Dlg["dialog holding a turbo-frame<br/>(Stimulus: showModal)"]
    Dlg -->|"POST/PUT/DELETE"| Ctl["FamilyTree::*Controller"]
    Ctl --> Mut["FamilyTree::Mutations"]
    Ctl -->|"redirect to the tree URL"| Frame["turbo-frame#chart reloads"]
    Ctl -->|"422"| Dlg
```