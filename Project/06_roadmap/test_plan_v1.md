# Lumen v1 — Test Plan

This is the master test plan for v1 (Sprints 1-3 deliverable). It is the single source of truth for both:

- **Automated QA agent passes** on the iOS Simulator (during dev sessions).
- **Manual verification on a real iPhone** before the PALO handoff (11 May 2026).

## How to read this document

Every test has the following fields:

- **ID** — stable identifier (e.g., `S1.OB.01`). Use this in QA reports.
- **Scope** — which v1 phase implements it: `pre-flight` / `sprint-1` / `sprint-2` / `sprint-3`.
- **Channel** — where it's runnable:
  - `simulator` → the QA agent can run it via computer-use on the iOS Simulator.
  - `device-only` → requires a real iPhone (background alarm, microphone, audio session).
  - `manual` → requires human judgment (visual fidelity, haptics, VoiceOver narration).
- **Status** — `not-built` / `ready` / `passing` / `failing` / `skipped`. Updated by each QA pass.
- **Steps** — ordered actions.
- **Expected** — what should happen.

The QA agent runs **only tests with `Channel: simulator` AND `Status: ready` or `failing`** in the current build. It skips `not-built`, `device-only`, and `manual`.

The user runs **all `device-only` and `manual` tests** on a real iPhone before submission.

## Current build state (auto-updated by orchestrator)

- **Branch:** `worktree-feat+preflight-scaffold`
- **As of date:** 2026-04-27
- **Built features:** pre-flight scaffold only (placeholder root view, design tokens, app state machine actor, composition root).
- **Not yet built:** every Sprint 1+ feature.

## Section 0 — Pre-flight scaffold (current scope)

### S0.LAUNCH.01 — App launches without crash
- **Scope:** pre-flight
- **Channel:** simulator
- **Status:** ready
- **Steps:**
  1. Tap the Lumen app icon on the simulator home screen (or `xcrun simctl launch booted com.highthem.lumen`).
- **Expected:** App opens to the placeholder root view within 3 seconds. No crash. No system error dialog.

### S0.RV.01 — Root view shows hero copy in serif display
- **Scope:** pre-flight
- **Channel:** simulator
- **Status:** ready
- **Steps:**
  1. Launch the app.
- **Expected:** "Lumen" rendered in large serif (Charter/New York). Subtitle "Pre-flight scaffold" in sans-serif callout. Both centered.

### S0.RV.02 — Background uses bgPrimary token
- **Scope:** pre-flight
- **Channel:** simulator
- **Status:** ready
- **Steps:**
  1. Launch the app in **Dark** appearance.
  2. Inspect the background color.
  3. Switch the simulator to **Light** appearance (`xcrun simctl ui booted appearance light`).
  4. Inspect again.
- **Expected:**
  - Dark: warm near-black (`#0F0D0B`).
  - Light: cream (`#FAF6EF`).
  - Foreground text contrast remains legible in both.

### S0.RV.03 — Text foreground uses textPrimary token
- **Scope:** pre-flight
- **Channel:** simulator
- **Status:** ready
- **Steps:** As S0.RV.02.
- **Expected:**
  - Dark: warm off-white "Lumen" text (`#F5EFE6`).
  - Light: ink-black text (`#1F1A14`).

### S0.IDL.01 — App reaches `idle` state on launch
- **Scope:** pre-flight
- **Channel:** simulator (indirectly, via UI consequence — no debug overlay)
- **Status:** ready
- **Steps:** Launch app, observe.
- **Expected:** No alarm-ringing UI shown, no ritual-active UI shown. Just the placeholder. (When AlarmRingingView ships, the placeholder being visible is the implicit assertion that state is `idle`.)

## Section 1 — Onboarding (Sprint 1)

### S1.OB.01 — Welcome screen, kinetic typography
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:**
  1. First-launch (delete + reinstall app to reset onboarding flag).
  2. Wait for animation.
