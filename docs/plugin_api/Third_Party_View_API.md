# Third-Party View API

> **Plugin API vs. Third-Party View API.** These are two distinct integration
> surfaces, and it is worth being clear about which one you need:
>
> - The **[Makerchip Plugin API](README.md)** lets an *external host* (a web app, a
>   VS Code extension) **embed the Makerchip IDE** and drive it from the
>   outside (load code, compile, capture layout, open views, …). The host is the parent;
>   the IDE is the guest.
> - The **Third-Party View API** (this document) is the mirror image: it lets a
>   **third party contribute a view that lives *inside* the IDE**, rendered as an
>   `iframe` in the tabbed layout, and — via the communication channel described
>   below — participate in the IDE's event flow alongside built-in views. Here the IDE
>   is the parent; the view is the guest.
>
> A single deployment routinely uses both at once (e.g. a VS Code extension embeds the
> IDE *via the Plugin API*, and that IDE hosts a Compiler Explorer *third-party view*).

This document has five sections:

1. **[View construction](#view-construction)** — how third-party views are created,
  uniquified, and configured.
2. **[Communication channel](#communication-channel)** — how a third-party view
   exchanges events with the IDE (via pub/sub on the bus and request/response RPC) and
   with other views (and, TODO: non-view participants).
3. **[Persistence](#persistence)** — how transferrable views are captured and restored.
4. **[Security model](#security-model)** — the current trust model and isolation notes.
5. **[Licensing and independence](#licensing-and-independence)** — the legal relationship
   between views and the IDE.

---

## View construction

Third-party views inject external content (PDFs, web pages) into the IDE's tabbed
interface. They are created via `openThirdPartyView()`.

### Method signature

```typescript
openThirdPartyView(
  requestedMnemonic: string,
  contentType: "pdf" | "iframe",
  contentParams: ContentParams,   // content-type-specific parameters
  options?: OpenOptions,
  agent?: string                  // optional; attributes the open to "platform.<agent>"
): Promise<string>
```

Returns the view's actual mnemonic, which may differ from `requestedMnemonic` if it had
to be uniquified.

### Content parameters

#### PDF content (`contentType: "pdf"`)

```typescript
{ contentUrl: string }
```

**`contentUrl`** — URL to a PDF file. The bundled viewer's own origin check is disabled, but
the sandbox CSP still governs the fetch (`connect-src 'self' https: blob:`), so in practice:
`https://`, `blob:`, and same-origin URLs work. `file://` does **not** — browsers block local-file
loads from an `http(s)` document beneath CSP, so no CSP change can enable it. `http://` is upgraded/blocked, and `data:` is not in
`connect-src`. To present a local file, pass its bytes as a `blob:` URL.

```javascript
await ide.api.openThirdPartyView(
  "User Guide", "pdf",
  { contentUrl: "https://example.com/guide.pdf" }
);
```

#### Iframe content (`contentType: "iframe"`)

```typescript
{ contentUrl: string }
// or
{ sourceUrl: string, rewriteRelativeUrls?: boolean }
```

- **`contentUrl`** — URL to embed. Subject to browser same-origin and CSP policies, and
  must permit framing (no `X-Frame-Options: DENY` / restrictive `frame-ancestors`).
  The IDE frames only `https:`, `data:`, and `blob:` URLs, so serve a local view over HTTPS. A
  `frame-ancestors` policy must allow every ancestor, which in the Makerchip VS Code extension
  includes `vscode-webview:` and `vscode-file:` (not matched by `*`).
  The frame is sandboxed: scripts, forms, modals, popups and downloads work, but the view cannot
  navigate the IDE's top window, and a `blob:` view runs at an opaque (`null`) origin. A `data:`
  or `blob:` page inherits the IDE's Content Security Policy, which allows inline and `https:`
  scripts.
- **`sourceUrl`** — instead of `contentUrl`: the URL of an HTML *file* that is not served as a
  page, such as one on `raw.githubusercontent.com` (which serves it as `text/plain`). The IDE
  fetches it (through its CORS proxy if need be) and frames it from a `blob:` URL, so the view
  runs at an opaque origin: no `localStorage`, IndexedDB or cookies (accessing them throws), and
  its requests carry `Origin: null`, so it can `fetch` only CORS-`*` resources. Keep state in the
  IDE (e.g. [`params`](#view-parameters)). `sourceUrl` is what is persisted, so a restored view
  fetches again. **Pin a commit SHA** rather than a branch: a branch's content changes under a
  saved layout, and caches lag unpredictably (jsDelivr can serve a stale branch for days).
- **`rewriteRelativeUrls`** — with `sourceUrl`, opt in to resolving the page's relative URLs. By
  default they don't resolve, so only a self-contained page (inline or absolute-URL assets)
  works. With this set, the IDE adds a `<base href>` for `sourceUrl`'s directory, unless the page
  has its own `<base>`. A GitHub raw source gets its jsDelivr mirror instead
  (`https://cdn.jsdelivr.net/gh/<owner>/<repo>@<ref>/<dir>/`), because raw serves scripts and
  stylesheets as `text/plain`, which browsers refuse. This helps only where the host serves assets
  with correct types (GitLab raw, for one, doesn't), and relative links to other pages still
  won't render on jsDelivr, which serves HTML as `text/plain`.

> `contentParams` carries **only** content-type-specific parameters. The communication
> [`channel`](#communication-channel) contract and view-specific
> [`params`](#view-parameters) are renderer-independent and are supplied
> via [`options`](#options) instead.

```javascript
await ide.api.openThirdPartyView(
  "API Docs", "iframe",
  { contentUrl: "https://docs.example.com" }
);
await ide.api.openThirdPartyView(
  "My View", "iframe",
  { sourceUrl: "https://raw.githubusercontent.com/<owner>/<repo>/<sha>/view/index.html",
    rewriteRelativeUrls: true }
);
```

### Options

The optional fourth argument groups two kinds of settings — transient open behavior, and
persisted, renderer-independent configuration:

```typescript
{
  // Transient (affect this open call only; NOT persisted):
  background?: boolean,        // default false — if true, do not activate immediately
  nonTransferrable?: boolean,  // default false — if true, construction data is not stored
                               //   (saves memory; view cannot be recovered via getLayoutState())

  // Persisted with the view (survive save / restore / cross-instance transfer,
  // unless nonTransferrable); apply to iframe AND pdf views:
  channel?: ChannelContract,   // communication contract — see “Communication channel”
  params?: object              // view-specific parameters made available to the view —
                               //   see “View parameters”
}
```

**`channel`** and **`params`** apply to both `iframe` and `pdf` views. Unlike `background` /
`nonTransferrable`, they are **persisted** with the view so a restored view is reconstructed
identically.

For a `pdf` view the channel client is not author-supplied code: it is Makerchip's own bridge,
injected into the PDF.js viewer bundle by `bin/install_pdfjs.sh`. A PDF can only contribute
**static link strings** (currently as an experimental feature, subject to change) so it expresses intent through a sentinel URL that the bridge intercepts and relays:

```latex
\href{https://makerchip.com/_bus?rpc=openExample&code_url=https://.../fifo.tlv}{Open in Makerchip}
```

Ordinary links are untouched. Everything the PDF can express remains bounded by the view's
`produces` contract and the IDE's inward RPC whitelist, exactly as for an iframe view.

### Mnemonics and uniquification

A mnemonic is a display name (used as the tab label) with an optional `+`-delimited
uniquifier. Uniqueness is enforced for third-party views: on collision, a `+#` / `-#`
suffix is appended. Collisions are compared case-insensitively with special characters mapped to `-`.

```javascript
const m1 = await ide.api.openThirdPartyView("Guide", "pdf", {...}); // "Guide"
const m2 = await ide.api.openThirdPartyView("Guide", "pdf", {...}); // "Guide+2"
```

Always use the **returned** mnemonic for subsequent API calls:

```javascript
const mnemonic = await ide.api.openThirdPartyView(...);
await ide.api.activateView(mnemonic);
```

The full view mnemonic is also the view's **identity on the communication channel** (see
below). At times it is necessary to know a view's mnemonic before opening it. `reserveView()`
resolves a view's mnemonic ahead of creating the view:

```typescript
reserveView(requestedMnemonic: string): Promise<string>   // → the actual (uniquified) mnemonic
```

It uniquifies `requestedMnemonic` against existing views (and outstanding reservations), reserves the resulting mnemonic, and returns it. A later `openThirdPartyView()` (or
`initThirdPartyView()`) called with that exact mnemonic is then guaranteed to return it
**unchanged** — the reservation is consumed as the view is created.

An unused reservation persists for the session. (TODO: a future `closeThirdPartyView()` will release reservations as well as close open views).
<!-- TODO(issues/044-close-or-replace-third-party-view.md) -->

### View parameters

`params` is an opaque, structured-clone-safe, and (because it is persisted)
JSON-serializable object of view-specific configuration — for example, a WARP-V
configurator's default settings. An iframe view pulls its `params` on demand (e.g., for initialization) via the
**`getContext` RPC** (see [View → IDE RPC](#view--ide-rpc)):

```javascript
const { params } = await callIde("getContext");  // callIde() as in "A tiny client" below.
```

`params` are persisted automatically across layout save/restore for transferrable views. The reloaded view repeats its initialization using `getContext`.

For example, a Compiler Explorer view is opened pre-set to emit RISC-V assembly:

```javascript
ide.openThirdPartyView("Compiler Explorer", "iframe",
  { contentUrl: "https://compiler-explorer.example/" },
  { channel: { produces: ["sourceAsm"], subscribes: [], rpc: true },
    params: { ce: { language: "c", compiler: "rv32-cgcc1430",
                    options: "-O2 -march=rv32i -mabi=ilp32",
                    source: "int fib(int n){ ... }",
                    filters: "directives,labels,commentOnly" } } });
```

The Compiler Explorer view reads `params.ce` from the `getContext` result and translates it into its own native
initial-state mechanism (here, a Compiler Explorer share-link URL). The `params` shape is
entirely the view's own convention; the IDE treats it as opaque.

> Alternatively, a view author may encode configuration directly in the `contentUrl` (query
> string or hash fragment) and read it synchronously at load. This needs no support from the
> IDE — the URL is part of `contentParams` and so is carried across save / restore / transfer
> like any other content parameter — and is entirely the view's own convention. `params` is
> often preferable when the iframe is loaded from a blob URL, where `contentUrl` is best kept
> as an opaque handle to the iframe content rather than as the configuration channel.

## Communication channel

> A connected iframe view can publish and receive bus events, and
> can call a bounded IDE RPC surface (view-scoped methods plus the safe subset of Plugin API
> operations). Both are carried over `postMessage` by a per-view connector.

The channel is carried on an **IDE-level event bus**. Built-in views already participate in
IDE events, and third-party views join that flow through explicitly declared contracts.
Filtering happens outside the iframe: large payloads are never delivered to views that did
not subscribe to them, and undeclared outbound events are dropped.

### Channel overview

A connected view declares its event contract in [`options.channel`](#options), persisted
with the view:

```typescript
type ChannelContract = {
  produces: string[]
  subscribes: Array<{ type: string, sources?: string[] }>
  rpc?: boolean
}
```

- **`produces`** is the outbound whitelist: event types this view may publish.
- **`subscribes`** is the inbound whitelist: event types this view wants delivered.
- **`sources`** optionally narrows a subscription to specific view mnemonics; omit it to
  accept that event type from any producer. (Sources can also be filtered internally.)
- **`rpc`** opts the view into view → IDE RPC. It is a coarse, all-or-nothing capability:
  with `rpc: true` the view may call any whitelisted IDE method; without it (the default)
  RPC requests are refused with an `rpc-error`.

Bus events carry application payloads between views. View → IDE RPC uses the same
`postMessage` connector for request/response calls, but never touches the bus.

### Identities

An identity names a bus participant — it is what appears in `source`, `target`, and a
subscription's `sources`. A view's channel identity is its full mnemonic. If a contract needs
a specific view in `subscribes[].sources`, reserve that mnemonic before opening views with
[`reserveView()`](#mnemonics-and-uniquification). If the subscriber accepts any producer of
an event type, omit `sources`. The reserved identity **`ide`** names the host IDE itself.

The mirror-image reserved identity **`platform`** names the **embedding host** — the outside
application, VS Code extension, or AI agent that embeds the IDE via the [Plugin
API](README.md) — and is the source stamped when the host publishes onto the bus. Where the
host relays an action on behalf of a *less-trusted* agent, it stamps **`platform.<agent>`**
(e.g. `platform.ai` for a relayed AI action), so recipients can distinguish first-hand host
events from relayed ones. A subscriber accepts host events by listing `platform` (or a
specific `platform.<agent>`) in `subscribes[].sources`; to accept the whole family it omits
`sources`, which matches any source (`platform` and every `platform.<agent>` alike). Like a
view, the `platform` identity is stamped by the IDE and cannot forge the reserved `ide`
identity. The host publishes and calls views through the Plugin API's `busEmit` (broadcast,
as `platform` / `platform.<agent>`) and `callView` (host→view RPC); see the `IdePlugin`
methods of the same name for their signatures.

### Event types

An event type is the `type` string an event travels under — it is what appears in `produces`,
a subscription's `type`, and the emitted envelope. Application event types are named directly
by their `type` (e.g. `sourceAsm`). Until a [registry](#registry) defines shared types, custom
types should be named under the owning view's mnemonic — `<mnemonic>/<type>` — to avoid
collisions. [First-party events](#first-party-events) use plain types and are distinguished by
the reserved `ide` source.

### Registry

A future public registry is expected to define stable view **identities** and shared **event
types**, and to reserve/govern both namespaces — so views can target well-known identities and
agree on event types without the opener brokering every mnemonic inline. Until it exists,
channel contracts are supplied inline at view creation (see [Identities](#identities) and
[Event types](#event-types)).

### Bus events

Bus envelopes are structured-clone-safe plain objects:

```typescript
{
  v: 1,                          // wire-framing version (as negotiated; see below)
  source: string,                // stamped by the IDE; never trusted from the view
  origin?: string,               // IDE-stamped web origin of `source` (see below)
  author?: string,               // IDE-stamped responsible participant for `source` (see below)
  type: string,                  // e.g. "sourceAsm"
  payload: any,
  target?: string | string[]     // optional recipient whitelist
}
```

The `origin`/`author` trust stamps and the negotiated `v` are covered under
[Wire versioning and trust stamps](#wire-versioning-and-trust-stamps).

Example: Compiler Explorer publishes `sourceAsm`; WARP-V subscribes to that event from the
reserved CE instance.

```javascript
const ce    = await ide.api.reserveView("Compiler Explorer");
const warpv = await ide.api.reserveView("WARP-V");

await ide.api.openThirdPartyView(ce, "iframe",
  { contentUrl: "https://makerchip.com/ce/" },
  { channel: { subscribes: [], produces: ["sourceAsm"], rpc: true } });

await ide.api.openThirdPartyView(warpv, "iframe",
  { contentUrl: "https://warp-v.org/view/" },
  { channel: { subscribes: [ { type: "sourceAsm", sources: [ce] } ],
               produces:   ["warpvConfig"], rpc: true } });
```

Outbound delivery is: validate iframe window, check `produces`, stamp `source`, and publish the
event on the IDE bus. Inbound delivery is: match each connector's `subscribes`, then
`postMessage` only to matching views.

### First-party events

Besides view-to-view traffic, the host IDE itself publishes a few events on the same bus,
stamped with the reserved `ide` source. A view opts in by subscribing with
`sources: ["ide"]`. Two are available today:

| type | payload | when |
| --- | --- | --- |
| `theme` | `{ dark: boolean }` | The IDE's dark mode changes. The initial value is also available synchronously from [`getContext().theme`](#view--ide-rpc). |
| `compile-result` | `{ which, id, resultsUrl?, success?, artifacts? }` | A compile starts, and each stage completes (see below). |

`compile-result` reports Makerchip's build pipeline so a view can follow it live:

- **`which`** names the event: `"start"` when a new compile begins, or the stage that just
  finished — `"sandpiper"` (Verilog / model generation) or `"vcd"` (simulation waveform, only if "sandpiper" succeeds).
- **`id`** is the compile id (stable per compile).
- **`resultsUrl`** is the absolute URL of the compile's files. Resolve a file name against it, e.g.
  `new URL("top.sv", p.resultsUrl)`; the files are served with CORS. A file is available once its
  stage succeeds: the `artifacts` below after `"sandpiper"`, and `vlt_dump.vcd` after `"vcd"`.
  `resultsUrl` may be absent, in which case the compile's files are not available to views.
- **`success`** accompanies the stage events (except `"start"`) and is `true` if that stage
  succeeded. A failed `"sandpiper"` stage skips simulation, so no `"vcd"` event follows.
- **`artifacts`** accompanies a successful `"sandpiper"` stage: a map of model-run artifact
  filename → `boolean` (present) reporting which intermediates the compile actually produced —
  e.g. `top.m4.pre`/`top.m4` exist only when M5/M4 preprocessing ran, and `top_gen.sv` is absent
  when Verilog generation is inlined. Files downloaded by `m4_sv_include_url` or `m4_sv_get_url` are
  listed as `sv_url_inc/<path>`.

```javascript
on("compile-result", (env) => {
  const p = env.payload;
  if (p.which === "start") showBusy();
  else if (p.which === "sandpiper" && p.success && p.resultsUrl) {
    fetch(new URL("top.sv", p.resultsUrl)).then((r) => r.text()).then(showVerilog);
  }
});
```

### Lifecycle and wire protocol

The connector attaches its receive-listener synchronously when the view is created, before
the iframe loads. A view may emit immediately. Before the IDE delivers events **to** a view,
the view posts `{v:1, type:"ready", …}`; the IDE queues inbound deliveries until that control
message arrives. `ready` is handled locally and is never relayed onto the bus. RPC replies
are not gated behind `ready`, because the view initiated the request and is already
listening for the response. Post `ready` unconditionally, once your listener is attached: it is
never acknowledged, so a view that omits it is not refused but simply never served, and every
IDE→view request times out.

```text
view  ──postMessage({ type:"ready", … })─────────────────────────────▶  IDE
IDE   ──(flush queued deliveries)────────────────────────────────────▶  view
view  ──postMessage({ type:"sourceAsm", payload })───────────────────▶  IDE
view  ──postMessage({ kind:"rpc", id, target:"ide", method, args })──▶  IDE
IDE   ──postMessage({ kind:"rpc-result", id, result })───────────────▶  view
IDE   ──postMessage({ kind:"rpc-call", id, method, args })───────────▶  view
view  ──postMessage({ kind:"rpc-call-result", id, result })──────────▶  IDE
```

Every message also carries `v` (elided above); see
[Wire versioning and trust stamps](#wire-versioning-and-trust-stamps).

On view close or transfer, the connector tears down its listener; on restore, the persisted
[`channel`](#options) contract reconstructs an identical connector.

### View → IDE RPC

RPC requests use the same connector but never touch the IDE bus:

```typescript
// view → IDE request
{ v: 1, kind: "rpc", id: number | string, target: string, method: string, args?: any[] }
// IDE → view response
{ v: 1, kind: "rpc-result", id, result: any }
{ v: 1, kind: "rpc-error",  id, error: string }
```

`target` addresses the RPC destination. It is required, and only `"ide"` is supported today;
peer (view-to-view) targets are reserved for the future, so the field is part of the wire
format now to keep it stable. Any other value is rejected with an `rpc-error`.

RPC is a coarse, opt-in capability. A view may only call over RPC if its
[`channel`](#communication-channel) contract declares `rpc: true`; otherwise every request
is refused with an `rpc-error`.

Unlike the Plugin API exposed outward to a trusted embedding host, this inward-facing
surface is deliberately bounded. It comprises two things: a couple of *view-scoped* methods
(which need the calling view's identity, so they are not part of the Plugin API), plus a
proxy to the safe subset of Plugin API **operations**.

**View-scoped methods:**

| method | args | result |
| --- | --- | --- |
| `getContext` | — | `{ mnemonic: string, params: object \| null, theme: { dark: boolean }, wire: { min, max, selected } }` — the view's registered `params`, its own assigned mnemonic (seldom needed once reserved — see [Mnemonics and uniquification](#mnemonics-and-uniquification)), the IDE's current theme (thereafter tracked via the [`theme`](#first-party-events) event), and the negotiated [wire version](#wire-versioning-and-trust-stamps). |
| `setStatus` | `[status: string]` | `boolean` — sets **this** view's own tab-status indicator. `status` is one of the generic values below; an unknown value is ignored (returns `false`). |
| `getCompileStatus` | `[id?: string]` | `{ id, resultsUrl?, model, sim, artifacts? } \| null` — a compile's (by default, the latest compile's) recorded per-stage outcome, where `resultsUrl` is as in [`compile-result`](#first-party-events), `model` (Verilog / SandPiper) and `sim` (simulation) are each `"pending" \| "success" \| "fail"`, `artifacts` is the model run's artifact manifest (present once `model` succeeds; see [`compile-result`](#first-party-events)), or `null` if `id` is unknown. The [`compile-result`](#first-party-events) event is live-only; this lets a view opened *after* a compile reconstruct the state it missed instead of assuming success. |

Accepted `setStatus` values are — `"none"`, `"working"`, `"success"`, `"warning"`,
`"error"`, `"fail"`, `"timeout"`.

**Proxied Plugin API operations.** Views may also call a safe whitelisted subset of the Plugin API's
*operations* (host→IDE commands): `loadCode`, `getCode`, `getChangeGeneration`,
`getSettings`, `getCycle`, `setCycle`, `updatePlayState`, `highlight`, `clearHighlights`,
`setDarkMode`, `setLiveMode`, `openView`, `activateView`, `reserveView`, `getVizImage`,
`getKeyframe`, `getAvailableViews`.

Each takes the same positional arguments as the corresponding Plugin API method.
See `Plugin_API.md` (at the same path as this document) for details.

Two categories of Plugin API method are **not** exposed inward:

- The inbound compile-result delivery callbacks (`compilationId`, `compilationError`,
  `compilationGraph`, `compilationVcdStream`, `exitStatus`, `setLockedVCD`, …) — trusted
  pipeline inputs, so a view cannot inject forged results, waveforms, or diagrams.
- Cross-view / cross-boundary operations (`getLayoutState`, `setLayoutState`,
  `openThirdPartyView`, `extractPdfFigure`, `captureVideo`) — these would let a view read or
  tear down *other* views, spawn arbitrary views, or use the IDE's fetch capabilities.

### IDE → View RPC

The same `rpc: true` opt-in also lets the **IDE call the view** (host→view) — the request/response
complement to fire-and-forget bus events. The embedding host (e.g. an AI agent via the Plugin
API's `callView`) names a view it opened and a method the view exposes; the IDE forwards it over
that view's channel and returns the view's result. The IDE interprets neither the method nor the
arguments — the view defines and implements the callable surface.

```typescript
// IDE → view request
{ v: 1, kind: "rpc-call", id: number | string, method: string, args?: any[] }
// view → IDE response
{ v: 1, kind: "rpc-call-result", id, result: any }
{ v: 1, kind: "rpc-call-error",  id, error: string }
```

A view opts in by declaring `rpc: true` and implementing a handler; a request for an unknown
method (or to a view that never declared `rpc: true`) is answered with an `rpc-call-error`, and a
view that simply never replies is timed out on the caller's side. Requests are held until the view
posts `ready`, so nothing is lost at startup.

### Wire versioning and trust stamps

These fields extend the [envelope](#bus-events) and [lifecycle](#lifecycle-and-wire-protocol).

**Wire-version negotiation.** `v` is the wire-framing version — today always `1`, the permanent
floor. Every message carries it, and a message whose `v` the receiver does not understand is
dropped. `ready` precedes negotiation, so frame it at `v: 1`, which every IDE understands. In
`ready`, a view advertises the range it supports, and the IDE selects the highest common version
and reports it in the view's startup context:

```javascript
parent.postMessage({ v: 1, type: "ready", versions: { min: 1, max: 1 } }, "*");
const { wire } = await callIde("getContext");   // { min, max, selected }
```

Absence of `versions` means v1. If the ranges do not overlap, the IDE delivers no bus events to the
view (rather than frames it cannot parse). Each connector then frames outbound messages at, and
validates inbound messages against, the negotiated version; per-frame `v` remains as a redundant
guard. Because bus events fan out to participants that may run different versions, the Bus reframes
each event into the recipient's version at delivery (an L1 gasket), so a view never sees a foreign
`v` — a no-op while every participant is v1.

**Trust stamps.** Two envelope fields, `origin` and `author`, establish provenance so a recipient can authenticate a sender. They characterize a "responsible participant" — the bus participant responsible for sending the message. This may be the sender itself, or — when the sender has no web origin of its own (a blob/opaque URL) — the nearest participant in its creation chain that does. The chase stops at that first origin, never crossing to a more-trusted ancestor, so a stamp can never attribute an event past an origin boundary; a purely first-party chain resolves instead to `ide`, `platform` or `platform.<agent>`. Both are
resolved and stamped **by the IDE** and, like `source`, can never be set by a view:

```typescript
{
  // …
  origin?: string,   // web origin of the responsible participant (or absent if first-party or origin-less)
  author?: string    // responsible participant identifier, if different from source
}
```

**Recipient helpers.** The optional `@rweda/makerchip-view-client` library exposes the stamps on each
delivered message — `msg.origin` and `msg.sameOrigin()` (true when the sender shares the view's own
origin) — plus a static `sameOrigin(a, b)` for comparing two origins. Testing the sender's origin is
the usual trust check, and the message already carries it, so no argument is needed.

**Identity namespaces (future).** A sigil convention — `#`-prefixed mnemonics and `@`-prefixed
reserved identities (`@ide`, `@platform`) — will carve the identity space and leave the bare
namespace for registered identities. It is deferred to `issues/008-registered-view-identities.md`;
nothing above depends on it, since `author` already resolves to a reserved principal and `origin`
carries the web origin.

### A tiny client

Nothing is injected into your view; RPC and bus events are just the `postMessage` protocols
above. Most views should use the
[`@rweda/makerchip-view-client`](https://www.npmjs.com/package/@rweda/makerchip-view-client)
library, which implements them. Alternatively, this copy-paste snippet provides minimal RPC and
bus helpers.

```javascript
const V = 1;
let _rpcSeq = 0; const _rpcPending = new Map();
const _busHandlers = new Map();
const _rpcServed = new Map();
window.addEventListener("message", (e) => {
  const m = e.data; if (!m || m.v !== V) return;
  if (m.kind === "rpc-result") { _rpcPending.get(m.id)?.resolve(m.result); _rpcPending.delete(m.id); }
  else if (m.kind === "rpc-error") { _rpcPending.get(m.id)?.reject(new Error(m.error)); _rpcPending.delete(m.id); }
  else if (m.kind === "rpc-call") {
    const fn = _rpcServed.get(m.method);
    Promise.resolve(fn ? fn(...(m.args ?? [])) : Promise.reject(new Error(`no handler: ${m.method}`)))
      .then((result) => parent.postMessage({ v: V, kind: "rpc-call-result", id: m.id, result }, "*"))
      .catch((err) => parent.postMessage({ v: V, kind: "rpc-call-error", id: m.id, error: String(err?.message ?? err) }, "*"));
  }
  else if (typeof m.type === "string") { _busHandlers.get(m.type)?.forEach((fn) => fn(m)); }
});
function callIde(method, ...args) {
  const id = ++_rpcSeq;
  return new Promise((resolve, reject) => {
    _rpcPending.set(id, { resolve, reject });
    // target "ide" addresses the RPC destination; only "ide" is supported today.
    parent.postMessage({ v: V, kind: "rpc", id, target: "ide", method, args }, "*");
  });
}
const emit = (type, payload, target) => parent.postMessage({ v: V, type, payload, target }, "*");
const on = (type, fn) => {
  if (!_busHandlers.has(type)) _busHandlers.set(type, []);
  _busHandlers.get(type).push(fn);
};
// Register a method the IDE (or an AI agent via the Plugin API) may call on this view (rpc-call).
const serve = (method, fn) => _rpcServed.set(method, fn);
parent.postMessage({ v: V, type: "ready", versions: { min: V, max: V } }, "*");

// usage:
const { params } = await callIde("getContext");
on("sourceAsm", (env) => render(env.payload));
emit("warpvConfig", { xlen: 32 });
serve("runOnWarpV", async () => runAndReturnOutcome());
```

### Security and future surface

- **Identity is stamped, not asserted** — no view can spoof `source`.
- **`produces` bounds emission** and **`subscribes` bounds reception** — least privilege,
  enforced before messages cross the iframe boundary.
- **Origin/window validation** on every inbound message (trivial for same-origin,
  IDE-hosted views such as CE; the future registry records expected origins for external
  views).
- **Origin & author trust stamps** let a recipient authenticate a sender's web origin,
  and wire-version negotiation lets the protocol evolve without breaking views; see
  [Wire versioning and trust stamps](#wire-versioning-and-trust-stamps).
- **Versioned, structured-clone payloads**; an optional size cap guards against abuse.
- **RPC exposes an explicit safe subset of the Plugin API** — view-scoped methods plus a subset of the
  Plugin API *operations*. It excludes both the inbound compile-result callbacks (trusted
  pipeline inputs) and cross-view / cross-boundary operations (layout read/write, spawning
  views, arbitrary fetches). Exposure is safe-by-default: a newly added Plugin API method is
  not view-callable until added to the exposed operation list. Hardening the callbacks so they
  too could be exposed (e.g. via an IDE-minted compilation nonce) is future work.

More IDE state (e.g. highlights, view arrival/departure) can be exposed the same way as the
existing [first-party events](#first-party-events): published by the IDE under the `ide` source
where the state changes.

## Persistence

Transferrable third-party views are represented in layout state as a **third-party view
object** (`{mnemonic, contentType, contentParams, channel?, params?}`); see the
[Layout State structures](Plugin_API.md#view-identifiers) in the Plugin API data-structure
doc. On restore, the IDE recreates the view — including its persisted `channel` contract and
`params` — via `initThirdPartyView(mnemonic, contentType, contentParams, {channel, params})`.

## Security model

Some third-party views can execute arbitrary code within the IDE environment, similar to
the existing VIZ view which runs third-party JavaScript from libraries. The IDE will require
user confirmation before opening third-party views to establish trust (yet to be
implemented).

**PDF views (`contentType: "pdf"`)** are relatively trustworthy:

- Use the bundled PDF.js viewer (v5.4.624), modified to accept cross-origin PDFs and to host
  Makerchip's channel bridge.
- The bridge runs at the IDE's web origin while the content it presents is the untrusted PDF. A
  user-trust prompt must name the **content** origin, not the viewer's (TODO).
- Run in a sandboxed iframe with limited capabilities; cannot access sensitive IDE data,
  user credentials, or broader application state.
- Any PDF JavaScript is further sandboxed within PDF.js.
- Origin validation is disabled to support local files (`file://`, `vscode-webview://`) and
  external resources.
- Consistent with Makerchip's existing security model, which already executes arbitrary
  third-party JavaScript in VIZ views.

**Iframe views (`contentType: "iframe"`)** have broader capabilities:

- Subject to the browser same-origin policy and CSP restrictions.
- Can potentially interact with the IDE if not properly isolated; treat with caution when
  embedding untrusted content.
- When *connected*, a view's privileges are **explicitly bounded by its channel contract**
  (see [Security and future surface](#security-and-future-surface)).

**Cross-origin support.** The PDF.js viewer modification lets VS Code extensions and other
platforms load local PDFs and external documentation without origin restrictions,
facilitating seamless integration of reference material into the IDE workflow.

## Licensing and independence

Third-party views are independently authored applications. They run in isolated browsing
contexts and interact with the Makerchip IDE solely through the interoperability protocol
defined in this document. Integrating a view through this protocol does not transfer ownership
of either the view or the IDE, and does not alter the license of either: each remains governed
by its own terms, and each party is responsible for complying with the licenses of the software
it distributes or hosts. Integration implies no endorsement and grants no trademark rights.

This specification is licensed under
[Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).
The [`@rweda/makerchip-view-client`](https://www.npmjs.com/package/@rweda/makerchip-view-client)
library, which views may embed to speak this protocol, is licensed under the MIT License.
