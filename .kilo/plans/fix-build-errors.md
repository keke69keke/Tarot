# Plan: Fix Tarot Project Build Errors

## Problem
The project fails to build with 28 compilation errors, all in `TarotUI/Views/ReadingView.swift`. The root cause is a structural issue where the `ReadingView` struct is closed prematurely, leaving helper functions and the `FirstCardSlot` nested struct outside the struct scope.

## Root Cause Analysis
1. **Premature struct closure**: Line 366 (`    }`) closes the `ReadingView` struct. Lines 368–467 (helper functions and `FirstCardSlot`) end up at the top level with `private` access modifiers, which is invalid.
2. **Complex body**: The `body` computed property at line 17 is extremely large, causing the Swift compiler to emit: *"unable to type-check this expression in reasonable time"*. This cascades into spurious *"cannot find X in scope"* errors for properties that actually exist.
3. **Indentation issues in `Spread.swift`**: Several `SpreadType` enum cases have inconsistent indentation (mixed tabs/spaces and wrong indentation levels), making the file hard to read and maintain.

## Proposed Fixes

### 1. Fix `ReadingView.swift` struct scope
- Remove the premature closing brace at line 366 that ends the `ReadingView` struct.
- Ensure the final closing brace at line 467 properly closes the struct after `FirstCardSlot`.
- This moves `revealAll`, `spreadCardCount`, `firstCardPicker`, `cardsForPicker`, `chooseFirstCard`, `replacementCards`, `chooseReplacementCard`, and `FirstCardSlot` back inside the struct where they belong.

### 2. Simplify `ReadingView` body (if needed after fix #1)
- If the compiler still reports *"unable to type-check this expression in reasonable time"*, break the massive `body` into smaller extracted `View` computed properties (e.g., `spreadSelector`, `firstCardSection`, `drawButtonSection`).
- Also verify that `FirstCardSlot` and picker-related state (`chosenFirstCardSlot`, `cardPickerQuery`, `replacementPickerQuery`, `replacementIndex`) are correctly wired to the view model and picker UI.

### 3. Clean up `Spread.swift` formatting
- Fix inconsistent indentation on enum cases:
  - `.decision` (line 68)
  - `.moonCycle` (lines 262, 323, 351, 379)
  - `.lineage` (lines 326, 354, 382)
- Align all `case` labels and return statements to the same indentation level.
- Ensure no missing commas or typos (e.g., line 297 `description: "Lo que puedes soltar para honrar tu propio camino.")` appears correct but verify balanced parentheses).

### 4. Verify no broken references from deleted files
- Confirm that `TarotReadingViewModel`, `MusicServiceManager`, and `MysticMusicPlayerBar` (deleted from `TarotCore/Services/`) are no longer referenced anywhere in the codebase.
- Verify `TarotUI/MysticMusicPlayerBar.swift` exists and is correctly referenced by `LearningCenterView.swift`.

## Validation
- Run `xcodebuild` to ensure zero compilation errors.
- Run `swift test` if smoke tests exist.
