# Lumen v1 QA Report

- **Run at:** 2026-04-27T11:35:00Z
- **Branch:** worktree-feat+preflight-scaffold
- **Sim:** iPhone 17 Pro (UDID 538249D5-D6E0-4FB6-AD33-46499F8AC350)
- **Scope:** v1 simulator golden path
- **Summary:** 6 pass · 3 FAIL · 2 minor · 6 blocked-by-upstream · device-only/manual SKIPPED

## PASS

| Test ID | Notes |
|---|---|
| S0.LAUNCH.01 | App launches cleanly into Onboarding Welcome. No crash. |
| S1.OB.03 Permissions | "On a besoin de deux choses." renders with 2 icon cards (bell + speaker), italic footer "On ne t'envoie rien d'autre. Promis." Eyebrow "03 / 04" present. |
| S1.OB.04 First alarm | Title "À quelle heure veux-tu commencer ?", wheel time picker showing 07:00, subtext "Tu pourras changer plus tard.", CTA "Programmer". Eyebrow "04 / 04". |
| S1.OB.05 Onboarding completion flag | Killed app after onboarding, relaunched — landed on Dashboard, NOT onboarding. Flag persists. |
| S1.AL.01 Alarm list shows scheduled alarm | Réveil tab shows the 07:00 alarm scheduled by onboarding, "Tous les jours" recurrence label, toggle on (accent). The onboarding `scheduleFirstAlarm` use case persisted correctly. |
| S2.ST.01 / S2.ST.03 Settings sections | Réglages tab renders with sections: Rituel (timer duration 60s), Voix (toggle, voice picker, speed segmented, privacy notice), Intelligence Artificielle (WaterfallStatusList showing OpenAI/Anthropic = "CLÉ MANQUANTE", Apple Intelligence = "DISPONIBLE"). |

## FAIL

| Test ID | Expected | Actual | Evidence |
|---|---|---|---|
| **F1 — S1.OB.01 / S1.OB.02 KineticText broken** | "Quelques minutes à toi." reveals word-by-word with proper spacing, words do not break mid-word | Words break mid-word ("Quel\|ques", "min\|utes") and have no spaces between them on the Pitch screen ("Cinqminutes.", "Pasplus.") | `/tmp/lumen-qa-screenshots/A1-welcome.png`, `/tmp/lumen-qa-screenshots/A2-pitch.png` |
| **F2 — S1.AL.02 AlarmEdit empty** | Tapping "+" opens AlarmEdit sheet with: time picker, recurrence segmented control, sound picker, active toggle, "Enregistrer" CTA | Sheet opens but body shows only the title "Nouvelle alarme" — every form field is missing or rendered invisibly | `/tmp/lumen-qa-screenshots/C2-alarm-edit.png` |
| **F3 — S2.DB.02 Dashboard state logic** | After onboarding (alarm scheduled, no ritual completed today), Dashboard should show **Idle** state: banner "Tu n'as pas encore fait ton rituel." + secondary CTA "Démarrer" + 6 grayed cards. | Dashboard shows **Empty** state ("Ton premier matin t'attend." + "Programmer mon réveil" CTA), as if no alarm exists — yet the alarm IS persisted (visible in Réveil tab). The state check is using `hasAnyRitual` instead of `hasAlarms` to gate the Empty branch. | `/tmp/lumen-qa-screenshots/B1-dashboard-idle.png` |

## MINOR (not blocking, fix opportunistically)

- **M1** Voice "Mode vocal par défaut" toggle is OFF on first launch — spec says default is `true`. Likely the `SettingsViewModel` is reading from UserDefaults without writing a default value.
- **M2** Voice picker defaults to "Samantha (EN)" — for an FR-first app, the default voice should be a French neural voice (e.g., "Audrey" or "Thomas") when the locale is FR.

## BLOCKED (upstream FAILs)

| Test ID | Blocked by |
|---|---|
| S2.T.01 / S2.T.02 Timer breathing | F3 — Dashboard Empty state has no "Démarrer" CTA → can't enter the ritual flow. |
| S2.Q1.01 Q1 Mood (V4 sun rising) | F3 |
| S2.Q2.01 Q2 Priority chips | F3 |
| S2.Q3.01 / S2.Q4.01 Voice questionnaire | F3 |
| S2.SY.02 Synthesis queued (offline) | F3 |
| S1.AL.04 Swipe-delete alarm | F2 — verified List shows alarm but didn't exercise swipe (would still likely work; deferred until F2 is fixed and I can re-enter via "+"). |

## SKIPPED (out of current scope)

- **Device-only:** D1.BG.* alarm reliability (real iPhone), S2.Q3.02/Q4 voice on real mic, S2.SY.06/07 TTS audio routing, M3.HP.* haptics — require a real iPhone.
- **Manual:** M3.A11.* VoiceOver/Dynamic Type/Reduce Motion, M3.VF.* visual fidelity vs maquettes, M3.HP.* haptics — require human judgment.
- **API-key-dependent:** S2.SY.01 cloud success path — needs real `OPENAI_API_KEY`/`ANTHROPIC_API_KEY` in `Secrets.xcconfig`. The waterfall correctly reports "CLÉ MANQUANTE" in Settings.