- **Expected:** "Quelques minutes à toi." appears word-by-word, ~110ms stagger. Italic serif subtitle "Un rituel matinal pour commencer avec intention." follows. Two CTAs: "Commencer" (primary), "J'ai déjà un compte" (ghost).

### S1.OB.02 — Pitch screen
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap "Commencer" on welcome.
- **Expected:** "Cinq minutes." appears, then "Pas plus." 600ms later in italic at 0.55 opacity. Subtitle "Pour cadrer ta journée avant qu'elle ne te cadre." in sans. Primary CTA "Suivant".

### S1.OB.03 — Permissions screen, notification request
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap "Suivant" on pitch.
- **Expected:** Title "On a besoin de deux choses." Two cards: notifications (chip "Activer") + audio (chip "Demander"). Tapping "Activer" triggers the iOS notification authorization dialog. Italic serif "On ne t'envoie rien d'autre. Promis." footer.

### S1.OB.04 — First alarm time picker
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap "Continuer" after granting notifications.
- **Expected:** Title "À quelle heure veux-tu commencer ?" Wheel time picker, default 07:00. Subtext "Tu pourras changer plus tard." Primary CTA "Programmer".

### S1.OB.05 — Onboarding completion flag persists
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Complete onboarding once, then kill + relaunch app.
- **Expected:** Onboarding does not re-show. App lands on Dashboard.

## Section 2 — Alarm UI (Sprint 1)

### S1.AL.01 — Alarm list shows scheduled alarm
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:** After completing onboarding with 07:00 alarm.
- **Expected:** Alarm list view shows row for 07:00 with active toggle on, recurrence text, sound name.

### S1.AL.02 — Add new alarm
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap "+" toolbar button.
- **Expected:** AlarmEdit sheet opens. Time picker, recurrence segmented (Never/Weekdays/Everyday/Custom), sound picker (3 options), active toggle, "Enregistrer" CTA.

### S1.AL.03 — Edit alarm
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap an alarm row.
- **Expected:** AlarmEdit opens populated with current values. "Supprimer" button at bottom.

### S1.AL.04 — Delete alarm
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Swipe-delete row.
- **Expected:** Confirmation prompt; on confirm, row removed and OS notification cancelled.

### S1.AL.05 — Toggle alarm active
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Toggle off an alarm.
- **Expected:** OS notification cancelled. Toggle persists across app restart.

### S1.RG.01 — AlarmRinging V4 (foreground)
- **Scope:** sprint-1
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Force a fake `alarmFired` event via a dev-only entry point (or schedule alarm 30s out, leave app foreground).
- **Expected:** Eyebrow "Lundi 11 mai" (or current date). Serif 96pt time. Horizon line. Italic serif murmured copy. Sunrise gradient rises 4s from bottom 36%, then breathes. Snooze button (glassmorphism) above Silence (primary). Haptic `.medium` on Silence tap.

## Section 3 — Background alarm reliability (Sprint 1, REAL DEVICE)

### D1.BG.01 — Alarm fires when device locked
- **Scope:** sprint-1
- **Channel:** device-only
- **Status:** not-built
- **Steps:**
  1. On a real iPhone, schedule alarm for 5 minutes from now. Ringer ON, not in DND/Focus.
  2. Lock device. Screen off.
  3. Wait.
- **Expected:** Notification fires at the scheduled time, plays the configured sound.

### D1.BG.02 — Snooze action from lock screen
- **Scope:** sprint-1
- **Channel:** device-only
- **Status:** not-built
- **Steps:** When the lock-screen notification fires, tap "Snooze".
- **Expected:** Snooze count increments (verify by inspecting SwiftData via debug console after unlocking). Notification re-fires +5 minutes.

### D1.BG.03 — Snooze cap of 3
- **Scope:** sprint-1
- **Channel:** device-only
- **Status:** not-built
- **Steps:** Tap snooze 3 times consecutively.
- **Expected:** 4th notification has Snooze action removed; only Silence remains.

