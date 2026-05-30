# PokemonPlay → The Composable Architecture (TCA) Migration Plan

A staged plan to convert this app from `@MainActor ObservableObject` + free-function networking to Point-Free's [The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture). Each stage ends with an explicit **validation point** so we can pause, review, and ship incrementally rather than as one big-bang rewrite.

> Today's snapshot (lines of code is the rough size of each piece):
>
> | Layer | Files | Notes |
> |---|---|---|
> | App entry | `PokemonPlayApp.swift` | Trivial; just hosts `ContentView`. |
> | UI | `ContentView.swift`, `View/*` (`PokemonDetailsView`, `JSONTreeView`, `StatsCard`, `Pills`, `EvolutionGraphView`, `ImageLabelListView`) | UI only — already pretty clean. |
> | State | `Data/DataStore/PokemonDataStore.swift` | Defines `PokemonDataStore` (cache) and `@MainActor PokemonViewModel: ObservableObject`. **This is the file TCA replaces.** |
> | Networking | `Networking/Services.swift`, `Networking/URLParsing.swift`, `Networking/OldServices+callback.swift` | Global free functions. **Will become a `@DependencyClient`.** |
> | Parsing | `Parser/JSONParser.swift`, `Parser/JSONValue.swift` | Pure value types — keep as-is, TCA-agnostic. |
> | Models | `Data/Pokemon*.swift` | Plain Codable / value types — keep as-is. |

---

## 0. Goals and non-goals

**Goals**
- Replace `PokemonViewModel: ObservableObject` with TCA `Reducer` + `Store`.
- Make every state transition a typed `Action` so the flow is explicit, testable, and recordable.
- Move networking behind a `@DependencyClient` so tests can swap in fakes without `URLProtocol` ceremony.
- Ship `TestStore` coverage for the search → load → display flow.
- Keep all existing UI primitives (`StatsCard`, `JSONTreeView`, `Pills`, etc.) untouched.

**Non-goals**
- Not changing the network protocol or API contract.
- Not changing the JSON parser internals.
- Not introducing TCA `Stack` navigation in stage 1 (deferred to stage 7 as optional).
- Not converting other animation projects in this repo — scope is `PokemonPlay/` only.

---

## 1. Packages to import

Add via Xcode → **File → Add Package Dependencies…** Add to the `PokemonPlay` target only (not the whole `animation` workspace).

| Package | URL | Min version | Why |
|---|---|---|---|
| **swift-composable-architecture** | `https://github.com/pointfreeco/swift-composable-architecture` | `1.15.0` (or latest 1.x) | The framework itself. Pulls in everything below transitively. |
| swift-dependencies | `https://github.com/pointfreeco/swift-dependencies` | (transitive) | `@Dependency`, `DependencyKey`, `@DependencyClient` macro. We'll explicitly use the macro. |
| swift-identified-collections | `https://github.com/pointfreeco/swift-identified-collections` | (transitive) | `IdentifiedArrayOf<T>` — replaces `[JSONNode]` so TCA can diff by id. |
| swift-perception | `https://github.com/pointfreeco/swift-perception` | (transitive) | Back-deploys `@Observable`-style observation; needed by TCA's `@ObservableState`. |
| swift-case-paths | `https://github.com/pointfreeco/swift-case-paths` | (transitive) | `@CasePathable` on enums; required for action enums to compose. |

**Optional, only if we hit specific needs:**

| Package | When to add |
|---|---|
| swift-tagged | If we want type-safe `Pokemon.Name` strings (e.g. `Tagged<Pokemon, String>`) — nice-to-have, not load-bearing. |
| swift-snapshot-testing | If we want snapshot tests of the new views. Optional in stage 6. |
| swift-clocks | If we add debounce/throttle to the search bar in stage 4. Otherwise skip. |

You only need to add **`swift-composable-architecture`** at the project level — the rest land automatically as transitive dependencies. The macros require **Swift 5.9+ / Xcode 15+** (project already requires Xcode 15+ for SwiftUI iOS 17 APIs).

