import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
import { ask, yesno, done } from '@reach-sh/stdlib/ask.mjs';

(async () => {
  const stdlib = await loadStdlib();

  const isAlice = await ask(
    `Are you Alice?`,
    yesno
  );
  const who = isAlice ? 'Alice' : 'Bob';

  console.log(`Starting Rock, Paper, Scissors! as ${who}`);

  let acc = null;
  const createAcc = await ask(
    `Would you like to create an account? (only possible on devnet)`,
    yesno
  );
  if (createAcc) {
    acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
  } else {
    const secret = await ask(
      `What is your account secret?`,
      (x => x)
    );
    acc = await stdlib.newAccountFromSecret(secret);
  }

  let ctc = null;
  const deployCtc = await ask(
    `Do you want to deploy the contract? (y/n)`,
    yesno
  );
  if (deployCtc) {
    ctc = acc.deploy(backend);
    const info = await ctc.getInfo();
    console.log(`The contract is deployed as = ${JSON.stringify(info)}`);
  } else {
    const info = await ask(
      `Please paste the contract information:`,
      JSON.parse
    );
    ctc = acc.attach(backend, info);
  }

  const fmt = (x) => stdlib.formatCurrency(x, 9);
  const getBalance = async () => fmt(await stdlib.balanceOf(acc));

  const before = await getBalance();
  console.log(`Your balance is ${before}`);

  const interact = { ...stdlib.hasRandom };

  interact.informTimeout = () => {
    console.log(`There was a timeout.`);
    process.exit(1);
  };

  if (isAlice) {
    // TODO prevent alice from setting the wager too high
    const amt = await ask(
      `How much do you want to wager?`,
      stdlib.parseCurrency
    );
    interact.wager = amt;
  } else {
    // TODO prevent bob from accepting too high of a wager
    interact.acceptWager = async (amt) => {
      const accepted = await ask(
        `Do you accept the wager of ${fmt(amt)}?`,
        yesno
      );
      if (accepted) {
        return;
      } else {
        process.exit(0);
      }
    };
  }

  const HAND = ['Rock', 'Paper', 'Scissors'];
  const HANDS = {
    'Rock': 0, 'R': 0, 'r': 0,
    'Paper': 1, 'P': 1, 'p': 1,
    'Scissors': 2, 'S': 2, 's': 2,
  };
  // getHand (interaction)
  // - returns [countOfHandPlayed, ...hands]
  interact.getHand = async (MAX_HANDS) => {
    console.log(`You are allowed to play up to ${MAX_HANDS - 1} hands`);
    const hands = Array.from({ length: MAX_HANDS }).map(el => Number(0));
    let count;
    // use 1-based array slice to hold hands
    for (count = 1; count < MAX_HANDS; count++) {
      // get hand
      const hand = await ask(`What hand will you play?`, (x) => {
        const hand = HANDS[x];
        if (hand == null) {
          throw Error(`Not a valid hand ${hand}`);
        }
        return hand;
      });
      // show hand and save
      console.log(`You played ${HAND[hand]}`);
      hands[count] = hand
      // ask participant if they want to play another hand if not last hand
      if (count == MAX_HANDS - 1) continue
      const playAnotherHand = await ask(
        `Play another hand?`,
        yesno
      );
      if (!playAnotherHand) break;
    }
    // use 0-based head of array to hold count hands played
    hands[0] = count;
    const plural = count > 1 ? 's' : ''
    console.log(`You played ${count} hand${plural}: ${hands.slice(1, count+1).map(hand=>HAND[hand]).join(' ')}`);
    return hands;
  };

  const OUTCOME = ['Bob wins', 'Draw', 'Alice wins'];
  interact.seeOutcome = async (outcome) => {
    console.log(`The outcome is: ${OUTCOME[outcome]}`);
  };

  const part = isAlice ? backend.Alice : backend.Bob;
  await part(ctc, interact);

  const after = await getBalance();
  console.log(`Your balance is now ${after}`);

  done();
})();