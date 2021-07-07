'reach 0.1';

import 'rps.rsh'

//
// Rock Paper Scissors
//
// FEATURES
// - Make game fair 
//   1. Alternate first moves
// - Make game more efficient O(3n)
//   1. Optimize for case where there is no draw
//

const DEADLINE = 100;

const Player =
{
	...hasRandom,
	getHand: Fun([], UInt),
	seeOutcome: Fun([UInt], Null),
	informTimeout: Fun([], Null),
};
const Alice =
{
	...Player,
	wager: UInt,
};
const Bob =
{
	...Player,
	acceptWager: Fun([UInt], Null),
};

export const main =
	Reach.App(
		{},
		[Participant('Alice', Alice), Participant('Bob', Bob)],
		(A, B) => {
			const isEvenTurn = state => state.turn % 2 === 0;

			const informTimeout = () => {
				each([A, B], () => {
					interact.informTimeout();
				});
			};

			const playHands = (state, C, D) => {
				C.only(() => {
					const _handA = interact.getHand();
					const [_commitA, _saltA] = makeCommitment(interact, _handA);
					const commitA = declassify(_commitA);
				});
				C.publish(commitA)
					.timeout(DEADLINE, () => closeTo(B, informTimeout));
				commit();
				unknowable(D, C(_handA, _saltA));
				D.only(() => {
					const handB = declassify(interact.getHand())
				});
				D.publish(handB)
					.timeout(DEADLINE, () => closeTo(C, informTimeout));
				commit();
				C.only(() => {
					const [saltA, handA] = declassify([_saltA, _handA]);
				});
				C.publish(saltA, handA)
					.timeout(DEADLINE, () => closeTo(D, informTimeout));
				checkCommitment(commitA, saltA, handA);
				return {
					outcome: winner(handA, handB),
					turn: state.turn + 1
				};
			}

			const playRound = (state, C, D) => {
				commit();
				return playHands(state, C, D);
			}

			A.only(() => {
				const wager = declassify(interact.wager);
				const _handA = interact.getHand();
				const [_commitA, _saltA] = makeCommitment(interact, _handA);
				const commitA = declassify(_commitA);
			});
			A.publish(wager, commitA)
				.pay(wager)
				.timeout(DEADLINE, () => closeTo(B, informTimeout));
			commit();
			unknowable(B, A(_handA, _saltA));
			B.only(() => {
				interact.acceptWager(wager);
				const handB = declassify(interact.getHand())
			});
			B.publish(handB)
				.pay(wager)
				.timeout(DEADLINE, () => closeTo(A, informTimeout));
			commit();
			A.only(() => {
				const [saltA, handA] = declassify([_saltA, _handA]);
			});
			A.publish(saltA, handA)
				.timeout(DEADLINE, () => closeTo(B, informTimeout));
			checkCommitment(commitA, saltA, handA);
			var state = { outcome: winner(handA, handB), turn: 1 };
			invariant(balance() == 2 * wager && isOutcome(state.outcome));
			while (state.outcome == DRAW) {
				state = isEvenTurn(state)
					? playRound(state, A, B)
					: playRound(state, B, A)
				continue;
			}

			assert(state.outcome == A_WINS || state.outcome == B_WINS);
			transfer(2 * wager).to(state.outcome == A_WINS ? A : B);
			commit();

			each([A, B], () => {
				interact.seeOutcome(state.outcome);
			});
			exit();
		}
	);
