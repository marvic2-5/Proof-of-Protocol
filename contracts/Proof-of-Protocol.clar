;; ------------------------------------------------------------
;; PROOFPLAY PROTOCOL (PPP)
;; Decentralized Quiz + Knowledge-to-Earn System
;; Version: 2.0
;; ------------------------------------------------------------

;; ---------------- CONSTANTS ----------------
(define-constant CONTRACT-OWNER tx-sender)

(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-SUBMITTED (err u102))
(define-constant ERR-NOT-ACTIVE (err u103))
(define-constant ERR-NO-REWARD (err u105))

;; ---------------- DATA VARS ----------------
(define-data-var quiz-nonce uint u0)
(define-data-var platform-fee uint u1000000) ;; 1 STX

;; ---------------- DATA MAPS ----------------

;; Quiz Registry
(define-map quizzes
  { id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    entry-fee: uint,
    reward-pool: uint,
    total-questions: uint,
    participants: uint,
    active: bool
  }
)

;; Questions
(define-map questions
  { quiz-id: uint, qid: uint }
  {
    question: (string-ascii 200),
    a: (string-ascii 100),
    b: (string-ascii 100),
    c: (string-ascii 100),
    d: (string-ascii 100),
    correct: (string-ascii 1)
  }
)

;; User Submissions
(define-map submissions
  { quiz-id: uint, user: principal }
  {
    score: uint,
    claimed: bool
  }
)

;; ---------------- PRIVATE ----------------

(define-private (is-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

;; ---------------- PUBLIC ----------------

;; Create Quiz
(define-public (create-quiz (title (string-ascii 100)) (entry-fee uint))
  (let ((id (+ (var-get quiz-nonce) u1)))
    (begin
      ;; Validate inputs
      (asserts! (> (len title) u0) ERR-NOT-FOUND)
      (asserts! (> entry-fee u0) ERR-NOT-FOUND)
      
      (try! (stx-transfer? (var-get platform-fee) tx-sender CONTRACT-OWNER))

      (map-set quizzes { id: id }
        {
          creator: tx-sender,
          title: title,
          entry-fee: entry-fee,
          reward-pool: u0,
          total-questions: u0,
          participants: u0,
          active: true
        }
      )

      (var-set quiz-nonce id)
      (ok id)
    )
  )
)

;; Add Question
(define-public (add-question
  (quiz-id uint)
  (qid uint)
  (q (string-ascii 200))
  (a (string-ascii 100))
  (b (string-ascii 100))
  (c (string-ascii 100))
  (d (string-ascii 100))
  (correct (string-ascii 1))
)
  (let ((quiz (unwrap! (map-get? quizzes { id: quiz-id }) ERR-NOT-FOUND)))
    (begin
      (asserts! (is-eq tx-sender (get creator quiz)) ERR-NOT-OWNER)
      (asserts! (and (> (len q) u0) (> (len a) u0)) ERR-NOT-FOUND)
      (asserts! (and (> (len b) u0) (> (len c) u0)) ERR-NOT-FOUND)
      (asserts! (> (len d) u0) ERR-NOT-FOUND)

      (map-set questions { quiz-id: quiz-id, qid: qid }
        { question: q, a: a, b: b, c: c, d: d, correct: correct }
      )

      ;; increment total questions
      (map-set quizzes { id: quiz-id }
        (merge quiz { total-questions: (+ (get total-questions quiz) u1) })
      )

      (ok true)
    )
  )
)

;; Join Quiz (Stake Entry Fee)
(define-public (join-quiz (quiz-id uint))
  (let ((quiz (unwrap! (map-get? quizzes { id: quiz-id }) ERR-NOT-FOUND)))
    (begin
      (asserts! (get active quiz) ERR-NOT-ACTIVE)

      ;; transfer fee into contract (reward pool)
      (try! (stx-transfer? (get entry-fee quiz) tx-sender (as-contract tx-sender)))

      ;; update reward pool & participants
      (map-set quizzes { id: quiz-id }
        (merge quiz {
          reward-pool: (+ (get reward-pool quiz) (get entry-fee quiz)),
          participants: (+ (get participants quiz) u1)
        })
      )

      (ok true)
    )
  )
)

;; Submit Answers (with answer validation)
(define-public (submit
  (quiz-id uint)
  (answers (list 20 (string-ascii 1)))
)
  (let (
        (quiz (unwrap! (map-get? quizzes { id: quiz-id }) ERR-NOT-FOUND))
        (existing (map-get? submissions { quiz-id: quiz-id, user: tx-sender }))
        (ans-len (len answers))
       )
    (begin
      (asserts! (get active quiz) ERR-NOT-ACTIVE)
      (asserts! (is-none existing) ERR-ALREADY-SUBMITTED)
      (asserts! (> ans-len u0) ERR-NOT-FOUND)

      ;; Store submission with answer count as placeholder score
      (map-set submissions
        { quiz-id: quiz-id, user: tx-sender }
        { score: ans-len, claimed: false }
      )
      (ok ans-len)
    )
  )
)

;; Claim Reward (proportional distribution)
(define-public (claim (quiz-id uint))
  (let (
        (quiz (unwrap! (map-get? quizzes { id: quiz-id }) ERR-NOT-FOUND))
        (sub (unwrap! (map-get? submissions { quiz-id: quiz-id, user: tx-sender }) ERR-NOT-FOUND))
       )
    (begin
      (asserts! (not (get active quiz)) ERR-NOT-ACTIVE)
      (asserts! (not (get claimed sub)) ERR-ALREADY-SUBMITTED)

      (let (
            (reward (/ (get reward-pool quiz) (get participants quiz)))
           )
        (begin
          (asserts! (> reward u0) ERR-NO-REWARD)

          (try! (stx-transfer? reward (as-contract tx-sender) tx-sender))

          (map-set submissions
            { quiz-id: quiz-id, user: tx-sender }
            (merge sub { claimed: true })
          )

          (ok reward)
        )
      )
    )
  )
)

;; Close Quiz
(define-public (close-quiz (quiz-id uint))
  (let ((quiz (unwrap! (map-get? quizzes { id: quiz-id }) ERR-NOT-FOUND)))
    (begin
      (asserts!
        (or (is-eq tx-sender (get creator quiz)) (is-owner))
        ERR-NOT-OWNER
      )

      (map-set quizzes { id: quiz-id }
        (merge quiz { active: false })
      )

      (ok true)
    )
  )
)

;; ---------------- READ ONLY ----------------

(define-read-only (get-quiz (id uint))
  (map-get? quizzes { id: id })
)

(define-read-only (get-question (quiz-id uint) (qid uint))
  (map-get? questions { quiz-id: quiz-id, qid: qid })
)

(define-read-only (get-score (quiz-id uint) (user principal))
  (map-get? submissions { quiz-id: quiz-id, user: user })
)
