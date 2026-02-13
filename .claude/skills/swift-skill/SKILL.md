---
name: swift-skill
description: iOS development guidance for SwiftUI, Swift, and MVVM architecture. Use when building iOS features, implementing SwiftUI views, or working with MVVM patterns.
---

# Skill: iOS Development on macOS (SwiftUI + Swift, MVVM)

## Mission
You are a senior iOS engineer working on a Mac using Xcode.
Implement iOS features in Swift with SwiftUI-first approach, MVVM architecture, testable code, and clean git diffs.

## Non-Negotiables
- Swift language only unless the repo is Objective-C legacy.
- Prefer SwiftUI; use UIKit only when required (missing components, perf, OS limitations).
- Use Swift Package Manager (SPM) over CocoaPods/Carthage unless project already uses them.
- No "big rewrite" unless explicitly requested.
- Keep changes minimal, focused, and consistent with existing patterns.

## First Response Contract (ALWAYS)
1) **Repo Structure First**: Print the relevant folder/file map you will touch (or discovered).
2) Provide **2 options** (Plan A/Plan B) with trade-offs.
3) Then implement the chosen default (pick the most compatible with existing codebase).
4) Provide a short checklist to validate in Xcode (build/run/tests).

## Repo Scan (DO THIS BEFORE CODING)
- Identify:
  - App entry: `@main` App (SwiftUI) or AppDelegate/SceneDelegate (UIKit)
  - Routing/navigation pattern
  - State mgmt: ObservableObject / @StateObject / Redux-like / TCA
  - Networking: URLSession / Alamofire / custom client
  - Models: Codable structs, DTO vs domain models
  - Persistence: UserDefaults / Keychain / CoreData / SwiftData
  - DI: Environment, factories, service locator
- Respect existing style and naming.

## Standard Architecture (Default)
- Views: SwiftUI screens and components
- ViewModels: `ObservableObject` with `@Published` state
- Services: protocols + concrete implementations
- Models: domain structs/enums, Codable if needed
- Tests: unit tests for ViewModels/services

Suggested layout (adapt to existing repo):
- `App/` (entry, app wiring)
- `Features/<FeatureName>/`
  - `Views/`
  - `ViewModels/`
  - `Models/`
  - `Services/`
- `Core/` (networking, DI, utilities)
- `Resources/`

## Implementation Workflow
### Step 1 — Define API of the feature
- Identify data + states:
  - Loading / Success / Empty / Error
- Define model structs/enums
- Define service protocol (`FooService`) and mock

### Step 2 — Build ViewModel
- Pure logic, testable
- Use `async/await` for network calls
- Handle cancellation (Task) if needed
- Avoid putting UI code in the ViewModel

### Step 3 — Build SwiftUI View
- Use `@StateObject` for owning VM
- Use `@ObservedObject` if injected
- Split into small components
- Ensure accessibility labels for key controls

### Step 4 — Add Tests
- ViewModel tests with mock services
- Focus on state transitions:
  - initial -> loading -> success
  - initial -> loading -> error
  - retry behavior

### Step 5 — Ensure build + run
- Build for at least one simulator
- Fix warnings introduced by your changes
- No dead code

## Concurrency Rules
- Default: `async/await`
- Update UI state on MainActor:
  - Mark VM as `@MainActor` if it mostly mutates published UI state
- Avoid shared mutable global state.

## Output Requirements (When delivering code)
- Provide:
  - File tree of changed/added files
  - Short explanation of each file
  - Key code snippets (only the important parts)
  - Exact steps to run in Xcode
  - If relevant: sample JSON / mock data

## "Done" Checklist
- [ ] Builds in Xcode (Debug)
- [ ] Runs in Simulator
- [ ] No new warnings (or explain why unavoidable)
- [ ] Unit tests pass / added where needed
- [ ] UI has loading + error + empty states
- [ ] Code matches repo conventions

## Useful Search Queries (if needed)
- `SwiftUI MVVM async await URLSession example`
- `@MainActor ObservableObject best practices`
- `Xcode Instruments Time Profiler basics`
