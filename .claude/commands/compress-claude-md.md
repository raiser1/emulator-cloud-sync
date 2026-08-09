---
description: Compress CLAUDE.md to minimum tokens without losing a single rule
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Compress `CLAUDE.md` as far as it goes **without dropping or weakening one rule**.

Target file: `$ARGUMENTS` — if empty, use `./CLAUDE.md`.

## Procedure

**1. Baseline.** Run `bin/claude-md-stats <file>` for the size/token count. Do not skip — the before/after number is the deliverable.

**2. Inventory the rules.** Before editing, list every *normative* statement (must/never/always/prefer, plus any fact that changes what you'd do). Number them. This list is the contract; it must survive intact.

**3. Compress.** In rough order of payoff:
- Cut prose that carries no rule: intros, rationale, "this is important", transitions, closing summaries.
- Cut anything you would do anyway without being told.
- Merge duplicate/overlapping rules into one.
- Paragraph → imperative bullet. Sentence → clause. Drop articles and hedges.
- Collapse repeated-shape content (paths, flags, per-item settings) into a table or one-line list.
- Cut examples where the rule is unambiguous without them. Keep an example only where it disambiguates.
- Drop stale rules: contradicted by the code, or about files/tools no longer in the repo. Flag these to the user rather than silently deleting.
- Keep every literal string that must be typed exactly — paths, flags, package names, shebangs. Never paraphrase those.

**4. Verify.** Re-derive the rule inventory from the compressed text and diff against step 2. Any rule that lost force ("never X" → "avoid X") or specificity is a failure — restore it. Do not trade a rule for a smaller number.

**5. Report**, in this shape and nothing more:

```
before → after   N → M tokens (-P%)
cut:      <what classes of content went, one line>
merged:   <which rules combined>
flagged:  <stale/contradicted rules needing a human call, or "none">
rules:    K before, K after ✓
```

Then write the file. If it is already tight, say so and change nothing — a 0% run is a valid outcome, and padding the diff to look productive is worse than no run.

## Never
- Never drop a safety rule to save tokens. The `BISYNC_FLAGS` rails, ROM copy-only, and the root-skip behavior are load-bearing.
- Never compress into ambiguity. If two readings become possible, you cut too far.
- Never invent rules that weren't there.