---

## 2. Target architecture (before / after)

**Before**

```
ContentView
   ↳ @StateObject PokemonViewModel (ObservableObject, @MainActor)
        ↳ PokemonDataStore (in-memory cache + free-function calls)
              ↳ fetchAndWrapPokemonAsync(name:)
              ↳ fetchEvolutionChain(for:)
```

**After**

```
ContentView
   ↳ @Bindable store: StoreOf<AppFeature>
        ↳ AppFeature (Reducer)
             ├─ SearchFeature (Reducer)         // search bar + suggestions
             ├─ PokemonListFeature (Reducer)    // loaded nodes + cache
             └─ (optional) Path: StackState<PokemonDetailFeature.State>
        @Dependency(\.pokemonAPI) → PokemonAPIClient (@DependencyClient)
                                          ↳ live: wraps existing fetchAndWrap*/fetchEvolutionChain
                                          ↳ test: returns canned values per test
```

The cache currently held inside `PokemonDataStore` moves into `PokemonListFeature.State` (as `IdentifiedArrayOf<PokemonNode>` keyed by name). That makes it part of the reducer's pure value, which TestStore can assert against.

---

## 3. Stages

Each stage is a self-contained PR-sized chunk. Don't start the next stage until the validation point for the previous one passes.

### Stage 1 — Bootstrap TCA in the project

**Tasks**
- [ ] Open `animation.xcodeproj` in Xcode.
- [ ] File → Add Package Dependencies → paste `https://github.com/pointfreeco/swift-composable-architecture`. Pick **Up to Next Major** from the latest 1.x.
- [ ] Add to **PokemonPlay** target (NOT the main `animation` target).
- [ ] In one of the existing files (e.g. top of `PokemonPlayApp.swift`) add `import ComposableArchitecture` to confirm the module resolves.
- [ ] Build PokemonPlay scheme — must compile clean.

**Validation point ✅**
- Xcode shows the package in the file tree.
- `import ComposableArchitecture` resolves.
- `xcodebuild build -scheme PokemonPlay` succeeds with no warnings about the new dep.
- App still launches and behaves exactly as before (no behavior change in this stage).

---

### Stage 2 — Define `PokemonAPIClient` as a `@DependencyClient`

Goal: wrap the existing free functions (`fetchAndWrapPokemonAsync`, `fetchEvolutionChain`) behind a typed dependency. **Do not delete the originals yet.**

**New file:** `PokemonPlay/Networking/PokemonAPIClient.swift`

```swift
import ComposableArchitecture
import Foundation

@DependencyClient
struct PokemonAPIClient: Sendable {
    var fetchPokemon: @Sendable (_ name: String) async throws -> JSONNode
    var fetchEvolutions: @Sendable (_ name: String) async throws -> [String]
}

extension PokemonAPIClient: DependencyKey {
    static let liveValue = Self(
        fetchPokemon: { name in
            // Reuse the existing free function; resolve the JSONNode shape that
            // PokemonDataStore.getPokemon currently produces.
            let wrapped = try await fetchAndWrapPokemonAsync(name: name)
            let value = convertToJSONValue(wrapped)
            guard case let .object(dict) = value,
                  let domain = dict["domain"],
                  let config = domain.children?.first(where: { $0.key == "config" }),
                  let node = config.value.children?.first(where: { $0.key.lowercased() == name.lowercased() })
            else { throw PokemonError.invalidStructure }
            return node
        },
        fetchEvolutions: { name in
            let chain = try await fetchEvolutionChain(for: name)
            return extractEvolutionNames(from: chain)
        }
    )
}

extension DependencyValues {
    var pokemonAPI: PokemonAPIClient {
        get { self[PokemonAPIClient.self] }
        set { self[PokemonAPIClient.self] = newValue }
    }
}
```

