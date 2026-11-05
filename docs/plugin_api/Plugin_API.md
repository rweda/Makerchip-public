# Makerchip Plugin API Data Structures

This document specifies the data structures used by the **[Makerchip Plugin API](README.md)** —
the API by which an external host embeds and controls the IDE. It augments the
[Plugin API README](README.md) and the Codo-generated API documentation.

> **Looking for third-party *views*?** Creating views that live *inside* the IDE, and the
> event channel by which they communicate with the IDE and other views, are documented
> separately in the **[Third-Party View API](Third_Party_View_API.md)**. See that document
> for the distinction between the two integration surfaces.

## API Overview

The Makerchip Plugin API provides programmatic control over the IDE, enabling:

- **Code Management**: Load, retrieve, and compile TL-Verilog code
- **Layout State**: Save, restore, and transfer IDE layout configurations between instances
- **Third-Party Views**: Inject custom content (PDFs, web pages) into the tabbed interface
  (see the [Third-Party View API](Third_Party_View_API.md))
- **View Control**: Open, activate, and manage IDE views
- **Visualization Export**: Export VIZ view diagrams as images
- **Navigation Integration**: Handle line navigation requests from the IDE

This document focuses on the data structures for **layout state**, which require detailed
specification. For other API capabilities, see the Codo-generated documentation and the
[README](README.md) for usage examples.

## Third-Party Views

Third-party views (custom content injected into the IDE's tabbed interface, created via
`openThirdPartyView()`) have their own dedicated documentation:
**[Third-Party View API](Third_Party_View_API.md)**. It covers construction parameters,
content types, uniquification, the security model, and the inter-view communication
channel. The layout-state structures below reference the third-party view *object* used to
persist such views.

## Layout State Structure

### Overview

In the Makerchip IDE TabbedViews hold views, and a binary tree of FlexSplits defines the layout of these TabbedViews. The layout state can be programmatically manipulated.

To save and restore or transfer layouts:

```javascript
// Save layout for cross-instance recovery (includes third-party views)
const state = await ide.api.getLayoutState({ forTransfer: true });
localStorage.setItem('savedLayout', JSON.stringify(state));

// Later, restore the saved layout
const saved = JSON.parse(localStorage.getItem('savedLayout'));
await ide.api.setLayoutState(saved);
// Transferrable third-party views will be recreated automatically

// Transfer layout between IDE instances
const layout = await ide1.api.getLayoutState({ forTransfer: true });
await ide2.api.setLayoutState(layout);
// Only transferrable third-party views transfer to the new instance
```

### Restoring

`setLayoutState()` detaches the current layout, then walks the given state to ensure every view it
names is present before rebuilding the tree:

- **Built-in and static views** are opened on demand if they are not already open.
- **Third-party views** are recreated from their construction data (`contentParams`, together with
  `channel` and `params`). A view already open under the same mnemonic is reused as-is, unless its
  `contentType` or `contentParams` differ from the state's — then it is closed and recreated.
- **A third-party entry carrying no construction data** (`contentParams: null`, i.e. a view opened
  `nonTransferrable`) cannot be recreated. It is honored only where a view of that mnemonic is
  already open; otherwise it is dropped.

A view that cannot be reconstructed is dropped rather than failing the restore: the layout is built
from whatever remains, and the user is alerted once with the list of views that were dropped.

Recreating a view is an *open*, so the participant calling `setLayoutState()` becomes the `creator`
of every view restored by that call — at the Plugin API boundary, `platform`, or `platform.<agent>`
when the platform restores on an agent's behalf. Provenance is never copied out of captured state: a
restored view's `creator` records who restored it rather than who opened it in the captured session,
and its `origin`/`author` stamps are re-derived from the restored `contentUrl` (see
[Wire versioning and trust stamps](Third_Party_View_API.md#wire-versioning-and-trust-stamps) in the
Third-Party View API).

### Node Types

The layout tree consists of:

#### FlexSplit Node

Represents a resizable split (horizontal or vertical):

```typescript
{
  sides: {
    left: LayoutNode,      // For horizontal splits
    right: LayoutNode,
    // OR
    top: LayoutNode,       // For vertical splits
    bottom: LayoutNode
  },
  splitAt: number          // Split position: 0.0 to 1.0
}
```

- **`sides`**: Object containing child nodes
  - `left` + `right`: Horizontal split
  - `top` + `bottom`: Vertical split
- **`splitAt`**: Normalized position of the splitter (0.0 = far left/top, 1.0 = far right/bottom)

#### TabbedView (Leaf) Node

Represents a tabbed container of views:

```typescript
{
  views: Array<string | ThirdPartyViewObject>,
  activeView: string
}
```

- **`views`**: Array of view identifiers (see [View Identifiers](#view-identifiers))
- **`activeView`**: Mnemonic of the currently visible view

### View Identifiers

Entries in the `views` array can be:

#### String Mnemonic

A view mnemonic (string):

- Built-in views: `"Log"`, `"Nav-TLV"`, `"Diagram"`, `VIZ`, `"Waveform"`
- Static views: `"Examples"`, `"Courses"`, etc.
- Third-party views accessed with `nonTransferrable: true`.

#### Third-Party View Object

A third-party view accessed with a `forTransfer: true` option provides:

```typescript
{
  mnemonic: string,
  contentType: "pdf" | "iframe",
  contentParams: {
    contentUrl: string
  } | null,
  channel?: ChannelContract,   // present for a connected view
  params?: object              // present for a parameterized view
}
```

- **`mnemonic`**: Unique view identifier (may include `+XXX` suffix for uniquification)
- **`contentType`**: Content renderer type
- **`contentParams`**: Content-type-specific parameters (see [Content parameters](Third_Party_View_API.md#content-parameters) in the Third-Party View API)
  - **`null`** for non-transferrable views (see [Options](Third_Party_View_API.md#options)). Such an
    entry records the view's position, but carries nothing to rebuild it from — see
    [Restoring](#restoring)
- **`channel`** / **`params`** (optional): the view's persisted communication contract and view-specific parameters (see [Options](Third_Party_View_API.md#options) in the Third-Party View API)

### Layout State Structure Example

```javascript
{
  sides: {
    left: {
      views: ["Editor", "Nav-TLV"],
      activeView: "Editor"
    },
    right: {
      sides: {
        top: {
          views: [
            "Diagram",
            { // transferrable third-party view with construction data:
              mnemonic: "User Guide",
              contentType: "pdf",
              contentParams: {contentUrl: "https://example.com/guide.pdf"}
            }
          ],
          activeView: "Diagram"
        },
        bottom: {
          views: ["Waveform", "Log"],
          activeView: "Waveform"
        }
      },
      splitAt: 0.6
    }
  },
  splitAt: 0.3
}
```

This represents:

- Root horizontal split at 30%
- Left side: Tabs with Editor and Nav-TLV (Editor active)
- Right side: Vertical split at 60%
  - Top: Tabs with Diagram and third-party PDF view (Diagram active)
  - Bottom: Tabs with Waveform and Log (Waveform active)
