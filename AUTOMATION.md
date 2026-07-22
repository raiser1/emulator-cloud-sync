# Hands-free auto-sync

Goal: **saves sync by themselves when you open or close an emulator**, so you
never think about it. Three levels — pick one.

---

## Level 1 — One-tap widget (easiest, no root)

Install the **Termux:Widget** add-on (from F-Droid). Then:

```bash
mkdir -p ~/.shortcuts
cat > ~/.shortcuts/Sync-Emulators <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
ecs sync
termux-toast "Emulator saves synced"
EOF
chmod +x ~/.shortcuts/Sync-Emulators

# optional second button that also grabs new ROMs
cat > ~/.shortcuts/Pull-ROMs <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
ecs pull
termux-toast "ROMs up to date"
EOF
chmod +x ~/.shortcuts/Pull-ROMs
```

Long-press your home screen → **Widgets** → **Termux:Widget** → drop it on the
home screen. Now tapping **Sync-Emulators** runs a full two-way save sync.
(`termux-toast` needs `pkg install termux-api` + the Termux:API app.)

---

## Level 2 — Fully automatic on emulator launch/exit (MacroDroid, no root)

**MacroDroid** (Play Store) can watch when an app opens or closes and fire a
Termux command — this is the "it just happens" setup.

Install **Termux:Tasker** add-on, then create these scripts:

```bash
mkdir -p ~/.termux/tasker
cp ~/.shortcuts/Sync-Emulators ~/.termux/tasker/sync 2>/dev/null || \
  printf '#!/data/data/com.termux/files/usr/bin/bash\necs sync\n' > ~/.termux/tasker/sync
chmod +x ~/.termux/tasker/sync
```

In MacroDroid, make **two macros per emulator**:

1. **On launch → fetch latest**
   - Trigger: *Application Launched* → pick your emulator (e.g. PPSSPP)
   - Action: *Tasker/Locale Plugin → Termux:Tasker* → run `sync`
   - (This pulls the newest cloud save before you play.)

2. **On close → push progress**
   - Trigger: *Application Closed* → same emulator
   - Action: *Termux:Tasker* → run `sync`
   - (This uploads the save you just made.)

Tasker works identically if you already own it (same Termux:Tasker plugin).

> Tip: keep sessions clean by syncing on **close** at minimum. Syncing on
> **launch** too protects you when you forgot to sync on another device.

---

## Level 3 — Scheduled safety net (cron, optional)

Belt-and-suspenders periodic sync so nothing is ever more than N minutes stale:

```bash
pkg install cronie termux-services
sv-enable crond
( crontab -l 2>/dev/null; echo "*/30 * * * * $PREFIX/bin/ecs auto >/dev/null 2>&1" ) | crontab -
```
Runs `ecs auto` (sync-all) every 30 minutes. Combine with Level 2 for the best
of both — instant on close, plus a periodic backstop.

---

## Rooted devices — sync on close for Android/data emulators
Everything above works the same; because `DEVICE_ROOTED=1` in your conf, `ecs`
uses the `su` staging bridge automatically for Eden/Citra/etc. The first time a
root sync runs, Termux will pop the **Grant superuser** prompt — allow it (and
"remember").

## Sanity checklist
- Play on Device A → close → (auto) push.
- Pick up Device B → open emulator → (auto) fetch → your save is there.
- If two devices edited the *same* save offline, the **newer** wins and the
  older is kept as `<name>.conflict1` — nothing is lost.
