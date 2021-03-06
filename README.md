![Logo](media/HiveEngine.png)

# Hive Engine

Manages the game state of a game of hive and determines valid playable moves.

Additionally, produces new game states from the application of valid moves.

This engine optionally supports games with all 3 official Hive expansions: the Mosquito, the Lady Bug, and the Pill Bug. See details on the `GameState` below for options.

## Usage

You can read about each of the engine's components below, or dive right in with an instance of `GameState`:

```
let state = GameState()
```

### Unit

A `Unit` represents one of the various pieces a game of Hive is played with -- ants, spiders, etc.

Each `Unit` has a `class`, which defines the type of bug it is, an `owner` to let you know who it belongs to, and an `identifier` to differentiate each instance.

There are a variety of functions for determining if a `Unit` can move, and where it can move to.

Each class of `Unit` also provides an extension to the `Unit` class to calculate its moves. See extension classes such as `Unit+Ant` and `Unit+Beetle` for more.

### Position

A `Position` is a space on the "board" where a `Unit` can be placed or moved to.

`Position`s rely on a hexagonal grid system, inspired by an [excellent article](https://www.redblobgames.com/grids/hexagons/) by Red Blog Games. Details on the grid system implementation can be found [here](https://www.redblobgames.com/grids/hexagons/implementation.html).

The `Position` class also provides functions for determining if a `Unit` can move freely between two `Positions`, very important for determining valid moves in the current state.

### Movement

A `Movement` provides details on moving a `Unit` around the board, or introducing a new `Unit` to the board.

- `.move(unit:to:)` specifies instructions for moving a `Unit` to a `Position`
- `.place(unit:at:)` specifies instructions for placing a `Unit` at a `Position`
- `.yoink(pillBug:unit:to:)` specifies instructions for moving a `Unit` through the use of a Pill Bug to a `Position`
- `.pass` specifies a non-movement, only available when a player has **no other moves**.

### GameState

The `GameState` is the structure which manages the overall state of a game of Hive.

Get started by creating an instance: `let state = GameState()`

#### Options

By default, a `GameState` will create a basic game with no additional options. You can enable expansion pieces and common unofficial rules through `GameState.Option`, as well as performance enhancements.

Provide a set of `GameState.Option` to the `GameState(options:)` constructor to change which options you have enabled.

#### API

You can enumerate all the current moves available with `availableMoves`.

To update the `GameState` with a given move, call `apply(_:)` which will mutate the state in place. If you want to explore various `Movement`s, you can undo a move with `undoMove()`

For better performance, you can disable move validation with `GameState.Option.disableMovementValidation`.

---

## Installation

### Swift Package Manager

This package is built with Swift Package Manager, so you can require it as a dependency in your `Package.swift` file:

```
    dependencies: [
        .package(url: "https://github.com/autoreleasefool/hive-engine.git", from: "3.1.2")
    ],
```

See the [Releases](https://github.com/autoreleasefool/hive-engine/releases) for the most recent release.

### Requirements

- Swift 5.2+
- [SwiftLint](https://github.com/realm/SwiftLint)

---

## Contributing

1. Write your changes and make sure you test them! This engine boasts nearly 100% code coverage and expects precise conformance to the rules of the game.
   - `swift test`
2. Install SwiftLint for styling conformance:
   - Run `swiftlint` from the root of the repository.
   - There should be no errors or violations. If there are, please fix them before opening a PR.
3. Open a PR with your changes 👍
4. CI will run your changes and ensure they build and pass all tests on Linux and macOS

## Notice

Hive Engine is not affiliated with Gen42 Games in any way.
