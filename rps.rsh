'reach 0.1';

export const [isHand, ROCK, PAPER, SCISSORS] = makeEnum(3);
export const [isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);

/*
 * winner
 * returns outcome of two hands
 */
export const winner = (handC, handD) => ((handC + (4 - handD)) % 3)

assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(ROCK, ROCK) == DRAW);

forall(UInt, handA =>
	forall(UInt, handB =>
		assert(isOutcome(winner(handA, handB)))));

forall(UInt, (hand) =>
	assert(winner(hand, hand) == DRAW));

/*
 * min
 * returns min of two values
 */
const min = (a, b) => a < b ? a : b

assert(min(0, 1) === 0)
assert(min(1, 0) === 0)
assert(min(1, 1) === 1)

/*
 * resolveWinner
 * returns winner of sets of order hands
 */
export const resolveWinner = (a, b) =>
	((aMin) => (a.hands).zip(b.hands)
		.mapWithIndex(([x, y], i) => i > aMin ? DRAW : winner(x, y))
		.reduce(DRAW, (acc, val) => acc == DRAW ? val : acc))
		(min(a.count, b.count))

assert(resolveWinner({ count: 0, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }, { count: 0, hands: array(UInt, [PAPER, ROCK, ROCK, ROCK]) }) == B_WINS)
assert(resolveWinner({ count: 0, hands: array(UInt, [PAPER, ROCK, ROCK, ROCK]) }, { count: 0, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }) == A_WINS)
assert(resolveWinner({ count: 0, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }, { count: 0, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }) == DRAW)

forall(UInt, handA =>
	forall(UInt, handB =>
		assert(isOutcome(resolveWinner({ count: 0, hands: array(UInt, [handA, ROCK, ROCK, ROCK]) }, { count: 0, hands: array(UInt, [handB, ROCK, ROCK, ROCK]) })))));

forall(UInt, (hand) =>
	assert(resolveWinner({ count: 0, hands: array(UInt, [hand, ROCK, ROCK, ROCK]) }, { count: 0, hands: array(UInt, [hand, ROCK, ROCK, ROCK]) }) == DRAW));

assert(resolveWinner({ count: 0, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }, { count: 1, hands: array(UInt, [PAPER, PAPER, ROCK, ROCK]) }) == B_WINS)
assert(resolveWinner({ count: 0, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }, { count: 1, hands: array(UInt, [SCISSORS, PAPER, ROCK, ROCK]) }) == A_WINS)
assert(resolveWinner({ count: 0, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }, { count: 1, hands: array(UInt, [ROCK, PAPER, ROCK, ROCK]) }) == DRAW)
assert(resolveWinner({ count: 1, hands: array(UInt, [ROCK, PAPER, ROCK, ROCK]) }, { count: 1, hands: array(UInt, [PAPER, ROCK, ROCK, ROCK]) }) == B_WINS)
assert(resolveWinner({ count: 1, hands: array(UInt, [PAPER, ROCK, ROCK, ROCK]) }, { count: 1, hands: array(UInt, [PAPER, PAPER, ROCK, ROCK]) }) == B_WINS)
assert(resolveWinner({ count: 1, hands: array(UInt, [PAPER, ROCK, ROCK, ROCK]) }, { count: 1, hands: array(UInt, [ROCK, PAPER, ROCK, ROCK]) }) == A_WINS)
assert(resolveWinner({ count: 1, hands: array(UInt, [PAPER, PAPER, ROCK, ROCK]) }, { count: 1, hands: array(UInt, [PAPER, ROCK, ROCK, ROCK]) }) == A_WINS)
assert(resolveWinner({ count: 1, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }, { count: 1, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }) == DRAW)
assert(resolveWinner({ count: 2, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }, { count: 2, hands: array(UInt, [ROCK, ROCK, PAPER, ROCK]) }) == B_WINS)
assert(resolveWinner({ count: 2, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }, { count: 2, hands: array(UInt, [ROCK, ROCK, ROCK, PAPER]) }) == DRAW)
assert(resolveWinner({ count: 3, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }, { count: 3, hands: array(UInt, [ROCK, ROCK, ROCK, PAPER]) }) == B_WINS)
assert(resolveWinner({ count: 3, hands: array(UInt, [PAPER, ROCK, ROCK, ROCK]) }, { count: 3, hands: array(UInt, [ROCK, ROCK, ROCK, PAPER]) }) == A_WINS)
assert(resolveWinner({ count: 3, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }, { count: 3, hands: array(UInt, [ROCK, ROCK, ROCK, ROCK]) }) == DRAW)