//
//  GameState.swift
//  HiveEngine
//
//  Created by Joseph Roque on 2019-02-07.
//  Copyright © 2019 Joseph Roque. All rights reserved.
//

import Foundation

/// Immutable state of a game of hive.
public class GameState: Codable {

	/// Units and their positions
	private(set) public var units: [Unit: Position]

	/// Units which are currently in play.
	public lazy var unitsInPlay: Set<Unit> = {
		return Set(units.filter { $0.value != .inHand }.keys)
	}()

	/// Stacks of units at a certain position
	private(set) public var stacks: [Position: [Unit]]

	/// The current player
	private(set) public var currentPlayer: Player

	/// The current move number
	private(set) public var move: Int

	/// The most recently moved unit
	private(set) public var lastMovedUnit: Unit?

	/// True if the game has ended
	public var isEndGame: Bool {
		return winner.isNotEmpty
	}

	/// Returns the Player who has won the game, both players if it is a tie,
	/// or no players if the game has not ended
	public lazy var winner: [Player] = {
		var winners: [Player] = []
		let queens = units.filter { $0.key.class == .queen }.map { $0.key }

		if queens[0].isSurrounded(in: self) {
			winners.append(queens[0].owner.next)
		}
		if queens[1].isSurrounded(in: self) {
			winners.append(queens[1].owner.next)
		}

		return winners
	}()

	// MARK: - Constructors

	public init() {
		self.currentPlayer = .white
		self.stacks = [:]
		self.move = 0

		let whiteUnits = Unit.Class.fullSet.map { Unit(class: $0, owner: .white) }
		let blackUnits = Unit.Class.fullSet.map { Unit(class: $0, owner: .black) }
		self.units = [:]
		(whiteUnits + blackUnits).forEach {
			self.units[$0] = .inHand
		}
	}

	/// Create a game state from a previous one.
	/// The current player and move area progressed when created and the units and positions are duplicated.
	public init(from other: GameState) {
		self.currentPlayer = other.currentPlayer.next
		self.move = other.move + 1
		self.units = other.units
		self.stacks = other.stacks
	}

	// MARK: - Updates

	/// List the available movements from a GameState.
	public lazy var availableMoves: [Movement] = {
		return moves(for: currentPlayer)
	}()

	/// List the available movements from a GameState for the opponent.
	public lazy var opponentMoves: [Movement] = {
		return moves(for: currentPlayer.next)
	}()

	public func moves(for player: Player) -> [Movement] {
		guard isEndGame == false else { return [] }

		// Only available moves at the start of the game are to place a piece at (0, 0, 0)
		// or to place a piece next to the original piece
		if move == 0 {
			return availablePieces(for: player).map { .place(unit: $0, at: .inPlay(x: 0, y: 0, z: 0)) }
		}

		// Queen must be played in player's first 4 moves
		if (player == .white && move == 6) || (player == .black && move == 7),
			let queen = availablePieces(for: player).filter({ $0.class == .queen }).first {
			return playableSpaces(for: player).map { .place(unit: queen, at: $0) }
		}

		// Get placeable and moveable pieces
		let placePieceMovements: [Movement] = availablePieces(for: player).flatMap { unit in
			return playableSpaces(for: player).map { .place(unit: unit, at: $0) }
		}

		var movePieceMovements: [Movement] = []
		// Iterate over all pieces on the board
		units.filter {  $0.value != .inHand }
			// Only the current player can move
			.filter { $0.key.owner == player }
			// Moving the piece must not break the hive
			.filter { $0.key.class == .pillBug || oneHive(excluding: $0.key) }
			// Append moves available for the piece
			.forEach { movePieceMovements.append(contentsOf: $0.key.availableMoves(in: self)) }
		return placePieceMovements + movePieceMovements
	}

