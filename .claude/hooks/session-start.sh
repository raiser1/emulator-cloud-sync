#!/bin/bash
# SessionStart hook — install what `ecs` is verified with.
#
# This repo has no package manifest and no test suite. Per CLAUDE.md its
# verification is exactly `bash -n bin/ecs` plus `shellcheck`. bash ships with
# the container; shellcheck does not. Installing it is the whole job.
#
# Deliberately does NOT install rclone or anything Android: the emulator paths
# and rclone remotes cannot exist here, and pretending otherwise would invite
# claims that runtime behavior was tested. It cannot be, in this container.
set -euo pipefail

# Web sessions only — a local Termux checkout has its own toolchain.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

if command -v shellcheck >/dev/null 2>&1; then
  echo "session-start: shellcheck $(shellcheck --version | awk '/^version:/{print $2}') already present"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

install_shellcheck() {
  apt-get install -y --no-install-recommends shellcheck >/dev/null 2>&1
}

# The image ships a populated apt index, so the plain install usually hits it
# without a network round trip. Only refresh if that misses.
if ! install_shellcheck; then
  apt-get update >/dev/null 2>&1 || true
  install_shellcheck || true
fi

if command -v shellcheck >/dev/null 2>&1; then
  echo "session-start: installed shellcheck $(shellcheck --version | awk '/^version:/{print $2}')"
else
  # Fail open. A transient apt outage should not block the session from
  # starting — but the agent must know the linter is missing rather than
  # discover it as a confusing 'command not found' mid-task.
  echo "session-start: WARNING — shellcheck could not be installed."
  echo "session-start: \`bash -n\` still works; skip shellcheck and say so rather than claiming a clean lint."
fi