### D1.BG.04 — Silence action stops chain
- **Scope:** sprint-1
- **Channel:** device-only
- **Status:** not-built
- **Steps:** Tap "Silence" from lock-screen notification.
- **Expected:** No further notifications. App opens to AlarmRinging or Timer view (TBD per state machine wiring) when next launched.

### D1.BG.05 — Audio session ducks Spotify/podcast
- **Scope:** sprint-1
- **Channel:** device-only
- **Status:** not-built
- **Steps:** Play Spotify, schedule alarm 1 minute out, leave app foreground, wait.
- **Expected:** Spotify volume ducks while alarm sound plays. Restores after Silence.

## Section 4 — Timer + Questionnaire (Sprint 2)

### S2.T.01 — Timer breathing circle
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** From Silence, tap "Démarrer le rituel".
- **Expected:** Filling circle with breath animation (scale 1→1.045 over 4s, ease-in-out, infinite). Italic serif quote in center. No countdown numerals. Ghost "Passer" CTA.

### S2.T.02 — Timer auto-advances to Q1 at 0
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Wait 60s on timer, OR tap "Passer".
- **Expected:** Haptic `.soft` plays. Transition to Q1 Mood with crossfade.

### S2.Q1.01 — Q1 Mood, sun rising glyphs (V4)
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Land on Q1.
- **Expected:** Eyebrow "01 / 04 · Ressenti". Serif title "Comment tu te sens ?". 5 SunGlyph buttons (level 0 enfoui → level 4 rayonnant), italic serif tags below. Tapping a glyph: scale 1.10, halo, tag accent-colored. Primary "Suivant" enabled.

### S2.Q2.01 — Q2 Priority, 6 chips
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap Suivant from Q1.
- **Expected:** "Qu'est-ce qui compte aujourd'hui ?" 6 chips (Énergie, Intention, Corps, Relations, Travail, Gratitude). Optional 3-line textarea. Suivant enabled when ≥1 chip selected.

### S2.Q3.01 — Q3 Gratitude, voice default
- **Scope:** sprint-2
- **Channel:** simulator (mic permission denied → typing fallback)
- **Status:** not-built
- **Steps:** Tap Suivant from Q2.
- **Expected:** MicrophoneButton centered (96pt, idle state with serif `"` glyph). "Modifier" + "Recommencer" ghost buttons. Italic serif placeholder "Parle, je t'écoute…". Tap mic → permission dialog appears (simulator).