Notes:
- `@DependencyClient` macro auto-synthesises a default `Self()` and a `testValue` that traps when called — we override `testValue` per test.
- We move the JSON-shape unwrapping out of `PokemonDataStore.getPokemon` and into `liveValue` so the reducer doesn't need to know about JSONValue routing.

**Validation point ✅**
- Build still clean.
- App still uses the OLD `PokemonViewModel` → `PokemonDataStore` path; new client is unused but compiles.
- A throwaway smoke test that calls `PokemonAPIClient.liveValue.fetchPokemon("pikachu")` from an `XCTest` returns a node with key `pikachu`.

---

### Stage 3 — Add `PokemonListFeature` reducer (no UI swap yet)

Goal: define the reducer that will eventually replace `PokemonViewModel.loadPokemon`. Run it in parallel with the existing view model — do not wire it to the UI yet.

**New file:** `PokemonPlay/Features/PokemonListFeature.swift`

```swift
import ComposableArchitecture
import Foundation

@Reducer
struct PokemonListFeature {
    @ObservableState
    struct State: Equatable {
        var nodes: IdentifiedArrayOf<JSONNode> = []          // replaces pokemonNodes
        var evolutionNames: [String] = []                    // replaces evolutionNames
        var pinnedNames: [String] = ["pikachu", "charizard", "bulbasaur", "farfetchd", "snorlax"]
        var searchCounts: [String: Int] = [:]
        var error: String?
        var isLoading = false

        var suggestedNames: [String] {                       // mirrors current computed prop
            Array(Set(pinnedNames + evolutionNames)).sorted {
                searchCounts[$0, default: 0] > searchCounts[$1, default: 0]
            }
        }
    }

    enum Action {
        case loadPokemon(name: String)
        case pokemonResponse(Result<JSONNode, Error>, name: String)
        case loadEvolutions(name: String)
        case evolutionsResponse(Result<[String], Error>)
        case dismissError
    }

    @Dependency(\.pokemonAPI) var pokemonAPI

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .loadPokemon(name):
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.error = nil
                return .run { send in
                    await send(.pokemonResponse(
                        Result { try await pokemonAPI.fetchPokemon(name: name) },
                        name: name
                    ))
                }

            case let .pokemonResponse(.success(node), name):
                state.isLoading = false
                state.nodes.insert(node, at: 0)
                state.searchCounts[name, default: 0] += 1
                return .none

            case let .pokemonResponse(.failure(error), _):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case let .loadEvolutions(name):
                return .run { send in
                    await send(.evolutionsResponse(
                        Result { try await pokemonAPI.fetchEvolutions(name: name) }
                    ))
                }

            case let .evolutionsResponse(.success(names)):
                state.evolutionNames = names
                return .none

            case let .evolutionsResponse(.failure(error)):
                state.error = error.localizedDescription
                return .none

            case .dismissError:
                state.error = nil
                return .none
            }
        }
    }
}
```

> ⚠️ `JSONNode` must conform to `Identifiable` for `IdentifiedArrayOf<JSONNode>`. If it doesn't already, add `extension JSONNode: Identifiable { var id: String { key } }` in this same stage. If two requests for the same name should NOT add a duplicate, switch `nodes.insert(...)` to a remove-then-insert.

**Validation point ✅**
- Build clean.
- A new unit test target file `PokemonPlayTests/PokemonListFeatureTests.swift` runs (see template in stage 6) and:
  - `loadPokemon("pikachu")` with a stubbed `fetchPokemon` flips `isLoading` true → response → false.
  - Error response sets `state.error`.
  - Existing app behaviour unchanged because UI still talks to the old `PokemonViewModel`.

---

### Stage 4 — Add `SearchFeature` reducer (composed inside `AppFeature`)

Search bar input + submit handling + debouncing, separated from list state because it has its own concerns.

**New file:** `PokemonPlay/Features/SearchFeature.swift`

