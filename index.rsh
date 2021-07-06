'reach 0.1';

// WORKSHOP

// Rock Paper Scissors
// Additions features etc
// - Make game fair 
// + Alternate first moves
// - Make game more efficient O(3n/100)
// + optimize for case where there is no draw
// - play k hands in a single round
//
// TODO 
// (1) maybe handle cases when alice attempts to wager more than she has
//     and cases when bob tries to accept a wager for more than he has
//

const DEADLINE = 100;
const [isHand, ROCK, PAPER, SCISSORS] = makeEnum(3);
const [isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);
const MAX_HANDS = 10;

/*
 * winner
 * returns outcome of two hands
 */
const winner = (handC, handD) => ((handC + (4 - handD)) % 3)

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
const resolveWinner = (a, b) =>
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

const Player =
{
  ...hasRandom,
  getHand: Fun([UInt], Object({
    hands: Array(UInt, MAX_HANDS),
    count: UInt
  })),
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

      /*
       * informTimeout 
       * broadcasts timeout
       */
      const informTimeout = () =>
        each([A, B], () => {
          interact.informTimeout();
        });

      /*
       * isEvenTurn
       * returns true if turn is even else false 
       */
      const isEvenTurn = state
        => state.turn % 2 === 0

      /*
       * isAWinner
       * returns true if outcome is a wins else false
       */
      const isAWinner = state
        => state.outcome == A_WINS

      /*
       * nextState
       * returns state of next turn
       */
      const nextState = state
        => (aHands, bHands)
          => ({
            outcome: resolveWinner(aHands, bHands),
            turn: state.turn + 1
          })

      /*
       * playHands, main w/o wager
       * returns next state
       */
      const playHands = state => (C, D) => {
        C.only(() => {
          const _handA = interact.getHand(MAX_HANDS);
          const [_commitA, _saltA] = makeCommitment(interact, _handA);
          const commitA = declassify(_commitA);
        });
        C.publish(commitA)
          .timeout(DEADLINE, () => closeTo(B, informTimeout));
        commit();
        unknowable(D, C(_handA, _saltA));
        D.only(() => {
          const handB = declassify(interact.getHand(MAX_HANDS))
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
        return nextState(state)(handA, handB);
      }

      /*
       * playRound, body of while loop
       * returns next state
       */
      const playRound = state => (C, D) => {
        commit();
        return playHands(state)(C, D);
      }

      /*
       * adjustPartial
       * returns function (a, b) => member of [a,b] depending on state
       */
      const adjustPartial = state
        => ((evenTurn, aWins)
          => (a, b)
            => evenTurn ?
              aWins ? b : a :
              aWins ? a : b)(isEvenTurn(state), isAWinner(state))

      /*main*/
      A.only(() => {
        const wager = declassify(interact.wager);
        const _handA = interact.getHand(MAX_HANDS);
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
        const handB = declassify(interact.getHand(MAX_HANDS))
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
      var state = nextState({ turn: 0 })(handA, handB);
      invariant(balance() == 2 * wager && isOutcome(state.outcome));
      while (state.outcome == DRAW) {
        // role switch
        state = isEvenTurn(state)
          ? playRound(state)(A, B)
          : playRound(state)(B, A)
        continue;
      }
      assert(state.outcome == A_WINS || state.outcome == B_WINS);
      transfer(2 * wager).to(adjustPartial(state)(A, B)); // handle case of outcome that Bob plays as Alice
      commit();
      each([A, B], () => {
        interact.seeOutcome(adjustPartial(state)(A_WINS, B_WINS)); // handle case of outcome that Bob plays as Alice
      });
      exit();
    });