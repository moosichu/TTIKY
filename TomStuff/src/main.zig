const std = @import("std");
const testing = std.testing;

// Past, present, future
// White, Black Travellers
// White, Focus, Black Focus

// 3 4x4 grids
// one piece in each corner
// person who starts does past
// person who second does future
// going to past duplicates
// going forward does not
// 4 reserves
// have to switch focus after end of each turn

// Change unreal play thing to simulate!

const PieceStateTag = enum {
    reserve,
    active,
    dead,
};

const PiecePosition = struct {
    period: Period,
    space: u4,
};

const PieceState = union(PieceStateTag) {
    reserve: void,
    active: PiecePosition,
    dead: void,
};

const Period = enum {
    past,
    present,
    future,
};

const Player = u1;

const player_count = 2;
const piece_count = 7;

const GameState = struct {
    player_turn: Player,
    focus: [player_count]Period,
    piece_states: [player_count][piece_count]PieceState,

    fn construct() GameState {
        return .{
            .player_turn = 0,
            .focus = .{ .past, .future },
            .piece_states = [_][7]PieceState{
                [_]PieceState{
                    .{
                        .active = .{ .period = .past, .space = 0 },
                    },
                    .{
                        .active = .{ .period = .present, .space = 0 },
                    },
                    .{
                        .active = .{ .period = .future, .space = 0 },
                    },
                    .reserve,
                    .reserve,
                    .reserve,
                    .reserve,
                },
                [_]PieceState{
                    .{
                        .active = .{ .period = .past, .space = 15 },
                    },
                    .{
                        .active = .{ .period = .present, .space = 15 },
                    },
                    .{
                        .active = .{ .period = .future, .space = 15 },
                    },
                    .reserve,
                    .reserve,
                    .reserve,
                    .reserve,
                },
            },
        };
    }

    fn countDeadPieces(game_state: GameState, player: Player) i32 {
        var count: i32 = 0;
        for (game_state.piece_states[player]) |piece_state| {
            if (piece_state == .dead) {
                count += 1;
            }
        }
        return count;
    }

    fn otherPlayer(player: Player) Player {
        if (player == 0) {
            return 1;
        } else {
            return 0;
        }
    }

    // Heuristically evaluate the state of the game
    // player 0 winning is positive,
    // player 1 winning is negative
    pub fn evaluate(game_state: GameState) i32 {
        // TODO: figure out if game ended!
        {
            // Player can only be lost if it's not their turn
            const other_player = otherPlayer(game_state.player_turn);

            var active_count: u32 = 0;
            for (game_state.piece_states[other_player]) |piece_state| {
                if (piece_state == .active) {
                    active_count += 1;
                }
            }
            if (active_count < 2) {
                if (other_player == 1) {
                    return std.math.maxInt(i32);
                } else {
                    return std.math.minInt(i32);
                }
            }
        }

        const dead_score = dead_score: {
            const dead_0 = game_state.countDeadPieces(0);
            const dead_1 = game_state.countDeadPieces(1);

            // if player 0 has fewer dead pieces, they are winning
            // "by" amount losing
            break :dead_score dead_1 - dead_0;
        };

        return dead_score;
    }
};

export fn construct() void {
    var game_state = GameState.construct();
    _ = game_state.evaluate();
}

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