```swift
@Reducer
struct SearchFeature {
    @ObservableState
    struct State: Equatable {
        var query: String = ""
        var isFocused: Bool = false
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case submitted
        case suggestionTapped(String)
        case clear

        // Delegate up so the parent can react without coupling
        @CasePathable
        enum Delegate: Equatable { case search(name: String) }
        case delegate(Delegate)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none

            case .submitted:
                let name = state.query
                guard !name.isEmpty else { return .none }
                state.isFocused = false
                return .send(.delegate(.search(name: name)))

            case let .suggestionTapped(name):
                state.query = name
                state.isFocused = false
                return .send(.delegate(.search(name: name)))

            case .clear:
                state.query = ""
                return .none

            case .delegate: return .none
            }
        }
    }
}
```

**New file:** `PokemonPlay/Features/AppFeature.swift`

```swift
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var search = SearchFeature.State()
        var list = PokemonListFeature.State()
    }

    enum Action {
        case search(SearchFeature.Action)
        case list(PokemonListFeature.Action)
        case onAppear
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.search, action: \.search) { SearchFeature() }
        Scope(state: \.list,   action: \.list)   { PokemonListFeature() }

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.list.nodes.isEmpty else { return .none }
                return .send(.list(.loadPokemon(name: "charizard")))

            case let .search(.delegate(.search(name))):
                return .merge(
                    .send(.list(.loadPokemon(name: name))),
                    .send(.list(.loadEvolutions(name: name)))
                )

            case .search, .list:
                return .none
            }
        }
    }
}
```

**Validation point ✅**
- Build clean.
- TestStore: tapping a suggestion routes through `search.suggestionTapped` → `delegate(.search(name:))` → `list.loadPokemon` and `list.loadEvolutions`. Add this as a single integration test in `AppFeatureTests`.

---

### Stage 5 — Swap `ContentView` over to the store

Replace the `@StateObject PokemonViewModel` with `@Bindable store: StoreOf<AppFeature>`. Keep all the same subviews. **This is the only stage where the user-visible UI plumbing changes.**

`PokemonPlayApp.swift`

```swift
@main
struct PokemonPlayApp: App {
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
            ._printChanges()                  // remove before ship
    }
    var body: some Scene {
        WindowGroup { ContentView(store: Self.store) }
    }
}
```

`ContentView.swift` (sketch — keeps the same subview layout):

```swift
struct ContentView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                SearchBarSectionView(
                    pokemonName: $store.search.query,        // BindableAction
                    isLoading: .constant(store.list.isLoading),
                    suggestions: store.list.suggestedNames,
                    onSearch: { _ in store.send(.search(.submitted)) }
                )

                if store.list.isLoading { ProgressView() }
                if let error = store.list.error {
                    Text("Error: \(error)").foregroundColor(.red).padding(.horizontal)
                }
                if !store.list.nodes.isEmpty {
                    List(store.list.nodes) { node in
                        NavigationLink {
                            PokemonDetailsView(node: node)
                                .navigationTitle(node.key.capitalized)
                        } label: { CodedImageView(node: node) }
                    }
                    if !store.list.evolutionNames.isEmpty {
                        EvolutionSectionView(names: store.list.evolutionNames)
                    }
                } else if store.list.error != nil {
                    Text("Error: \(store.list.error!)").foregroundColor(.red).padding()
                } else {
                    Spacer()
                    Text("Enter a Pokémon name to view its data.").foregroundColor(.secondary)
                    Spacer()
                }
            }
            .navigationTitle("Pokémon Statistics")
        }
        .onFirstAppearAsync { store.send(.onAppear) }
    }
}
```

**Delete in this stage**
- `PokemonViewModel` (the entire `class PokemonViewModel: ObservableObject` block in `PokemonDataStore.swift`).
- The `class PokemonDataStore` cache — its job moves into `PokemonListFeature.State`.
- `Networking/OldServices+callback.swift` if not referenced elsewhere — the legacy completion-handler API was a teaching artifact; TCA effects don't need it.

