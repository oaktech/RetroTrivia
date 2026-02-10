# Question Quality Audit & Fix Plan

**Audit date:** 2026-02-10
**Dataset:** `RetroTrivia/Data/questions_full_backup.json` (5,000 questions)
**Audit tool:** `RetroTrivia/Scripts/audit_questions.py`
**Report output:** `RetroTrivia/Data/audit_report.json`

---

## Summary of Findings

| Category | Count | % of total |
|---|---|---|
| Broken "All of these / Both" answers | 732 | 14.6% |
| Garbled "What X was?" questions | 328 | 6.6% |
| Exact duplicate pairs | 14 | — |
| Near-duplicate groups | 3 | — |
| Post-80s content (90s songs in 80s trivia) | 4 | — |
| Difficulty conflicts (same Q, diff difficulty) | 5 | — |
| Known factual errors | 4 | — |
| **Total unique flagged question IDs** | **757** | **15.1%** |

---

## Fix Phases

### Phase 1 — Regenerate Broken "All of these / Both" Questions (732 questions)
**Priority: Critical**

These are AI-generation failures where instead of writing a specific discriminating answer, the model wrote "All of these" or "Both" as the correct answer. They are **unplayable**.

**Detection:** `report["broken_all_of_above"]` in audit report
**Approach:**
1. Extract all 732 question IDs from the audit report.
2. For each, use the question text and wrong-answer distractors as context to **regenerate a properly specific question** with one unambiguous correct answer.
3. Regeneration prompt template:
   ```
   Rewrite this 80s music trivia question so it has a single specific correct answer
   (not "All of these" or "Both"). Keep the same topic and difficulty level.

   Original: {question}
   Options were: {options}
   Difficulty: {difficulty}
   Category: {category}

   Return: { "question": "...", "options": ["...", "...", "...", "..."], "correctIndex": N }
   ```
4. Validate regenerated questions before writing to file.
5. Keep original IDs — only replace question/options/correctIndex fields.

**Estimated effort:** ~4–6 LLM batch calls at 150 questions each.

---

### Phase 2 — Rewrite Garbled "What X was?" Questions (328 questions)
**Priority: High**

These have malformed sentence structure ("What Arcadia was?", "What cEvin Key contributed?").
Most are salvageable — the topic is valid, just the phrasing is broken.

**Detection:** `report["garbled_questions"]` in audit report
**Approach:**
1. Extract all 328 IDs.
2. Many overlap with Phase 1 (broken answer too). Handle them in Phase 1 regeneration.
3. For the remainder (garbled question but valid answer), rewrite **only the question text**.
4. Regeneration prompt template:
   ```
   Rewrite this malformed trivia question into a proper grammatical question.
   The correct answer and difficulty should remain the same.

   Malformed: {question}
   Correct answer: {correct_answer}
   All options: {options}
   Difficulty: {difficulty}

   Return only: { "question": "..." }
   ```

**Estimated effort:** ~3 LLM batch calls at ~110 questions each.

---

### Phase 3 — Resolve Exact Duplicates (14 pairs)
**Priority: High**

14 questions appear twice with different IDs. In some cases they have conflicting difficulty ratings or conflicting answers.

**Detection:** `report["exact_duplicates"]` in audit report
**Approach — for each pair:**

| Question | Keep | Delete | Note |
|---|---|---|---|
| "What year did MTV launch?" | q3986 (easy) | q0005 (medium) | Easy is correct |
| "Who was lead singer of INXS?" | q2466 (easy) | q0078 (medium) | Easy is correct |
| "Who founded Def Jam Records?" | q0324 (medium) | q2253 (medium) | q0324 has better answer order |
| "Who was lead singer of Spandau Ballet?" | q0268 | q2699 | Either; delete q2699 |
| "Life's Rich Pageant — which band?" | q2855 | q4860 | Delete q4860 |
| "Zen Arcade — which band?" | q4725 | q3856 | q4725 has correct Hüsker Dü diacritic |
| "What Dead Can Dance fused?" | q0699 | q1655 | q0699 has correct specific answer; q1655 says "Both" |
| "What does LL Cool J stand for?" | q2249 (easy) | q0323 (medium) | Easy is correct |
| "Who produced Eddie Murphy's Party All the Time?" | q2067 (medium) | q0227 (hard) | Medium is correct |
| "What was distinctive about Land of Confusion?" | q0543 (medium) | q2083 (medium) | Delete q2083 |
| "Who was lead singer of Pet Shop Boys?" | q2336 (medium) | q0257 (hard) | Medium is correct |
| "Who was lead singer of Siouxsie?" | q0691 (easy) | q2399 (easy) | Delete q2399 |
| "Flashdance Oscar year?" | q2547 (medium) | q4050 (medium) | q2547 has more complete answer |
| "Souvlaki — which shoegaze band?" | q3913 | q4845 | Delete q4845 |

