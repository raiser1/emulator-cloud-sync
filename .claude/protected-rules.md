# Protected rules — emulator-cloud-sync

Read by `/compress-claude-md`. Every rule named here is load-bearing: it may not be
weakened, merged, paraphrased, or dropped to save tokens. Losing any one of them
risks destroying save data.

1. **ROMs are copy-only.** `rclone copy` only — never `sync`, never `bisync`, never
   any delete flag.
2. **Every `BISYNC_FLAGS` rail, verbatim**: `--conflict-resolve newer`,
   `--conflict-loser pathname`, `--max-delete 25`, `--resilient --recover`. All four
   must survive with their exact literal spelling.
3. **Nothing is hard-deleted.** Conflict losers are retained as `<name>.conflict1`.
4. **`root 1` profiles skip with a message on `DEVICE_ROOTED=0`** — they never fail
   the run, and no workaround for the Android 11+ `Android/data` restriction may be
   invented.
5. **Shebang exactly `#!/data/data/com.termux/files/usr/bin/bash`**, LF endings.
6. **Never commit `.ecs/` or `*.log`.**

Literal strings above are typed exactly as shown. Paraphrasing a flag is the same
failure as deleting it.
