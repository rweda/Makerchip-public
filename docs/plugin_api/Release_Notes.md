# Release Notes

Version history for the Makerchip Plugin API, tracked by the static
`IdePlugin.version` property. The API follows semantic versioning: the major
version is bumped for breaking (backward-incompatible) changes.

## 2.2.0

External waveforms: `loadVcd()` loads a VCD trace (e.g. from simulating a non-TL-Verilog model) and locks
the waveform to it, so VIZ (from compiled TL-Verilog) renders from it; `unlockVcd()` reenables simulation,
and `getWaveformStatus()` reports the lock. While locked, `compile()` defaults to not simulating.

`compile()`'s second argument is now documented as the options object (`{sim, dot}`) that it has
effectively always been; a Boolean (giving `sim`) is still accepted and, previously, was ignored.

## 2.1.0

"Panes" are now **views**, matching common IDE terminology. Methods and layout-state keys are renamed
accordingly: `openPane` → `openView`, `activatePane` → `activateView`, `openThirdPartyPane` →
`openThirdPartyView`, `reservePane` → `reserveView`, `getAvailablePanes` → `getAvailableViews`,
`fitPane` → `fitView`, `callPane` → `callView`, and `panes`/`activePane` → `views`/`activeView`.
The old names remain as deprecated `ide.api` aliases, and layout state using the old keys is still accepted.

The IDE now asks the user to accept the Makerchip Terms of Service and Privacy Policy. To avoid
asking again, remember the acceptance reported by the new `onTermsAccepted()` hook and pass it back
via the new `termsAcceptedAt` option (see the [README](README.md)).

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