**Script to write:** `Scripts/fix_duplicates.py` — reads audit report, outputs cleaned JSON.

---

### Phase 4 — Fix Known Factual Errors (4 questions)
**Priority: High**

**q0276** — *"What was George Michael's first solo #1 after Wham!?"*
- Current answer: "Careless Whisper" ❌
- Fix: Change answer to "A Different Corner" (1986 UK #1) OR rewrite question as:
  *"'Careless Whisper' (1984) was released while George Michael was in which group?"* → Wham!

**q0749** — *"What 1985 Grammy saw Michael Jackson sweep?"*
- Current: "8 awards including Album of the Year" (correct count, wrong year)
- Fix: Change question to "What **1984** Grammy ceremony saw Michael Jackson sweep?"

**q0109** — *"Which Toto song won multiple Grammy Awards in 1983?"* → Rosanna
- Misleading: "Africa" won Record of the Year; "Rosanna" won Best Pop Group Vocal
- Fix: Rewrite as *"Which Toto song won the Grammy for Record of the Year in 1983?"* → Africa

**q0699 / q1655** — Dead Can Dance duplicate with conflicting answers
- Keep q0699 (answer: "World music and gothic"), delete q1655 (answer: "Both")
- Handled in Phase 3.

---

### Phase 5 — Tag / Remove Post-80s Content (4+ questions)
**Priority: Medium**

Questions about songs clearly released after 1989:
- q4112: "Tears in Heaven" (1992) — remove or tag as "bonus 90s"
- q3136: "Silent Lucidity" (1991)
- q2985: "k.d. lang's Constant Craving" (1992)
- q2551: "Sit Down" by James (1991)

**Approach:** Either remove entirely, or if the game ever expands to "90s" mode, add a `decade: "90s"` field to these questions and filter them out of 80s mode.

---

### Phase 6 — Recalibrate Difficulty on Conflicts (5 pairs)
**Priority: Low**

Where the same question appears with two different difficulty ratings, standardize:

| Question | Current | Correct |
|---|---|---|
| "What year did MTV launch?" | medium + easy | **easy** |
| "Who was lead singer of INXS?" | medium + easy | **easy** |
| "Who produced Eddie Murphy's Party All the Time?" | hard + medium | **medium** |
| "Who were the two members of Pet Shop Boys?" | hard + medium | **medium** |
| "What does LL Cool J stand for?" | medium + easy | **easy** |

Also recalibrate these individual outliers:
- "Who was lead singer of Siouxsie and the Banshees?" — currently easy → should be **medium**
- "What Fleetwood Mac album was released in 1987?" — currently hard → should be **medium**
- "Who left Fleetwood Mac in 1987?" — currently hard → should be **medium**
- "What year did the first MTV VMAs air?" — currently medium → should be **easy**

---

## Execution Order

```
Phase 1 (regenerate 732 broken answers)    ← biggest impact, do first
Phase 2 (rewrite 328 garbled questions)    ← many overlap with Phase 1
Phase 3 (resolve 14 duplicate pairs)       ← quick, manual list above
Phase 4 (fix 4 factual errors)             ← quick, surgical edits
Phase 5 (tag/remove post-80s content)      ← depends on game scope decision
Phase 6 (recalibrate difficulty outliers)  ← polish pass, last
```

---

## Scripts

| Script | Purpose |
|---|---|
| `Scripts/audit_questions.py` | Detects all issues, outputs `Data/audit_report.json` |
| `Scripts/fix_duplicates.py` | Removes duplicate entries per Phase 3 table (TODO) |
| `Scripts/fix_factual_errors.py` | Applies Phase 4 surgical edits (TODO) |
| `Scripts/regenerate_broken.py` | Sends Phase 1/2 questions to LLM for rewrite (TODO) |
| `Scripts/apply_fixes.py` | Merges all fix outputs into a clean questions.json (TODO) |

---

## Acceptance Criteria

After all phases, re-run `audit_questions.py` and verify:
- `broken_all_of_above`: 0
- `garbled_questions`: 0
- `exact_duplicate_pairs`: 0
- `known_factual_errors`: 0
- `post_80s_content`: 0 (or moved to separate decade tag)
- Total flagged: < 10 (only near-dupes that need human review)