**Validation point ✅**
- App launches; default `charizard` loads on first appear.
- Searching for `pikachu` works end-to-end and the new pokemon appears at the top of the list.
- Error path: search a nonsense name like `"xyz123"` → red error text appears, app doesn't crash.
- Tapping a row pushes `PokemonDetailsView` (still uses the same `JSONNode` it always did).
- Manual smoke checklist passes (see §5 below).

---

### Stage 6 — Tests

Add `PokemonPlayTests/` target if it doesn't exist (Xcode → File → New → Target → Unit Testing Bundle). Target the `PokemonPlay` app.

Minimum coverage:

```swift
import ComposableArchitecture
import XCTest
@testable import PokemonPlay

final class PokemonListFeatureTests: XCTestCase {
    @MainActor
    func test_loadPokemon_success() async {
        let mockNode = JSONNode(key: "pikachu", value: .object([:]))
        let store = TestStore(initialState: PokemonListFeature.State()) {
            PokemonListFeature()
        } withDependencies: {
            $0.pokemonAPI.fetchPokemon = { _ in mockNode }
        }

        await store.send(.loadPokemon(name: "pikachu")) { $0.isLoading = true }
        await store.receive(\.pokemonResponse) {
            $0.isLoading = false
            $0.nodes = [mockNode]
            $0.searchCounts["pikachu"] = 1
        }
    }

    @MainActor
    func test_loadPokemon_failure() async {
        let store = TestStore(initialState: PokemonListFeature.State()) {
            PokemonListFeature()
        } withDependencies: {
            $0.pokemonAPI.fetchPokemon = { _ in throw PokemonError.invalidStructure }
        }

        await store.send(.loadPokemon(name: "x")) { $0.isLoading = true }
        await store.receive(\.pokemonResponse) {
            $0.isLoading = false
            $0.error = PokemonError.invalidStructure.localizedDescription
        }
    }
}
```

Add at minimum:
- `PokemonListFeatureTests` — load success, load failure, evolutions success, dedupe (if added).
- `SearchFeatureTests` — submit empty (no-op), submit non-empty (delegate fires), suggestion tap.
- `AppFeatureTests` — search delegate composes into list `loadPokemon` + `loadEvolutions`.

**Validation point ✅**
- `cmd+U` runs all tests. All green.
- Coverage report shows the new feature files at >80% (TestStore exercises every action).
- No `XCTFail` from "unexpected effect produced" — TestStore is exhaustive by default; if a test passes despite skipping a `.receive`, the framework forces you to acknowledge it.

---

### Stage 7 — Optional polish

These can ship later or never. Listed here so they're not lost.

- [ ] **Type-safe ID for Pokemon name.** Add `swift-tagged` and define `typealias PokemonName = Tagged<Pokemon, String>` so `loadPokemon(name:)` can't be called with a random `String`.
- [ ] **Debounced search-as-you-type.** Add `swift-clocks`, inject `\.continuousClock` into `SearchFeature`, debounce 300ms in the search reducer before firing the delegate.
- [ ] **Stack navigation for details.** Replace `NavigationLink { PokemonDetailsView }` with TCA's `NavigationStack(path: $store.scope(state: \.path, action: \.path))` and a `Path` reducer enum. Lets us deep-link and snapshot navigation state.
- [ ] **Persistence.** TCA 1.13+ ships `@Shared(.fileStorage(...))` — the in-memory `searchCounts` could persist across launches with one annotation.
- [ ] **Snapshot tests.** Add `swift-snapshot-testing` and snapshot the rendered states (loading, success, error, empty).
- [ ] **Delete `Networking/OldServices+callback.swift`** if not done in stage 5.

---

## 4. File-by-file mapping