## Notes for the fix agent

### F1 — KineticText word layout

**File:** `Apple/lumen/Shared/DesignSystem/Components/KineticText.swift`

**Root cause:** the component renders each word as a separate `Text` view inside an `HStack` (or similar layout) without inter-word spaces, AND when the line is too long, the HStack wraps but each `Text` is treated as an indivisible flex item that can break mid-character. Two distinct symptoms:
- On Welcome (long line): "Quelques" → "Quel" + "ques" stacked, "minutes" → "min" + "utes" stacked.
- On Pitch (short line): "Cinq" + "minutes." rendered with no space → "Cinqminutes."

**Fix approach:** Replace the per-word View layout with `Text` concatenation. Build a single `Text` value as `Text(words.joined(separator: " "))` and animate per-word opacity using an `AttributedString` with custom run attributes that drive `.foregroundColor(.clear)` on un-revealed ranges, OR (simpler) keep individual words but lay them out using `FlowLayout` (custom Layout) with a real space character between words and `.fixedSize(horizontal: true, vertical: false)` per word so they never break mid-word.

**Simplest fix:** rewrite as a single `Text` with `Animation`-controlled opacity per character/word range using `AttributedString.attributedSubstring(from:)` ranges. Or render `Text(words[..<revealedCount].joined(separator: " "))` updated over time — the trailing words simply pop in but the layout never breaks word integrity.

Recommended: `Text(visibleString)` where `visibleString = words.prefix(visibleCount).joined(separator: " ")`, animated by appending words one by one with a Task. This trades word-by-word fade-in for sequential reveal but preserves layout correctness.

### F2 — AlarmEdit form not rendering

**File:** `Apple/lumen/Features/Alarm/AlarmEditView.swift`

**Root cause:** body returns only the title text; the `Form` (or VStack) with form fields is missing or wrapped in a conditional that's `false` for new-alarm mode.

**Fix:** make sure the full Form body is rendered for both new-alarm and edit-existing modes. Verify the view's body contains: `DatePicker(.hourAndMinute, .wheel)`, segmented recurrence, sound picker, active Toggle, "Enregistrer" PrimaryCTA, and (edit mode only) a "Supprimer" GhostCTA at the bottom.

### F3 — Dashboard state should be Idle, not Empty

**Files:** 
- `Apple/lumen/Features/Dashboard/DashboardHomeViewModel.swift`
- `Apple/lumen/Features/Dashboard/DashboardHomeView.swift`

**Root cause:** the Empty/Idle/Post-rituel state machine is gating Empty on `!hasAnyRitual` (no ritual ever completed). Per spec it should gate on `!hasAnyAlarm` (no alarm scheduled yet). Once at least one alarm exists, even without any completed ritual, the dashboard should be Idle — not Empty.

**Fix:** load alarms from the AlarmRepository in `DashboardHomeViewModel.load()`. Set `hasAnyAlarm = !alarms.isEmpty`. Then the view picks Empty when `!hasAnyAlarm`, Idle when `hasAnyAlarm && !hasRitualToday`, Post-rituel when `hasRitualToday`. The Idle branch must include a "Démarrer" CTA that triggers the ritual flow (set `RootView.RitualFlowState = .timer`).

### M1 — Voice default toggle

**File:** `Apple/lumen/Features/Settings/SettingsViewModel.swift`

**Fix:** when reading the UserDefaults key `"lumen.settings.voiceDefault"`, fall back to `true` if the key is absent. (`UserDefaults.standard.object(forKey:) ?? true` pattern.)

### M2 — Voice picker FR default

**File:** `Apple/lumen/Features/Settings/SettingsViewModel.swift`

**Fix:** when no voice id has been persisted, pick the first voice from `availableVoices()` whose `language` starts with `Locale.current.language.languageCode?.identifier ?? "fr"` (preferring `fr-FR`). Fall back to the first available if none match.

## Evidence files

- `/tmp/lumen-qa-screenshots/A1-welcome.png` — F1 evidence (kinetic word breaks)
- `/tmp/lumen-qa-screenshots/A2-pitch.png` — F1 evidence (no word spacing)
- `/tmp/lumen-qa-screenshots/A3-permissions.png` — PASS
- `/tmp/lumen-qa-screenshots/A4-firstalarm.png` — PASS
- `/tmp/lumen-qa-screenshots/B1-dashboard-idle.png` — F3 evidence (Empty state instead of Idle)
- `/tmp/lumen-qa-screenshots/C1-alarms-tab.png` — PASS (alarm persisted)
- `/tmp/lumen-qa-screenshots/C2-alarm-edit.png` — F2 evidence (empty form)
- `/tmp/lumen-qa-screenshots/E1-settings.png` — PASS (Settings sections render, WaterfallStatusList correct)
