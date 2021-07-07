'reach 0.1';

import 'rps.rsh'

//
// Rock Paper Scissors
//
// FEATURES
// - Make game fair 
//   1. Alternate first moves each round
// - Make game more efficient O(3n/k)
//   1. optimize for case where there is no draw
//   2. play k hands in a single round
//
// TODO 
// (1) maybe handle cases when alice attempts to wager more than she has
//     and cases when bob tries to accept a wager for more than he has
//
// CHANGELOG
// - rps.rsh code separation
// - initial, Alice and Bob play fair and optimized game of
//   rock paper scissors
// 

const DEADLINE = 100;
const MAX_HANDS = 10;

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