//
//  Unit.swift
//  HiveEngine
//
//  Created by Joseph Roque on 2019-02-07.
//  Copyright © 2019 Joseph Roque. All rights reserved.
//

import Foundation

public struct Unit: Codable {

	public enum Class: Int, CaseIterable, Codable {
		case ant = 0
		case beetle = 1
		case hopper = 2
		case ladyBug = 3
		case mosquito = 4
		case pillBug = 5
		case queen = 6
		case spider = 7

		init?(notation: String) {
			switch notation {
			case "A": self = .ant
			case "B": self = .beetle
			case "G": self = .hopper
			case "L": self = .ladyBug
			case "M": self = .mosquito
			case "P": self = .pillBug
			case "Q": self = .queen
			case "S": self = .spider
			default: return nil
			}
		}

		var notation: String {
			switch self {
			case .ant: return "A"
			case .beetle: return "B"
			case .hopper: return "G"
			case .ladyBug: return "L"
			case .mosquito: return "M"
			case .pillBug: return "P"
			case .queen: return "Q"
			case .spider: return "S"
			}
		}

		/// A single player's full set of units
		public static var basicSet: [Class] {
			return [
				.ant, .ant, .ant,
				.beetle, .beetle,
				.hopper, .hopper, .hopper,
				.queen,
				.spider, .spider,
			]
		}

		/// Get a set of Units for a game based on the Options provided.
		public static func set(with options: Set<GameState.Options>) -> [Class] {
			var basicSet = Class.basicSet
			if options.contains(.ladyBug) { basicSet.append(.ladyBug) }
			if options.contains(.mosquito) { basicSet.append(.mosquito) }
			if options.contains(.pillBug) { basicSet.append(.pillBug) }
			return basicSet
		}
	}

	// MARK: Properties

	/// Unique ID for the unit which persists across game states
	public let index: Int
	/// Class of the unit to determine its movements
	public let `class`: Class
	/// Owner of the unit
	public let owner: Player

	public init(`class`: Class, owner: Player, index: Int) {
		self.class = `class`
		self.owner = owner
		self.index = index
	}

	init?(notation: String) {
		guard notation.count == 3,
			let owner = Player(notation: String(notation[notation.startIndex])),
			let `class` = Unit.Class(notation: String(notation[notation.index(after: notation.startIndex)])),
			let index = Int(String(notation[notation.index(notation.startIndex, offsetBy: 2)])) else { return nil }
		self.owner = owner
		self.class = `class`
		self.index = index
	}

	/// Standard unit notation
	public var notation: String {
		let colorNotation: String = owner == .white ? "w" : "b"
		let indexNotation: String = "\(index)"
		let classNotation: String = self.class.notation

		return "\(colorNotation)\(classNotation)\(indexNotation)"
	}

	// MARK: Movement

	/// List the moves available for the unit.
	public func availableMoves(in state: GameState, moveSet: inout Set<Movement>) {
		return moves(as: self.class, in: state, moveSet: &moveSet)
	}

	/// Get the available moves when treating this unit as a certain class
	func moves(as `class`: Class, in state: GameState, moveSet: inout Set<Movement>) {
		switch `class` {
		case .ant: movesAsAnt(in: state, moveSet: &moveSet)
		case .beetle: movesAsBeetle(in: state, moveSet: &moveSet)
		case .hopper: movesAsHopper(in: state, moveSet: &moveSet)
		case .ladyBug: movesAsLadyBug(in: state, moveSet: &moveSet)
		case .mosquito: movesAsMosquito(in: state, moveSet: &moveSet)
		case .pillBug: movesAsPillBug(in: state, moveSet: &moveSet)
		case .queen: movesAsQueen(in: state, moveSet: &moveSet)
		case .spider: movesAsSpider(in: state, moveSet: &moveSet)
		}
	}

	/// Returns false if this piece cannot move due to fundamental rules of the game.
	public func canMove(in state: GameState) -> Bool {
		return state.oneHive(excluding: self) && self.isTopOfStack(in: state) && self != state.lastUnitMoved
	}

	/// Returns true if this unit can move as the given class.
	public func canCopyMoves(of givenClass: Class, in state: GameState) -> Bool {
		if self.class == givenClass {
			return true
		} else if self.class == .mosquito {
			// Mosquitos can only move as beetles when on top of the hive
			if stackPosition(in: state) ?? 1 > 1 {
				return givenClass == .beetle
			}

			// Mosquitos can otherwise move as any piece they're adjacent to
			for unit in state.units(adjacentTo: self) {
				if unit.class == givenClass ||
					((unit.class == .pillBug || unit.class == .beetle) && givenClass == .queen) {
					return true
				}
			}

			return false
		} else if (self.class == .pillBug || self.class == .beetle) && givenClass == .queen {
			// Beetles and pill bugs have movements similar to queens
			return true
		}

		return false
	}

	// MARK: Special ability

	/// Returns true if this unit can use the Pill Bug's special ability.
	public func canUseSpecialAbility(in state: GameState) -> Bool {
		guard self != state.lastUnitMoved || state.options.contains(.allowSpecialAbilityAfterYoink) else { return false }

		switch self.class {
		case .pillBug:
			return true
		case .mosquito:
			return canCopyMoves(of: .pillBug, in: state)
		case .ant, .beetle, .hopper, .ladyBug, .queen, .spider:
			return false
		}
	}

	// MARK: Position

	/// Determine the position of a unit in a positional stack.
	public func stackPosition(in state: GameState) -> Int? {
		guard let position = state.unitsInPlay[owner]?[self],
			let stack = state.stacks[position] else {
			return nil
		}

		guard let height = stack.firstIndex(of: self) else { return nil }
		return height &+ 1
	}

	/// Determine if this unit is at the top of its stack.
	public func isTopOfStack(in state: GameState) -> Bool {
		return state.unitIsTopOfStack[self] ?? false
	}

	/// Returns true if this unit is surrounded on all 6 sides.
	public func isSurrounded(in state: GameState) -> Bool {
		return state.units(adjacentTo: self).count == 6
	}
}

// MARK: - CustomStringConvertible

extension Unit: CustomStringConvertible {
	public var description: String {
		return "\(self.owner.description) \(self.class.description) (\(self.index))"
	}
}

extension Unit.Class: CustomStringConvertible {
	public var description: String {
		switch self {
		case .ant: return "Ant"
		case .beetle: return "Beetle"
		case .hopper: return "Hopper"
		case .ladyBug: return "Lady Bug"
		case .mosquito: return "Mosquito"
		case .pillBug: return "Pill Bug"
		case .queen: return "Queen"
		case .spider: return "Spider"
		}
	}
}

// MARK: - Hashable

extension Unit: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(owner)
		hasher.combine(`class`)
		hasher.combine(index)
	}
}

// MARK: - Equatable

extension Unit: Equatable {
	public static func == (lhs: Unit, rhs: Unit) -> Bool {
		return lhs.owner == rhs.owner &&
			lhs.class == rhs.class &&
			lhs.index == rhs.index
	}
}

// MARK: - Comparable

extension Unit: Comparable {
	public static func < (lhs: Unit, rhs: Unit) -> Bool {
		if lhs.owner == rhs.owner {
			if lhs.class == rhs.class {
				return lhs.index < rhs.index
			}
			return lhs.class < rhs.class
		}
		return lhs.owner < rhs.owner
	}
}

extension Unit.Class: Comparable {
	public static func < (lhs: Unit.Class, rhs: Unit.Class) -> Bool {
		return lhs.rawValue < rhs.rawValue
	}
}
