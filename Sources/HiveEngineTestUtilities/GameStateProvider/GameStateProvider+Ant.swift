//
//  GameStateProvider+Ant.swift
//  HiveEngineTests
//
//  Created by Joseph Roque on 2020-12-02.
//

@testable import HiveEngine

extension GameState {
	public var whiteAnt: Unit {
		find(.ant, belongingTo: .white)
	}

	public var blackAnt: Unit {
		find(.ant, belongingTo: .black)
	}
}

extension GameStateProvider {
	/// Produces a GameState in which the White Ant has a number of interesting moves available
	public var whiteAntGameState: GameState {
		let state = GameState()
		self.apply(
			moves: [
				RelativeMovement(notation: "wQ")!,
			],
			to: state
		)
		return state
	}
}
