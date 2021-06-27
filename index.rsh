'reach 0.1';

// WORKSHOP

// Rock Paper Scissors
// Additions features
// - Make game fair for Alice
// + Even number of consensus steps for gameplay

const [isHand, ROCK, PAPER, SCISSORS] = makeEnum(3);
const [isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);
const ALICE_GOES_FIRST = 0;
const BOB_GOES_FIRST = 1;

const winner = (handA, handB) =>
  ((handA + (4 - handB)) % 3);

assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(ROCK, ROCK) == DRAW);

forall(UInt, handA =>
  forall(UInt, handB =>
    assert(isOutcome(winner(handA, handB)))));

forall(UInt, (hand) =>
  assert(winner(hand, hand) == DRAW));

const Player =
{
  ...hasRandom,
  getHand: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
  informTimeout: Fun([], Null)
};
const Alice =
{
  ...Player,
  wager: UInt
};
const Bob =
{
  ...Player,
  acceptWager: Fun([UInt], Null)
};

const DEADLINE = 100;
export const main =
  Reach.App(
    {},
    [Participant('Alice', Alice), Participant('Bob', Bob)],
    (A, B) => {
      const informTimeout = () => {
        each([A, B], () => {
          interact.informTimeout();
        });
      };
      const playRound = [
        (state) => {
          commit();
          A.only(() => {
            const _handA = interact.getHand();
            const [_commitA, _saltA] = makeCommitment(interact, _handA);
            const commitA = declassify(_commitA);
          });
          A.publish(commitA)
            .timeout(DEADLINE, () => closeTo(B, informTimeout));
          commit();
          unknowable(B, A(_handA, _saltA));
          B.only(() => {
            const handB = declassify(interact.getHand())
          });
          B.publish(handB)
            .timeout(DEADLINE, () => closeTo(A, informTimeout));
          commit();
          A.only(() => {
            const [saltA, handA] = declassify([_saltA, _handA]);
          });
          A.publish(saltA, handA)
            .timeout(DEADLINE, () => closeTo(B, informTimeout));
          checkCommitment(commitA, saltA, handA);
          return {
            outcome: winner(handA, handB),
            turn: state.turn + 1
          };
        },
        (state) => {
          commit();
          B.only(() => {
            const _handB = interact.getHand();
            const [_commitB, _saltB] = makeCommitment(interact, _handB);
            const commitB = declassify(_commitB);
          });
          B.publish(commitB)
            .timeout(DEADLINE, () => closeTo(A, informTimeout));
          commit();
          unknowable(A, B(_handB, _saltB));
          A.only(() => {
            const handA = declassify(interact.getHand());
          });
          A.publish(handA)
            .timeout(DEADLINE, () => closeTo(B, informTimeout));
          commit();
          B.only(() => {
            const [saltB, handB] = declassify([_saltB, _handB]);
          });
          B.publish(saltB, handB)
            .timeout(DEADLINE, () => closeTo(A, informTimeout));
          checkCommitment(commitB, saltB, handB);
          return {
            outcome: winner(handA, handB),
            turn: state.turn + 1
          };
        }
      ]

      A.only(() => {
        const wager = declassify(interact.wager);
      });
      A.publish(wager)
        .pay(wager);
      commit();

      B.only(() => {
        interact.acceptWager(wager);
      });
      B.pay(wager)
        .timeout(DEADLINE, () => closeTo(A, informTimeout));

      var state = {
        outcome: DRAW,
        turn: 0
      };
      invariant(balance() == 2 * wager && isOutcome(state.outcome));
      while (state.outcome == DRAW) {
        state = state.turn % 2 === 0
          ? playRound[ALICE_GOES_FIRST](state)
          : playRound[BOB_GOES_FIRST](state)
        continue;
      }

      assert(state.outcome == A_WINS || state.outcome == B_WINS);
      transfer(2 * wager).to(state.outcome == A_WINS ? A : B);
      commit();

      each([A, B], () => {
        interact.seeOutcome(state.outcome);
      });
      exit();
    });