### S2.Q3.02 — Q3 Voice listening (Sunrise Echo)
- **Scope:** sprint-2
- **Channel:** device-only (simulator can't accept mic input cleanly)
- **Status:** not-built
- **Steps:** On device, tap mic, speak "le silence avant que les arbres bougent".
- **Expected:** Listening state: radial accent gradient, 4s breath, single tracing arc 0°→360° per cycle. LiveTranscript serif 38pt reveals char-by-char (80ms/char). Auto-stop ~2s after silence.

### S2.Q3.03 — Q3 fallback to typing when on-device unsupported
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Force `supportsOnDeviceRecognition=false` via debug toggle (TBD).
- **Expected:** Mic button disabled, keyboard input visible. Friendly explanation text: "Reconnaissance non disponible pour ta langue. Tu peux écrire."

### S2.Q4.01 — Q4 Intention, voice default, single word
- **Scope:** sprint-2
- **Channel:** device-only
- **Status:** not-built
- **Steps:** Tap Suivant from Q3.
- **Expected:** Same Sunrise Echo pattern, LiveTranscript 64pt italic accent, faster char reveal (120ms).

## Section 5 — AI synthesis (Sprint 2)

### S2.SY.01 — Synthesis cloud success path
- **Scope:** sprint-2
- **Channel:** simulator (with valid OPENAI_API_KEY)
- **Status:** not-built
- **Steps:** Complete Q1-Q4 with online network, valid key.
- **Expected:** SynthesisView shows 3 sequential reveal blocks (Intention/Focus/Reminder), staggered fade+slide-up 250ms. SpeakerButton "Écouter" visible. Compteur régénérations "2/3 restantes". Returns within ~5s.

### S2.SY.02 — Synthesis offline fallback (queued)
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Toggle airplane mode before submitting Q4.
- **Expected:** Queued state UI: SlowPulse circle + "Ta synthèse arrive" copy. Local notification fires when network restored and synthesis completes.

### S2.SY.03 — Synthesis Apple Intelligence fallback
- **Scope:** sprint-2
- **Channel:** device-only (iOS 26+ A17 Pro+)
- **Status:** not-built
- **Steps:** With cloud blocked + AI available, complete Q4.
- **Expected:** AI badge with shimmer + "Généré localement · aucun envoi réseau".

### S2.SY.04 — Synthesis self-harm short-circuit
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Inject Q3 with the trigger word (TBD test fixture). Submit Q4.
- **Expected:** No cloud HTTP request issued (verify via Network log). Returns SupportResources template with crisis hotline numbers. EthicalLog entry has `selfHarmCue` flag.

### S2.SY.05 — Rate limit "Limite atteinte"
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Trigger 3 manual regens, then 4th.
- **Expected:** Calm message "Limite atteinte pour aujourd'hui — reviens demain." No error. EthicalLog still receives the attempt.

### S2.SY.06 — TTS "Écouter" reads with neural voice
- **Scope:** sprint-2
- **Channel:** device-only (simulator TTS quality varies)
- **Status:** not-built
- **Steps:** On synthesis screen, tap "Écouter".
- **Expected:** AVSpeechSynthesizer plays Intention block first. Reading focus mode: only current paragraph at full opacity, others 0.32. Eyebrow dot breathes. Pause/resume works.

### S2.SY.07 — TTS auto-pauses when scrolled out
- **Scope:** sprint-2
- **Channel:** device-only
- **Status:** not-built
- **Steps:** Start TTS, scroll synthesis off-screen, scroll back.
- **Expected:** TTS pauses on scroll-out, does not auto-resume. User can tap to resume.

## Section 6 — Dashboard (Sprint 2)

### S2.DB.01 — Empty state (first launch, no ritual ever done)
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Fresh install, skip onboarding to dashboard (or complete with no alarm scheduled).
- **Expected:** Serif "Ton premier matin t'attend." + subtitle + CTA "Programmer mon réveil".

### S2.DB.02 — Idle state (ritual not done today)
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Have alarm scheduled, no ritual completed today.
- **Expected:** Banner "Tu n'as pas encore fait ton rituel. Prêt ?" + secondary CTA "Démarrer". 6 grayed placeholder cards below.

### S2.DB.03 — Post-rituel state (filled cards)
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** After completing morning ritual.
- **Expected:** Eyebrow date, serif title "Aujourd'hui". 2-col grid of 6 cards: Énergie (mood emoji + tag), Intention (1-3 words serif), Corps, Relations, Travail, Gratitude. Floating Ask Lumen FAB bottom-right.

### S2.DB.04 — Ask Lumen modal opens from FAB
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap Ask Lumen FAB.
- **Expected:** Half-sheet modal opens. Pre-prompt template visible. Send button + close.

### S2.DB.05 — Category detail
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap any card.
- **Expected:** Detail view with today's content, last-7-days list, "Ask Lumen" contextual CTA.

### S2.DB.06 — 3am rolling-day reset
- **Scope:** sprint-2
- **Channel:** simulator (set sim clock past 3am)
- **Status:** not-built
- **Steps:** After ritual done day N, advance sim clock past 3am day N+1, reopen app.
- **Expected:** Dashboard returns to Idle (or Empty if fresh) state. Yesterday's data accessible via category detail's "7 derniers jours" list.

## Section 7 — Settings (Sprint 2)

### S2.ST.01 — Settings sections render
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Open Settings.
- **Expected:** Sections in order: Ritual, Voice, IA, Ethical Monitoring, Appearance, About.

### S2.ST.02 — Voice settings (toggle, voice picker, speed)
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap Voice section.
- **Expected:** Toggle "Mode vocal par défaut" (true default). Voice picker shows iOS neural FR + EN voices, preview-on-tap. Speed segmented 0.8/1.0/1.2. Italic privacy notice. "Vérifier les permissions" link.

### S2.ST.03 — IA waterfall status display
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap IA section.
- **Expected:** WaterfallStatusList: 4 steps (OpenAI → Anthropic → Apple Intelligence → Queue) with dots (live=green/standby=muted/warn=amber).

### S2.ST.04 — Export ethical logs
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap "Exporter en JSON".
- **Expected:** ShareSheet opens with valid JSON file. JSON validates against schema in `data_model.md` §Export JSON. No PII. Prompt hashes present. `mode: auto`/`manualRegenerate`/`fallbackQueued`/`fallbackOnDevice` values seen.

### S2.ST.05 — Erase logs
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Tap "Effacer mes logs", confirm.
- **Expected:** All EthicalLog entries removed. Subsequent export returns empty JSON.

### S2.ST.06 — Appearance toggle
- **Scope:** sprint-2
- **Channel:** simulator
- **Status:** not-built
- **Steps:** Switch dark/light/system.
- **Expected:** All screens adapt.

## Section 8 — Manual checks (Sprint 3 polish)

### M3.A11.01 — VoiceOver on all interactive elements
- **Scope:** sprint-3
- **Channel:** manual
- **Status:** not-built
- **Steps:** Enable VoiceOver. Navigate every screen.
- **Expected:** Every button has a clear `.accessibilityLabel`. MicrophoneButton announces state ("écoute / transcription terminée"). Cards group children with `.combine`.

### M3.A11.02 — Dynamic Type up to AccessibilityXXXL
- **Scope:** sprint-3
- **Channel:** manual
- **Status:** not-built
- **Steps:** Settings → Accessibility → Larger Text → AccessibilityXXXL.
- **Expected:** All screens scale, no truncation. Wheel time picker still readable. Questionnaire chips wrap.

### M3.A11.03 — Reduce Motion
- **Scope:** sprint-3
- **Channel:** manual
- **Status:** not-built
- **Steps:** Settings → Accessibility → Reduce Motion ON.
- **Expected:** Timer breath becomes static. MicrophoneButton tracing arc frozen at 300°. LiveTranscript instant. Synthesis reveal is crossfade only. AlarmSunrise gradient static.

### M3.A11.04 — Reduce Transparency
- **Scope:** sprint-3
- **Channel:** manual
- **Status:** not-built
- **Steps:** Settings → Accessibility → Reduce Transparency ON.
- **Expected:** AlarmRinging Snooze button (glassmorphism by default) becomes opaque.

### M3.HP.01 — Haptics
- **Scope:** sprint-3
- **Channel:** device-only
- **Status:** not-built
- **Steps:** Run full ritual.
- **Expected:** `.medium` on Silence tap. `.soft` at timer end. `.success` when synthesis appears.

### M3.VF.01 — Visual fidelity vs maquettes
- **Scope:** sprint-3
- **Channel:** manual
- **Status:** not-built
- **Steps:** Compare every screen against `_handoff/project/screens/screens.jsx`/`screens-v3.jsx`/`screens-v4.jsx` artboards in dark + light.
- **Expected:** Spacing, alignment, typography weights match. Tolerable variance: ±2pt.

## Section 9 — Test plan housekeeping

- **QA agent must update `Project/06_roadmap/test_report_latest.md`** after each pass. Format: per-test ID, status, evidence link (screenshot path), notes.
- **Status field in this doc** is updated by the orchestrator (not the QA agent) when a sprint slice merges to main.
- **Adding new tests:** allocate next free ID in the relevant section. Don't renumber existing IDs.
