# Proof-of-Protocol (PPP)

Decentralized Quiz + Knowledge-to-Earn System  
**Version:** 2.0

## Overview

Proof-of-Protocol (PPP) is a decentralized quiz platform built on Stacks using Clarity smart contracts. It enables users to create, join, and participate in quizzes, rewarding knowledge with STX tokens.

---

## Features

- **Quiz Creation:** Anyone can create a quiz by paying a platform fee.
- **Add Questions:** Quiz creators can add multiple-choice questions.
- **Join Quiz:** Users join by staking the entry fee, which funds the reward pool.
- **Submit Answers:** Participants submit answers; scores are recorded.
- **Claim Rewards:** After the quiz closes, rewards are distributed proportionally.
- **Read-Only Functions:** Query quiz, question, and user score data.

---

## Contract Functions

### Public Functions

- `create-quiz(title, entry-fee)`  
  Create a new quiz. Pays a platform fee to the contract owner.

- `add-question(quiz-id, qid, q, a, b, c, d, correct)`  
  Add a question to a quiz (creator only).

- `join-quiz(quiz-id)`  
  Join a quiz by staking the entry fee.

- `submit(quiz-id, answers)`  
  Submit answers to a quiz (one submission per user).

- `claim(quiz-id)`  
  Claim your reward after the quiz is closed.

- `close-quiz(quiz-id)`  
  Close a quiz (creator or contract owner only).

### Read-Only Functions

- `get-quiz(id)`  
  Get quiz details by ID.

- `get-question(quiz-id, qid)`  
  Get a specific question from a quiz.

- `get-score(quiz-id, user)`  
  Get a user's score and claim status for a quiz.

---

## Data Structures

- **quizzes:** Quiz registry (id, creator, title, entry-fee, reward-pool, total-questions, participants, active)
- **questions:** Questions per quiz (quiz-id, qid, question, a, b, c, d, correct)
- **submissions:** User submissions (quiz-id, user, score, claimed)

---

## Error Codes

- `ERR-NOT-OWNER` (u100): Not authorized
- `ERR-NOT-FOUND` (u101): Not found
- `ERR-ALREADY-SUBMITTED` (u102): Already submitted
- `ERR-NOT-ACTIVE` (u103): Quiz not active
- `ERR-NO-REWARD` (u105): No reward available

---

## Usage

1. **Create a quiz:**  
   Call `create-quiz` with a title and entry fee.

2. **Add questions:**  
   Use `add-question` for each question.

3. **Join a quiz:**  
   Call `join-quiz` and pay the entry fee.

4. **Submit answers:**  
   Call `submit` with your answers.

5. **Close the quiz:**  
   The creator or owner calls `close-quiz`.

6. **Claim rewards:**  
   Participants call `claim` to receive their share.

---

## Development

- Contract: Proof-of-Protocol.clar
- Tests: Proof-of-Protocol.test.ts
- Config: Clarinet.toml, package.json

### Compile & Check

```sh
clarinet check
```

### Run Tests

```sh
npm install
npm test
```

---

## License

MIT

---