| Today | After migration | Notes |
|---|---|---|
| `PokemonPlayApp.swift` | unchanged shell | Holds the root `Store`. |
| `ContentView.swift` | unchanged shape, body driven by `store` | `@StateObject` → `@Bindable var store`. |
| `Data/DataStore/PokemonDataStore.swift` | **deleted** | `PokemonDataStore` cache → `PokemonListFeature.State`; `PokemonViewModel` → reducers. |
| `Data/DataStore/PokemonError.swift` | unchanged | Error type stays. |
| `Networking/Services.swift` | trimmed | Keep `fetchAndWrapPokemonAsync` and `fetchEvolutionChain` as private helpers used inside `PokemonAPIClient.liveValue`. Drop the callback variants if no consumer remains. |
| `Networking/OldServices+callback.swift` | **deleted** | Legacy callback variant; TCA effects use async/await. |
| `Networking/PokemonAPIClient.swift` | **NEW** | `@DependencyClient`. |
| `Features/AppFeature.swift` | **NEW** | Composes children; routes `search.delegate` → `list`. |
| `Features/SearchFeature.swift` | **NEW** | Search bar reducer + `BindableAction`. |
| `Features/PokemonListFeature.swift` | **NEW** | Owns the list + cache state. |
| `Parser/*.swift` | unchanged | Pure value types. |
| `Data/Pokemon*.swift` | unchanged | Pure value types. |
| `View/*.swift` | unchanged | Subviews stay; only `ContentView` rewires its data source. |

---

## 5. Manual smoke checklist (run after stages 1, 5, and 7)

- [ ] Cold launch → "charizard" loads automatically; row appears.
- [ ] Type "pikachu" → tap search → row prepends; suggestions update with evolutions.
- [ ] Type "xyz123" → red error text appears; app doesn't crash; clearing & re-searching works.
- [ ] Tap a row → detail view pushes; stats card and JSON tree render.
- [ ] Background the app → foreground → state persists (in-session); the list isn't wiped.
- [ ] No `_printChanges()` output in release builds (it's stripped or removed before ship).

---

## 6. Risks and unknowns

- **`JSONNode` identity.** TCA expects `Identifiable` (or stable hashing) on collection elements. Verify the existing `JSONNode.key` is unique-per-pokemon BEFORE switching to `IdentifiedArrayOf` — if two requests can produce the same key (re-fetch), decide whether to dedupe (replace existing entry) or de-duplicate by inserting a UUID instead. If we hit a duplicate-key crash from `IdentifiedArray`, that's the smell.
- **`PokemonDataStore`'s "extract domain.config[name]" path.** Currently lives in `PokemonDataStore.getPokemon`. The plan moves it into `PokemonAPIClient.liveValue.fetchPokemon`. If anything else (e.g. a test fixture) relied on the un-extracted shape, it'll break — `grep` for `convertToJSONValue` callers before deleting.
- **Cache eviction.** Today the cache lives forever in `PokemonDataStore`. After migration it's in `PokemonListFeature.State` and lives as long as the Store does (= app process lifetime). Same effective behaviour, but worth flagging if we ever add background-purge logic.
- **Concurrency.** `PokemonViewModel` is `@MainActor`; reducers run on `MainActor` by default in TCA, so no behaviour change. But the `liveValue` closures must be `@Sendable` — confirm `fetchAndWrapPokemonAsync` and `fetchEvolutionChain` are `Sendable` (they take `Sendable` params and return `Sendable` types, so they should be).
- **`onFirstAppearAsync`.** This project-local helper still works with TCA. If it's ever removed, replace with `.task { store.send(.onAppear) }`.

---

## 7. Estimated effort

| Stage | Effort | Skill |
|---|---|---|
| 1 — Bootstrap | 30 min | Xcode SPM clicks. |
| 2 — `PokemonAPIClient` | 1–2 hr | Familiar with `@DependencyClient`. |
| 3 — `PokemonListFeature` | 2–4 hr | First reducer is the steep part. |
| 4 — `SearchFeature` + `AppFeature` | 1–2 hr | Once the pattern clicks, this is fast. |
| 5 — Wire `ContentView` | 2–3 hr | Mechanical, but UI re-test is the slow part. |
| 6 — Tests | 2–4 hr | Pays back forever. |
| 7 — Polish (optional) | open-ended | Ship lean first. |

Total minimum to a green TCA conversion: **~1–2 focused days** plus testing.
