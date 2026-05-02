# Helpers/Extensions

Small, cross-cutting extensions on SwiftUI / UIKit / Foundation types.

## Rules for adding a new extension

1. **Name the file by purpose, not by OS version or mechanism.**
   - Good: `View+Geometry.swift`, `View+Compat.swift`, `Shape+Extensions.swift`.
   - Bad: `iOS26View+Extension.swift`, `View+Modifier+Extension.swift`.
   - Rationale: file names outlive any specific iOS version or Swift language
     feature. `iOS26...` files get stale every WWDC; concern-named files don't.

2. **One concern per file.** Pick the closest match below; make a new
   `View+<Concern>.swift` file if nothing fits. Don't pile into `View+Extension.swift`.

3. **Feature-specific helpers go with the feature, not here.** If a helper is
   only called by one demo, colocate it (`<Demo>/View/<Demo>Helpers.swift` or
   inside the demo file itself). See `View+FeatureHelpers.swift` for helpers
   that still need to be moved out.

4. **Deduplicate before adding.** `grep` the function name first. If a similar
   helper exists under a different name, either reuse it or consolidate.

## Current files

| File | Concern | Examples |
|---|---|---|
| `View+Animation.swift` | `Transaction`-based animation toggles | `withoutAnimation`, `noAnimation` |
| `View+AppStoreToolBar.swift` | App Store–style scroll-driven toolbar swap | `appStoreStyleToolBar` |
| `View+Compat.swift` | `if #available(iOS N, *)` shims + backports | `tryGlassEffect`, `customOnChange`, `isiOS26OrLater` |
| `View+FeatureHelpers.swift` | **Temporary** home for demo-specific helpers (should be moved) | `darkModeRect`, `didFrameChange`, `offsetY` |
| `View+Geometry.swift` | Generic geometry readers via PreferenceKey | `heightChangePreference`, `minXChangePreference` |
| `View+Visibility.swift` | Show/hide/fade/blur transitions | `hideWitOffset`, `hideWitScale`, `blurFade` |
| `Platform+View+Extension.swift` | `#if os(...)` branching | `platform(_:content:)` |
| `Shape+Extensions.swift` | Static factories on concrete shape types | `RoundedRectangle.rounded(...)` |
| `Text+Extension.swift` | `Text` styling helpers | — |
| `UIFont+Extension.swift` | UIKit font helpers | — |
| `UIView+Extension.swift` | UIKit view helpers (usually called from `UIViewRepresentable`) | `allSubViews`, `image(_:)` |
| `Comparable+Clamped.swift` | Numeric clamping | `BinaryFloatingPoint.clamped(to:)` |
| `Date+Extensions.swift` | `Date` formatting / math | — |
| `OffsetReader.swift` | Scroll offset reader view | — |
| `Snapshot.swift` | View → image snapshotting utilities | — |
| `ViewExtractor.swift` | Runtime view-tree extraction | — |

## Decision tree: "where does this extension go?"

```
Is it UIKit-only?
├─ UIView → UIView+Extension.swift
├─ UIFont → UIFont+Extension.swift
└─ other → new UI<Type>+Extension.swift

Is it SwiftUI View?
├─ branches on `if #available`?       → View+Compat.swift
├─ branches on `#if os(...)`?         → Platform+View+Extension.swift
├─ reads size / frame / offset?       → View+Geometry.swift
├─ show/hide/fade/blur transition?    → View+Visibility.swift
├─ wraps withTransaction / withAnimation? → View+Animation.swift
├─ used by exactly one demo?          → colocate with that demo (NOT here)
└─ genuinely new concern?             → new View+<Concern>.swift
```
