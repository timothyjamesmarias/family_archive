# Frontend

Two tiers of client-side code, deliberately kept separate.

```
app/frontend/
├── entrypoints/
│   ├── application.js      Turbo + Stimulus. Loaded on every page.
│   ├── application.css     Tailwind.
│   └── dashboard.tsx       One entrypoint per React page-app.
├── controllers/            Stimulus controllers (small islands). Plain JS.
└── apps/
    └── dashboard/          React page-app source. TypeScript.
```

## Tier 1 — Stimulus controllers

Behavior attached to server-rendered markup. The DOM is the source of truth.
Files named `*_controller.js` in `controllers/` register automatically:
`copy_button_controller.js` becomes `data-controller="copy-button"`.

## Tier 2 — React page-apps

A page hands a single empty node to React, which owns everything inside it.
Each app gets its own Vite entrypoint so React ships only on pages that use it.

```erb
<% content_for :react_app do %>
  <%= vite_javascript_tag "dashboard.tsx" %>
<% end %>

<div id="dashboard-app" data-props="<%= @props.to_json %>"></div>
```

Props are declared in the app's `types.ts` — that type is the contract with the
Rails controller. Note that `JSON.parse(...) as Props` at the mount point is an
assertion, not a check: if the server renames a key, TypeScript stays happy and
React gets `undefined`. Add runtime validation there once an app has a real API
boundary.

Using `content_for :react_app` also emits `<meta name="turbo-visit-control"
content="reload">`, which is what keeps the two tiers from colliding.

## The three rules

**1. A page is either a Turbo page or a React page, never both.**

Turbo Drive caches a snapshot of rendered HTML. If it cached a React-owned
subtree, back-navigation would paint stale markup and then React would remount
with fresh state — the user sees their filled-in form for a beat, then an empty
one. `turbo-visit-control: reload` forces a real page load instead.

**2. Stimulus controllers never reach inside a React container.**

Two systems mutating the same nodes is the same conflict in miniature. If a
Stimulus controller needs to talk to a React app, dispatch a DOM event on a
shared ancestor and let React listen.

**3. Server-pushed updates follow ownership.**

Turbo Streams may target server-rendered DOM only. React apps subscribe to
their own channel and receive JSON, then update their own state. Nothing pushes
HTML into a React-owned subtree.

## Persisting state across navigation

React page-apps unmount on navigation — that is the point. If state needs to
survive (a half-finished multi-step form), persist it deliberately:
`sessionStorage`, a server-side draft, or URL params. Do not rely on Turbo's
snapshot cache to do it.
