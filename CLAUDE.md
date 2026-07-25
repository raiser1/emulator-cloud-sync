# CLAUDE.md

Persistent instructions for Claude in this project/account.

## User Rules (ADDRULE)

Rules the user has explicitly asked to persist. **Convention:** whenever the user prefixes a
message with `ADDRULE:`, append the stated rule to this list (and commit it) so it carries across
sessions.

1. **Browser-first execution.** Always check whether a task can be accomplished via the browser /
   set up locally, and do it that way when possible, *before* handing the user manual instructions.
   _(Boundary: from a cloud Claude Code session the only browser I can drive directly is this
   container's unauthenticated one; the user's authenticated browser is reached via **Claude for
   Chrome** — route browser work there and hand it a ready prompt.)_

2. **`ADDRULE:` → persist here.** Any time the user prefixes an instruction with `ADDRULE:`, add
   that rule to this file (and commit/push it) so it persists across sessions.
