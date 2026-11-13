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

### The chart (`/family-tree`)

The Builder and the queries are used as they are; `Chart` composes their
responses the way the old island's store did and decorates the order.

```mermaid
flowchart TD
    URL["GET /family-tree?depth=2&up[]=12&down[]=87#person-12"] --> C["FamilyTreeChartsController#show<br/>whitelists depth, keeps numeric ids"]
    C --> Chart

    subgraph Chart["FamilyTree::Chart"]
        direction TB
        I["Builder#initial_tree,<br/>then expand_tree(root, depth up and down) per root,<br/>then expand_tree(id) for each up[]/down[] once its person is on the chart;<br/>depth=all keeps expanding flagged people until nobody new arrives"]
        MG["merge like the island's store:<br/>first person wins, family ids union"]
        U["decorate: parents father-first by sex,<br/>children by child_order, families by id → Layout::Unit[]"]
        LY["FamilyTree::Layout → positions"]
        F["Card per person: position + expands_up?/expands_down?<br/>(hasUnloaded* flag and no relative drawn in that direction)"]
        I --> MG --> U --> LY --> F
    end

    Chart --> V["FamilyTree::ChartComponent<br/>toolbar (zoom, fit, centre, depth links, counts) + stage"]
    V --> E["FamilyTree::Edges (pixels via Metrics)<br/>bracket under a couple, drop, bus, stubs; lanes; direct links"]
    E --> Ed["EdgesComponent: one SVG path per kind"]
    V --> Cards["PersonCardComponent × cards<br/>left = Metrics.left(x), top = Metrics.top(generation)<br/>expand links: same URL + one id + #person-id"]

    V -->|HTML| Frame["turbo-frame#chart, turbo-action=advance"]
    Frame --> Z["tree-zoom Stimulus controller<br/>translate/scale transform on the stage: wheel zooms about the pointer,<br/>drag pans, fit and centre; view values live on the frame and survive a swap"]
    Cards -.->|"expand click → frame fetch"| URL
```

### Edit mode (chunk 3, `?edit=1` for a signed-in user)

A visitor with `?edit=1` gets the plain chart; the controller only grants
`:edit` when signed in, and every form requires a user.

```mermaid
flowchart LR
    Card["PersonCardComponent<br/>menu slot in edit mode"] --> Menu["ActionMenuComponent<br/>native details: Edit, Add child/spouse/parent,<br/>Link existing parent, Add sibling, Delete<br/>links carry return_to = the chart URL"]
    Menu -->|"GET, data-turbo-frame=tree_form"| Forms["FamilyTreePeopleController#edit/#delete<br/>FamilyTreeRelativesController#new (kind=…)<br/>EditDialogComponent + PersonFieldsComponent"]
    Forms --> Dlg["dialog.tree-dialog holding turbo-frame#tree_form<br/>tree-dialog controller: frame-load → showModal"]
    Dlg -->|"PATCH / POST / DELETE inside the frame"| Ctl["TreeEditing concern:<br/>authenticate, url_from(return_to), person fields → camelCase"]
    Ctl --> Mut["Individual::Editor<br/>FamilyTree::Mutations (unchanged)"]
    Ctl -->|"303 to return_to"| Visit["tree-dialog#refresh replays the redirect<br/>as a replace visit: new chart + flash"]
    Ctl -->|"DomainError → 422"| Dlg
```

## Planned

Nothing at the moment. The island, its JSON API under `/api/family-tree`
and the dagre/d3 dependencies were removed at cutover (chunk 4). Ideas the
design draws but no backend serves yet (hidden-relative counts on the expand
tabs, the selected-person panel, person search, linked-artifact badges) start
as new plan documents.