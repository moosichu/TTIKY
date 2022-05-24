const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

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

const PieceSpace = @Vector(2, u2);
const PiecePosition = struct {
    period: Period,
    space: PieceSpace,

    pub fn equals(a: PiecePosition, b: PiecePosition) bool {
        if (a.period == b.period) {
            if (a.space == b.space) {
                return true;
            }
        }
        return false;
    }
};

const PieceState = union(enum) {
    reserve: void,
    active: PiecePosition,
    dead: void,
};

const Period = enum {
    past,
    present,
    future,

    pub fn back(period: Period) Period {
        return switch (period) {
            .present => .past,
            .future => .present,
            else => unreachable,
        };
    }

    pub fn forward(period: Period) Period {
        return switch (period) {
            .past => .present,
            .present => .future,
            else => unreachable,
        };
    }
};

const Player = u1;

const player_count = 2;
const piece_count = 7;
const board_size = 4;

const GameState = struct {
    player_turn: Player,
    focus: [player_count]Period,
    // Stored in order of active, reserve, dead - lets us break early out of loops
    piece_states: [player_count][piece_count]PieceState,

    fn construct() GameState {
        return .{
            .player_turn = 0,
            .focus = .{ .past, .future },
            .piece_states = [_][7]PieceState{
                [_]PieceState{
                    .{
                        .active = .{ .period = .past, .space = .{ 0, 0 } },
                    },
                    .{
                        .active = .{ .period = .present, .space = .{ 0, 0 } },
                    },
                    .{
                        .active = .{ .period = .future, .space = .{ 0, 0 } },
                    },
                    .reserve,
                    .reserve,
                    .reserve,
                    .reserve,
                },
                [_]PieceState{
                    .{
                        .active = .{ .period = .past, .space = .{ 3, 3 } },
                    },
                    .{
                        .active = .{ .period = .present, .space = .{ 3, 3 } },
                    },
                    .{
                        .active = .{ .period = .future, .space = .{ 3, 3 } },
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

        var piece_index = game_state.piece_states[player].len - 1;
        while (piece_index >= 0) {
            if (game_state.piece_states[player][piece_index] == .dead) {
                count += 1;
            } else {
                break;
            }
            piece_index += 1;
        }

        return count;
    }

    fn countReservePieces(game_state: GameState, player: Player) i32 {
        var count: i32 = 0;
        for (game_state.piece_states[player]) |piece_state| {
            if (piece_state == .reserve) {
                count += 1;
            } else if (piece_state == .dead) {
                break;
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
        switch (game_state.getWinner()) {
            .player_0 => return std.math.maxInt(i32),
            .player_1 => return std.math.minInt(i32),
            .none => {},
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

    const Winner = enum {
        player_0,
        player_1,
        none,

        pub fn hasWinner(winner: Winner) bool {
            return winner != .none;
        }
    };

    pub fn getWinner(game_state: GameState) Winner {
        // Player can only be lost if it's not their turn
        const other_player = otherPlayer(game_state.player_turn);

        var active_count: u32 = 0;
        for (game_state.piece_states[other_player]) |piece_state| {
            if (piece_state == .active) {
                active_count += 1;
            } else {
                break;
            }
        }
        if (active_count < 2) {
            if (other_player == 1) {
                return .player_0;
            } else {
                return .player_1;
            }
        }

        return .none;
    }

    pub fn isOccupiedByPlayer(game_state: GameState, piece_position: PiecePosition, player: Player) bool {
        for (game_state.piece_states[player]) |piece| {
            if (piece == .active) {
                if (piece_position.equals(piece.active)) {
                    return true;
                }
            } else {
                break;
            }
        }
        return false;
    }

    fn doSingleAction(game_state: GameState, piece_index: u32, move_action: MoveAction) GameState {
        // TODO: Asser tinvariants!
        const player = game_state.player_turn;
        // const other_player = otherPlayer(player);

        // Copy game state by value
        var next_game_state = game_state;
        // TODO: Assert focus matches piece we are looking at!

        const piece_state = game_state.piece_states[player][piece_index];

        switch (move_action) {
            .time_travel => |time_travel_action| switch (time_travel_action) {
                .forward => {
                    // TODO: Assert we can travel here!
                    next_game_state.piece_states[player][piece_index].period = piece_state.period.forward();
                },
                .back => {
                    // TODO: assert that we can travel to this space!
                    var success = false;
                    for (next_game_state.piece_states[player]) |target_piece_state, clone_piece_index| {
                        if (target_piece_state == .reserve) {
                            // leave a clone in the last position occupied by the piece
                            next_game_state.piece_states[player][clone_piece_index] = game_state.piece_states[player][piece_index];

                            // travel back in time
                            next_game_state.piece_states[player][piece_index] = .{
                                .active = .{ .period = game_state.piece_states[player][piece_index].period.back(), .space = game_state.piece_states[player][piece_index].space },
                            };

                            success = true;

                            break;
                        }
                    }
                    assert(success);
                },
            },
            .space_travel => |travel_amount| {
                // TODO: assert that we can travel to this space?
                next_game_state.piece_states[player][piece_index].active.space += travel_amount;
            },
        }
    }

    fn canDoSingleAction(game_state: GameState) bool {
        _ = game_state;
        // TODO:Next implement this!
        return true;
    }

    pub fn hasMovablePiece(game_state: GameState) bool {
        const player = game_state.player_turn;
        const focus = game_state.focus[player];
        // check you can do two moves!
        var reserve_count = game_state.countReservePieces(player);
        for (game_state.piece_states[player]) |piece_state| {
            if (piece_state != .active) {
                break;
            }

            // TODO:Next this all appears to be nonsense? Implement this properly.
            if (piece_state.period == focus) {
                if (piece_state.space[0] < board_size - 1) {
                    // can't move into space occupied by ourselves!
                    if (!game_state.isOccupiedByPlayer(.{ .period = piece_state.period, .space = piece_state.space + PieceSpace{ 1, 0 } }, player)) {
                        // can move back and forth - so cam defo do a full move
                        return true;
                    }
                }

                // can travel back to past!
                if (piece_state.period != .past and reserve_count > 0) {
                    if (!game_state.isOccupiedByPlayer(.{ .period = piece_state.period.back(), .space = piece_state.space }, player)) {
                        // TODO: check further moves!
                    }
                }
                // check moving to the future!
            }
        }
        // TODO: check time travel!
        return false;
    }
};

export fn construct() void {
    var game_state = GameState.construct();
    _ = game_state.evaluate();
}

const TimeTravel = enum {
    forward,
    back,
};

const SpaceTravel = @Vector(2, i2);

const MoveAction = union(enum) {
    // Period Travelling To
    time_travel: TimeTravel,
    // Space Travelling To
    space_travel: SpaceTravel,
};

const Move = struct {
    piece_index: i32, // -1 means do nothing
    actions: [2]MoveAction,
};

fn makeGoodMove(game_state: *GameState) void {
    if (!game_state.hasMovablePiece()) {
        return;
    }
    const player = game_state.player_turn;
    const focus = game_state.focus[player];
    var move: Move = undefined;
    for (game_state.piece_states[player]) |piece_state, piece_index| {
        if (piece_state == .active) {
            if (piece_state.active.period == focus) {
                move.piece_index = @intCast(i32, piece_index);

                // check for collision with own pieces!
                // can move this piece!
                if (piece_state.active.space[0] < board_size - 1) {
                    move.actions[0].space_travel = SpaceTravel{ 1, 0 };
                    break;
                }
            }
        }
    }

    // TODO: pick a good focus!
    const new_focus : Period = switch (focus) {
        .past => .present,
        .present => .future,
        .future => .past,
    };

    _ = new_focus;
}

test {
    _ = std.testing.refAllDecls(@This());
    _ = std.testing.refAllDecls(GameState);
}

// test "run random game" {
//     var game_state = GameState.construct();
//     while (true) {
//         makeGoodMove(game_state);
//         const winner = game_state.getWinner();
//         _ = game_state.hasMovablePiece();
//         if (winner.hasWinner()) {
//             // WOHOO
//             break;
//         }
//     }
// }