	/// Applies the movement to this game state (if it is valid) and returns
	/// the updated game state.
	public func apply(_ move: Movement) -> GameState {
		// Ensure only valid moves are played
		guard availableMoves.contains(move) else { return self }
		let update = GameState(from: self)

		switch move {
		case .move(let unit, let position):
			// Move a piece from its previous stack to a new position
			let startPosition = update.units[unit]!
			_ = update.stacks[startPosition]?.popLast()
			if (update.stacks[startPosition]?.count ?? -1) == 0 {
				update.stacks[startPosition] = nil
			}
			if update.stacks[position] == nil {
				update.stacks[position] = []
			}
			update.stacks[position]!.append(unit)
			update.units[unit] = position
			update.lastMovedUnit = move.movedUnit
		case .yoink(_, let unit, let position):
			// Move a piece from its previous stack to a new position adjacent to the pill bug
			update.stacks[update.units[unit]!] = nil
			update.stacks[position] = [unit]
			update.units[unit] = position
			update.lastMovedUnit = move.movedUnit
		case .place(let unit, let position):
			// Place an unplayed piece on the board
			update.stacks[position] = [unit]
			update.units[unit] = position
		}

		// When a player is shut out, skip their turn
		if update.isEndGame == false && update.availableMoves.count == 0 {
			update.lastMovedUnit = nil
			update.currentPlayer = update.currentPlayer.next
		}

		return update
	}

	// MARK: Units

	/// List the unplayed pieces for a player.
	public func availablePieces(for player: Player) -> Set<Unit> {
		return Set(units.filter { $0.key.owner == player }.keys).subtracting(unitsInPlay)
	}

	/// List the units which are at the top of a stack adjacent to the position of a unit.
	public func units(adjacentTo unit: Unit) -> Set<Unit> {
		guard let position = units[unit], position != .inHand else { return [] }
		return units(adjacentTo: position)
	}

	/// List the units which are at the top of a stack adjacent to a position.
	public func units(adjacentTo position: Position) -> Set<Unit> {
		return Set(position.adjacent().compactMap {
			guard let stack = stacks[$0] else { return nil }
			return stack.last
		})
	}

	/// Positions which are adjacent to another piece and are not filled.
	///
	/// - Parameters:
	///  - excludedUnit: optionally exclude a unit when determining if the space is playable
	public func playableSpaces(excluding excludedUnit: Unit? = nil, for player: Player? = nil) -> Set<Position> {
		var includedUnits = unitsInPlay
		if let excluded = excludedUnit {
			includedUnits.remove(excluded)
		}

		let allSpaces = Set(units
			.filter { includedUnits.contains($0.key) }
			.filter { $0.key.isTopOfStack(in: self) }
			.values.flatMap { $0.adjacent() }).subtracting(stacks.keys)
		guard let player = player, move > 1 else { return allSpaces }
		let unavailableSpaces = Set(units
			.filter { $0.key.owner != player }
			.filter { $0.key.isTopOfStack(in: self) }
			.values.flatMap { $0.adjacent() }).subtracting(stacks.keys)
		return allSpaces.subtracting(unavailableSpaces)
	}

	// MARK: - Validation

	/// Determine if this game state meets the "One Hive" rule.
	///
	/// - Parameters:
	///   - excludedUnit: optionally exclude a unit when determining if the rule is met
	public func oneHive(excluding excludedUnit: Unit? = nil) -> Bool {
		let allPositions = Set(units.filter { $0.key != excludedUnit && $0.value != .inHand }.compactMap { $0.value })
		guard let startPosition = allPositions.first else { return true }

		var found = Set([startPosition])
		var stack = [startPosition]

		// DFS through pieces and their adjacent positions to determine graph connectivity
		while stack.isNotEmpty {
			let position = stack.popLast()!
			for adjacent in position.adjacent() {
				if allPositions.contains(adjacent) && found.contains(adjacent) == false {
					found.insert(adjacent)
					stack.append(adjacent)
				}
			}
		}

		return found == allPositions
	}
}

extension GameState: Equatable {
	public static func == (lhs: GameState, rhs: GameState) -> Bool {
		return lhs.units == rhs.units &&
			lhs.stacks == rhs.stacks &&
			lhs.move == rhs.move &&
			lhs.currentPlayer == rhs.currentPlayer &&
			lhs.lastMovedUnit == rhs.lastMovedUnit
	}
}

extension GameState: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(units)
		hasher.combine(stacks)
		hasher.combine(move)
		hasher.combine(currentPlayer)
		hasher.combine(lastMovedUnit)
	}
}
