# Makerchip Plugin API Data Structures

This document specifies the data structures used by the **[Makerchip Plugin API](README.md)** —
the API by which an external host embeds and controls the IDE. It augments the
[Plugin API README](README.md) and the Codo-generated API documentation.

> **Looking for third-party *panes*?** Creating panes that live *inside* the IDE, and the
> event channel by which they communicate with the IDE and other panes, are documented
> separately in the **[Third-Party Pane API](Third_Party_Pane_API.md)**. See that document
> for the distinction between the two integration surfaces.

## API Overview

The Makerchip Plugin API provides programmatic control over the IDE, enabling:

- **Code Management**: Load, retrieve, and compile TL-Verilog code
- **Layout State**: Save, restore, and transfer IDE layout configurations between instances
- **Third-Party Panes**: Inject custom content (PDFs, web pages) into the tabbed interface
  (see the [Third-Party Pane API](Third_Party_Pane_API.md))
- **Pane Control**: Open, activate, and manage IDE panes
- **Visualization Export**: Export VIZ pane diagrams as images
- **Navigation Integration**: Handle line navigation requests from the IDE

This document focuses on the data structures for **layout state**, which require detailed
specification. For other API capabilities, see the Codo-generated documentation and the
[README](README.md) for usage examples.

## Third-Party Panes

Third-party panes (custom content injected into the IDE's tabbed interface, created via
`openThirdPartyPane()`) have their own dedicated documentation:
**[Third-Party Pane API](Third_Party_Pane_API.md)**. It covers construction parameters,
content types, uniquification, the security model, and the inter-pane communication
channel. The layout-state structures below reference the third-party pane *object* used to
persist such panes.

## Layout State Structure

### Overview

In the Makerchip IDE TabbedViews hold panes, and a binary tree of FlexSplits defines the layout of these TabbedViews. The layout state can be programmatically manipulated.

To save and restore or transfer layouts:

```javascript
// Save layout for cross-instance recovery (includes third-party panes)
const state = await ide.api.getLayoutState({ forTransfer: true });
localStorage.setItem('savedLayout', JSON.stringify(state));

// Later, restore the saved layout
const saved = JSON.parse(localStorage.getItem('savedLayout'));
await ide.api.setLayoutState(saved);
// Transferrable third-party panes will be recreated automatically

// Transfer layout between IDE instances
const layout = await ide1.api.getLayoutState({ forTransfer: true });
await ide2.api.setLayoutState(layout);
// Only transferrable third-party panes transfer to the new instance
```

### Restoring

`setLayoutState()` detaches the current layout, then walks the given state to ensure every pane it
names is present before rebuilding the tree:

- **Built-in and static panes** are opened on demand if they are not already open.
- **Third-party panes** are recreated from their construction data (`contentParams`, together with
  `channel` and `params`). A pane already open under the same mnemonic is reused as-is, unless its
  `contentType` or `contentParams` differ from the state's — then it is closed and recreated.
- **A third-party entry carrying no construction data** (`contentParams: null`, i.e. a pane opened
  `nonTransferrable`) cannot be recreated. It is honored only where a pane of that mnemonic is
  already open; otherwise it is dropped.

A pane that cannot be reconstructed is dropped rather than failing the restore: the layout is built
from whatever remains, and the user is alerted once with the list of panes that were dropped.

Recreating a pane is an *open*, so the participant calling `setLayoutState()` becomes the `creator`
of every pane restored by that call — at the Plugin API boundary, `platform`, or `platform.<agent>`
when the platform restores on an agent's behalf. Provenance is never copied out of captured state: a
restored pane's `creator` records who restored it rather than who opened it in the captured session,
and its `origin`/`author` stamps are re-derived from the restored `contentUrl` (see
[Wire versioning and trust stamps](Third_Party_Pane_API.md#wire-versioning-and-trust-stamps) in the
Third-Party Pane API).

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

Represents a tabbed container of panes:

```typescript
{
  panes: Array<string | ThirdPartyPaneObject>,
  activePane: string
}
```

- **`panes`**: Array of pane identifiers (see [Pane Identifiers](#pane-identifiers))
- **`activePane`**: Mnemonic of the currently visible pane

### Pane Identifiers

Entries in the `panes` array can be:

#### String Mnemonic

A pane mnemonic (string):

- Built-in panes: `"Log"`, `"Nav-TLV"`, `"Diagram"`, `VIZ`, `"Waveform"`
- Static panes: `"Examples"`, `"Courses"`, etc.
- Third-party panes accessed with `nonTransferrable: true`.

#### Third-Party Pane Object

A third-party pane accessed with a `forTransfer: true` option provides:

```typescript
{
  mnemonic: string,
  contentType: "pdf" | "iframe",
  contentParams: {
    contentUrl: string
  } | null,
  channel?: ChannelContract,   // present for a connected pane
  params?: object              // present for a parameterized pane
}
```

- **`mnemonic`**: Unique pane identifier (may include `+XXX` suffix for uniquification)
- **`contentType`**: Content renderer type
- **`contentParams`**: Content-type-specific parameters (see [Content parameters](Third_Party_Pane_API.md#content-parameters) in the Third-Party Pane API)
  - **`null`** for non-transferrable panes (see [Options](Third_Party_Pane_API.md#options)). Such an
    entry records the pane's position, but carries nothing to rebuild it from — see
    [Restoring](#restoring)
- **`channel`** / **`params`** (optional): the pane's persisted communication contract and pane-specific parameters (see [Options](Third_Party_Pane_API.md#options) in the Third-Party Pane API)

### Layout State Structure Example

```javascript
{
  sides: {
    left: {
      panes: ["Editor", "Nav-TLV"],
      activePane: "Editor"
    },
    right: {
      sides: {
        top: {
          panes: [
            "Diagram",
            { // transferrable third-party pane with construction data:
              mnemonic: "User Guide",
              contentType: "pdf",
              contentParams: {contentUrl: "https://example.com/guide.pdf"}
            }
          ],
          activePane: "Diagram"
        },
        bottom: {
          panes: ["Waveform", "Log"],
          activePane: "Waveform"
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
  - Top: Tabs with Diagram and third-party PDF pane (Diagram active)
  - Bottom: Tabs with Waveform and Log (Waveform active)
