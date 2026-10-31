# Release Notes

Version history for the Makerchip Plugin API, tracked by the static
`IdePlugin.version` property. The API follows semantic versioning: the major
version is bumped for breaking (backward-incompatible) changes.

## 2.0.0

**Breaking:** instances are now created with the static `IdePlugin.create()`
factory instead of a promise-returning constructor.

```javascript
// Before (1.x)
const ide = await new MyIDE('my-makerchip');

// After (2.x)
const ide = await MyIDE.create('my-makerchip');
```

**Why:** a constructor that returned a `Promise` meant `new MyIDE(...)` did not
actually evaluate to a `MyIDE` — `instanceof` failed, and (per the JavaScript
spec) subclass field initializers attached to the returned Promise rather than
to the instance. The static factory returns the real instance (`new @` preserves
the concrete subclass type) and reads naturally as an async creation call.

**Migration:** replace `await new Subclass(id, options)` with
`await Subclass.create(id, options)`. There are no option or method changes.

## 1.0.0

Initial Makerchip Plugin API release.
