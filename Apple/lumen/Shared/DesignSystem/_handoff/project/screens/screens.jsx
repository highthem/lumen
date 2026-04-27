// Lumen — All screens, dark + light variants
// Each screen is a function returning JSX inside a <div className="phone dark|lite">

const StatusBar = ({ time = '7:14' }) => (
  <>
    <div className="island"></div>
    <div className="sb">
      <span>{time}</span>
      <div className="icons">
        <svg width="18" height="11" viewBox="0 0 18 11" fill="currentColor"><rect x="0" y="7" width="3" height="4" rx="0.6"/><rect x="5" y="5" width="3" height="6" rx="0.6"/><rect x="10" y="2" width="3" height="9" rx="0.6"/><rect x="15" y="0" width="3" height="11" rx="0.6"/></svg>
        <svg width="16" height="11" viewBox="0 0 16 11" fill="currentColor"><path d="M8 2C10 2 11.8 2.8 13 4l1-1C12.5 1.4 10.4 0.5 8 0.5S3.5 1.4 2 3l1 1C4.2 2.8 6 2 8 2z"/><path d="M8 5.4c1.2 0 2.3 0.4 3.2 1.2l1-1C11 4.6 9.6 4 8 4s-3 0.6-4.2 1.6l1 1C5.7 5.8 6.8 5.4 8 5.4z"/><circle cx="8" cy="9" r="1.4"/></svg>
        <svg width="26" height="12" viewBox="0 0 26 12"><rect x="0.5" y="0.5" width="22" height="11" rx="3" stroke="currentColor" strokeOpacity="0.4" fill="none"/><rect x="2" y="2" width="19" height="8" rx="1.5" fill="currentColor"/><path d="M24 4v4c0.7-0.3 1.3-1 1.3-2s-0.6-1.7-1.3-2z" fill="currentColor" opacity="0.5"/></svg>
      </div>
    </div>
  </>
);

const HomeIndicator = () => <div className="home"></div>;

// ─────────────────────────────────────────────────────────────
// 01 — Onboarding · Welcome (kinetic typography "living")
// ─────────────────────────────────────────────────────────────
const KineticTitle = ({ words, dur = 900, stagger = 110 }) => (
  <span className="kinetic" style={{ fontSize: 56, fontWeight: 500 }}>
    {words.map((w, i) => (
      <React.Fragment key={i}>
        <span className="word" style={{ animationDelay: `${i * stagger}ms` }}>{w}</span>
        {i < words.length - 1 && <span> </span>}
      </React.Fragment>
    ))}
  </span>
);

function OnboardingWelcome({ mode = 'dark' }) {
  return (
    <div className={`phone ${mode}`}>
      <div className="scr glow-top">
        <StatusBar />
        <div className="content" style={{ justifyContent: 'space-between', paddingTop: 60 }}>
          <div>
            <div className="eyebrow">Lumen</div>
            <div style={{ marginTop: 80 }}>
              <KineticTitle words={["Quelques", "minutes", "à", "toi."]} />
            </div>
            <div className="h-sub serif" style={{ fontSize: 19, marginTop: 28, fontStyle: 'italic', opacity: .85 }}>
              Un rituel matinal pour commencer avec intention.
            </div>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <button className="cta primary">Commencer</button>
            <button className="cta ghost" style={{ alignSelf: 'center' }}>J'ai déjà un compte</button>
          </div>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 02 — Onboarding · Pitch (kinetic, 5 minutes)
// ─────────────────────────────────────────────────────────────
function OnboardingPitch({ mode = 'dark' }) {
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ justifyContent: 'space-between', paddingTop: 80 }}>
          <div>
            <div style={{ display: 'flex', gap: 4, marginBottom: 64 }}>
              <i style={{ width: 18, height: 2, background: 'currentColor', opacity: .25, borderRadius: 1 }}></i>
              <i style={{ width: 18, height: 2, background: 'currentColor', opacity: 1, borderRadius: 1 }}></i>
              <i style={{ width: 18, height: 2, background: 'currentColor', opacity: .25, borderRadius: 1 }}></i>
              <i style={{ width: 18, height: 2, background: 'currentColor', opacity: .25, borderRadius: 1 }}></i>
            </div>
            <div className="serif" style={{ fontSize: 48, lineHeight: 1.1, letterSpacing: '-0.02em', fontWeight: 500 }}>
              <span className="word" style={{ display: 'inline-block', animationDelay: '0ms' }}>Cinq</span>{' '}
              <span className="word" style={{ display: 'inline-block', animationDelay: '100ms' }}>minutes.</span><br/>
              <span className="word serif" style={{ display: 'inline-block', animationDelay: '600ms', fontStyle: 'italic', opacity: .55 }}>Pas plus.</span>
            </div>
            <div className="h-sub" style={{ fontSize: 17, marginTop: 32 }}>
              Pour cadrer ta journée avant qu'elle ne te cadre.
            </div>
          </div>
          <button className="cta primary">Suivant</button>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 03 — Onboarding · Permissions
// ─────────────────────────────────────────────────────────────
function OnboardingPermissions({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ paddingTop: 80, gap: 32 }}>
          <div style={{ display: 'flex', gap: 4 }}>
            <i style={{ width: 18, height: 2, background: 'currentColor', opacity: .25, borderRadius: 1 }}></i>
            <i style={{ width: 18, height: 2, background: 'currentColor', opacity: .25, borderRadius: 1 }}></i>
            <i style={{ width: 18, height: 2, background: 'currentColor', opacity: 1, borderRadius: 1 }}></i>
            <i style={{ width: 18, height: 2, background: 'currentColor', opacity: .25, borderRadius: 1 }}></i>
          </div>
          <div>
            <div className="eyebrow">03 / 04</div>
            <div className="h-title">On a besoin<br/>de deux choses.</div>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14, marginTop: 12 }}>
            <div className="card" style={{ flexDirection: 'row', alignItems: 'center', gap: 16, padding: 18 }}>
              <div style={{ width: 40, height: 40, borderRadius: 12, background: isDark ? 'var(--d-bg3)' : 'var(--l-bg3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <svg width="18" height="20" viewBox="0 0 18 20" fill="none" stroke="currentColor" strokeWidth="1.4"><path d="M9 1v2M3 16h12M9 4a6 6 0 016 6v3l1 2H2l1-2v-3a6 6 0 016-6zM7 18a2 2 0 004 0"/></svg>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 500 }}>Te notifier à l'heure choisie</div>
                <div style={{ fontSize: 12, color: isDark ? 'var(--d-ink2)' : 'var(--l-ink2)', marginTop: 2 }}>Notifications</div>
              </div>
              <span className="chip sel" style={{ fontSize: 12 }}>Activé</span>
            </div>
            <div className="card" style={{ flexDirection: 'row', alignItems: 'center', gap: 16, padding: 18 }}>
              <div style={{ width: 40, height: 40, borderRadius: 12, background: isDark ? 'var(--d-bg3)' : 'var(--l-bg3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.4"><path d="M11 4l-4 3H4v6h3l4 3V4zM14 7c1 1 1 5 0 6M16 5c2 2 2 8 0 10"/></svg>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 500 }}>Jouer un son doux</div>
                <div style={{ fontSize: 12, color: isDark ? 'var(--d-ink2)' : 'var(--l-ink2)', marginTop: 2 }}>Audio en arrière-plan</div>
              </div>
              <span className="chip" style={{ fontSize: 12 }}>Demander</span>
            </div>
          </div>
          <div className="h-sub serif" style={{ fontStyle: 'italic', fontSize: 15 }}>On ne t'envoie rien d'autre. Promis.</div>
          <div style={{ flex: 1 }}></div>
          <button className="cta primary">Continuer</button>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 04 — Onboarding · Première alarme (time picker)
// ─────────────────────────────────────────────────────────────
function OnboardingAlarm({ mode = 'dark' }) {
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ paddingTop: 60 }}>
          <div style={{ display: 'flex', gap: 4, marginBottom: 24 }}>
            <i style={{ width: 18, height: 2, background: 'currentColor', opacity: .25, borderRadius: 1 }}></i>
            <i style={{ width: 18, height: 2, background: 'currentColor', opacity: .25, borderRadius: 1 }}></i>
            <i style={{ width: 18, height: 2, background: 'currentColor', opacity: .25, borderRadius: 1 }}></i>
            <i style={{ width: 18, height: 2, background: 'currentColor', opacity: 1, borderRadius: 1 }}></i>
          </div>
          <div className="eyebrow">04 / 04</div>
          <div className="h-title">À quelle heure<br/>veux-tu commencer ?</div>

          <div className="wheel" style={{ marginTop: 24 }}>
            <div className="col">
              <span>05</span><span>06</span><span className="sel">07</span><span>08</span><span>09</span>
            </div>
            <span className="colon">:</span>
            <div className="col">
              <span>:00</span><span>:15</span><span className="sel">:00</span><span>:15</span><span>:30</span>
            </div>
          </div>

          <div className="h-sub" style={{ textAlign: 'center', alignSelf: 'center' }}>
            Tu pourras changer plus tard.
          </div>
          <div style={{ flex: 1 }}></div>
          <button className="cta primary">Programmer</button>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 05a — Dashboard · Empty state (premier lancement)
// ─────────────────────────────────────────────────────────────
function DashboardEmpty({ mode = 'dark' }) {
  return (
    <div className={`phone ${mode}`}>
      <div className="scr glow-top">
        <StatusBar />
        <div className="content" style={{ paddingTop: 32, justifyContent: 'space-between' }}>
          <div className="eyebrow">Lumen</div>
          <div style={{ textAlign: 'left' }}>
            <div className="serif" style={{ fontSize: 40, lineHeight: 1.1, letterSpacing: '-0.015em', fontWeight: 500 }}>
              Ton premier matin<br/>t'attend.
            </div>
            <div className="h-sub" style={{ marginTop: 20 }}>
              Programme une alarme.<br/>On s'occupe du reste.
            </div>
          </div>
          <div style={{ marginBottom: 24 }}>
            <button className="cta primary">Programmer mon réveil</button>
          </div>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 05b — Dashboard · Idle (rituel pas encore fait)
// ─────────────────────────────────────────────────────────────
function DashboardIdle({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr glow-top">
        <StatusBar />
        <div className="content" style={{ paddingTop: 24, gap: 20, overflow: 'auto' }}>
          <div>
            <div className="eyebrow">Lundi 11 mai</div>
            <div className="serif" style={{ fontSize: 32, fontWeight: 500, letterSpacing: '-0.01em', marginTop: 8 }}>Bonjour.</div>
          </div>

          <div style={{ borderRadius: 24, padding: 22, background: isDark ? 'linear-gradient(180deg, rgba(232,195,158,0.12), rgba(232,195,158,0.04))' : 'linear-gradient(180deg, rgba(166,124,82,0.10), rgba(166,124,82,0.03))', border: `1px solid ${isDark ? 'var(--d-line)' : 'var(--l-line)'}` }}>
            <div className="serif" style={{ fontSize: 22, lineHeight: 1.3, letterSpacing: '-0.005em' }}>
              Tu n'as pas encore<br/>fait ton rituel.
            </div>
            <div style={{ fontSize: 14, marginTop: 8, opacity: .7 }}>5 minutes pour démarrer.</div>
            <button className="cta primary" style={{ marginTop: 16 }}>Démarrer</button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, opacity: .5 }}>
            <div className="card"><div className="ic">Énergie</div><div className="v">—</div></div>
            <div className="card"><div className="ic">Intention</div><div className="v">—</div></div>
            <div className="card"><div className="ic">Corps</div><div className="v">—</div></div>
            <div className="card"><div className="ic">Relations</div><div className="v">—</div></div>
            <div className="card"><div className="ic">Travail</div><div className="v">—</div></div>
            <div className="card"><div className="ic">Gratitude</div><div className="v">—</div></div>
          </div>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 05c — Dashboard · Post-rituel (filled)
// ─────────────────────────────────────────────────────────────
function DashboardPost({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr glow-top">
        <StatusBar />
        <div className="content" style={{ paddingTop: 24, gap: 18, overflow: 'auto' }}>
          <div>
            <div className="eyebrow">Lundi 11 mai</div>
            <div className="serif" style={{ fontSize: 32, fontWeight: 500, letterSpacing: '-0.01em', marginTop: 8 }}>Aujourd'hui.</div>
          </div>

          <div style={{ borderRadius: 24, padding: 24, background: isDark ? 'var(--d-bg2)' : 'var(--l-bg2)', boxShadow: isDark ? 'none' : '0 4px 16px rgba(0,0,0,.06)' }}>
            <div className="eyebrow">Intention</div>
            <div className="serif" style={{ fontSize: 36, lineHeight: 1.1, fontWeight: 500, letterSpacing: '-0.02em', marginTop: 12, fontStyle: 'italic' }}>présence</div>
            <div style={{ fontSize: 14, marginTop: 14, lineHeight: 1.5, opacity: .8 }}>Écouter Karim sans projeter. Marcher 20 min sans téléphone.</div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div className="card"><div className="ic">Énergie</div><div className="v">Posée</div><div className="h">un peu fatiguée</div></div>
            <div className="card"><div className="ic">Corps</div><div className="v">6 h</div><div className="h">peu hydratée</div></div>
            <div className="card"><div className="ic">Relations</div><div className="v">Karim</div><div className="h">écouter</div></div>
            <div className="card"><div className="ic">Travail</div><div className="v">Project K.</div><div className="h">spec audio</div></div>
            <div className="card" style={{ gridColumn: 'span 2' }}><div className="ic">Gratitude</div><div className="v serif" style={{ fontStyle: 'italic' }}>Le silence avant que les enfants se lèvent.</div></div>
          </div>
        </div>
        {/* Floating Ask button */}
        <div style={{ position: 'absolute', right: 24, bottom: 36, width: 56, height: 56, borderRadius: 999, background: isDark ? 'var(--d-accent)' : 'var(--l-accent)', color: isDark ? '#1F1A14' : 'var(--l-bg)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 8px 24px rgba(0,0,0,0.25)' }}>
          <span className="serif" style={{ fontSize: 22, fontWeight: 500, fontStyle: 'italic' }}>?</span>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 06 — Création / édition alarme
// ─────────────────────────────────────────────────────────────
function AlarmEdit({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ paddingTop: 24, gap: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: 15, opacity: .7 }}>← Retour</span>
            <span style={{ fontSize: 15, fontWeight: 500 }}>Modifier alarme</span>
            <span style={{ fontSize: 15, color: isDark ? 'var(--d-accent)' : 'var(--l-accent)', fontWeight: 500 }}>OK</span>
          </div>

          <div className="wheel" style={{ marginTop: 8 }}>
            <div className="col">
              <span>05</span><span>06</span><span className="sel">07</span><span>08</span><span>09</span>
            </div>
            <span className="colon">:</span>
            <div className="col">
              <span>:00</span><span>:15</span><span className="sel">:00</span><span>:15</span><span>:30</span>
            </div>
          </div>

          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>Récurrence</div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              <span className="chip">Jamais</span>
              <span className="chip sel">Jours de semaine</span>
              <span className="chip">Tous les jours</span>
              <span className="chip">Personnalisé</span>
            </div>
          </div>

          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>Son</div>
            <div className="group">
              <div className="row"><span>Aube</span><span style={{ color: isDark ? 'var(--d-accent)' : 'var(--l-accent)' }}>●</span></div>
              <div className="row"><span>Verre d'eau</span><span style={{ opacity: .3 }}>○</span></div>
              <div className="row"><span>Cordes</span><span style={{ opacity: .3 }}>○</span></div>
            </div>
          </div>

          <div className="group">
            <div className="row"><span>Activée</span><span style={{ width: 44, height: 26, borderRadius: 999, background: isDark ? 'var(--d-accent)' : 'var(--l-accent)', position: 'relative' }}><i style={{ position: 'absolute', right: 2, top: 2, width: 22, height: 22, borderRadius: 999, background: '#fff' }}></i></span></div>
          </div>
          <div style={{ flex: 1 }}></div>
          <div style={{ textAlign: 'center', fontSize: 14, color: isDark ? 'var(--d-error)' : 'var(--l-accent)', opacity: .8 }}>Supprimer cette alarme</div>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 07 — Alarme sonne (foreground)
// ─────────────────────────────────────────────────────────────
function AlarmRinging({ mode = 'dark' }) {
  return (
    <div className={`phone ${mode}`}>
      <div className="scr glow-top" style={{ position: 'relative' }}>
        <StatusBar />
        <div className="content" style={{ paddingTop: 0, justifyContent: 'space-between' }}>
          <div style={{ paddingTop: 60, textAlign: 'center' }}>
            <div className="eyebrow">Lundi 11 mai</div>
            <div className="serif" style={{ fontSize: 96, lineHeight: 1, fontWeight: 400, letterSpacing: '-0.03em', marginTop: 16 }}>7:00</div>
          </div>
          <div className="alarm-pulse" style={{ color: 'currentColor' }}></div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <button className="cta secondary">Snooze 5 min</button>
            <button className="cta primary">Silence</button>
          </div>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 08 — Timer de présence (signature breathing)
// ─────────────────────────────────────────────────────────────
function PresenceTimer({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ paddingTop: 36, justifyContent: 'space-between' }}>
          <div>
            <div className="eyebrow" style={{ textAlign: 'center' }}>Présence · 60 secondes</div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 48, flex: 1, justifyContent: 'center' }}>
            <div className="serif" style={{ fontSize: 26, lineHeight: 1.35, letterSpacing: '-0.01em', textAlign: 'center', maxWidth: 280, fontWeight: 400, textWrap: 'balance' }}>
              Le matin a ses propres pensées.<br/><em style={{ opacity: .65 }}>Laisse-les venir.</em>
            </div>
            <div className="breath" style={{ color: isDark ? 'var(--d-accent)' : 'var(--l-accent)' }}></div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button className="cta ghost">Passer →</button>
          </div>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 09 — Q1 Ressenti
// ─────────────────────────────────────────────────────────────
function Q1Mood({ mode = 'dark' }) {
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ paddingTop: 28, gap: 24 }}>
          <div className="prog"><i className="cur"></i><i></i><i></i><i></i></div>
          <div>
            <div className="eyebrow">01 / 04 · Ressenti</div>
            <div className="h-title">Comment tu<br/>te sens ?</div>
          </div>
          <div style={{ flex: 1 }}></div>
          <div className="mood">
            <div className="e">😔</div>
            <div className="e">😐</div>
            <div className="e sel">🙂</div>
            <div className="e">☺️</div>
            <div className="e">✨</div>
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', justifyContent: 'center', marginTop: 8 }}>
            <span className="chip">fatigué</span>
            <span className="chip sel">posé</span>
            <span className="chip">anxieux</span>
            <span className="chip">curieux</span>
          </div>
          <div style={{ flex: 1 }}></div>
          <button className="cta primary">Suivant</button>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 10 — Q2 Priorité
// ─────────────────────────────────────────────────────────────
function Q2Priority({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ paddingTop: 28, gap: 24 }}>
          <div className="prog"><i className="done"></i><i className="cur"></i><i></i><i></i></div>
          <div>
            <div className="eyebrow">02 / 04 · Priorité</div>
            <div className="h-title">Qu'est-ce qui<br/>compte aujourd'hui ?</div>
          </div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <span className="chip">Travail</span>
            <span className="chip sel">Corps</span>
            <span className="chip">Relations</span>
            <span className="chip">Énergie</span>
            <span className="chip">Argent</span>
            <span className="chip">Création</span>
          </div>
          <div style={{ marginTop: 8 }}>
            <div className="eyebrow" style={{ marginBottom: 8 }}>Précise si tu veux</div>
            <textarea placeholder="optionnel" rows={3} style={{ width: '100%', appearance: 'none', borderRadius: 14, padding: '14px 16px', fontSize: 15, fontFamily: 'inherit', resize: 'none', background: isDark ? 'var(--d-bg2)' : 'var(--l-bg2)', color: 'inherit', border: `1px solid ${isDark ? 'var(--d-line)' : 'var(--l-line)'}`, outline: 0 }}>marcher 20 min sans téléphone</textarea>
          </div>
          <div style={{ flex: 1 }}></div>
          <button className="cta primary">Suivant</button>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 11 — Q3 Gratitude
// ─────────────────────────────────────────────────────────────
function Q3Gratitude({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ paddingTop: 28, gap: 24 }}>
          <div className="prog"><i className="done"></i><i className="done"></i><i className="cur"></i><i></i></div>
          <div>
            <div className="eyebrow">03 / 04 · Gratitude</div>
            <div className="h-title">Une gratitude ?</div>
          </div>
          <div>
            <textarea placeholder="Un moment, une personne, une chose…" rows={4} style={{ width: '100%', appearance: 'none', borderRadius: 14, padding: '16px 18px', fontSize: 17, fontFamily: 'Charter, serif', resize: 'none', background: isDark ? 'var(--d-bg2)' : 'var(--l-bg2)', color: 'inherit', border: `1.5px solid ${isDark ? 'var(--d-accent)' : 'var(--l-accent)'}`, outline: 0, lineHeight: 1.4 }} defaultValue="Le silence avant que les enfants se lèvent."></textarea>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 12, opacity: .55 }}>
              <span>Optionnel</span>
              <span>56 / 140</span>
            </div>
          </div>
          <div style={{ flex: 1 }}></div>
          <div style={{ display: 'flex', gap: 12 }}>
            <button className="cta ghost">Passer</button>
            <button className="cta primary" style={{ flex: 1 }}>Suivant</button>
          </div>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 12 — Q4 Intention
// ─────────────────────────────────────────────────────────────
function Q4Intention({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ paddingTop: 28, gap: 24 }}>
          <div className="prog"><i className="done"></i><i className="done"></i><i className="done"></i><i className="cur"></i></div>
          <div>
            <div className="eyebrow">04 / 04 · Intention</div>
            <div className="h-title">Ton intention<br/>en un mot.</div>
          </div>
          <div style={{ flex: 1 }}></div>
          <div style={{ textAlign: 'center', position: 'relative' }}>
            <input defaultValue="présence" placeholder="focus, patience, présence…" style={{ width: '100%', appearance: 'none', border: 0, borderBottom: `1px solid ${isDark ? 'var(--d-accent)' : 'var(--l-accent)'}`, background: 'transparent', textAlign: 'center', fontFamily: 'Charter, serif', fontSize: 56, color: isDark ? 'var(--d-accent)' : 'var(--l-accent)', fontStyle: 'italic', fontWeight: 400, padding: '12px 0', outline: 0, letterSpacing: '-0.02em' }} />
            <div style={{ fontSize: 12, opacity: .55, marginTop: 12 }}>8 / 30</div>
          </div>
          <div style={{ flex: 1 }}></div>
          <button className="cta primary">Voir ma synthèse</button>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 13 — Synthèse IA (cloud)
// ─────────────────────────────────────────────────────────────
function Synthesis({ mode = 'dark', offline = false }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr glow-top">
        <StatusBar />
        <div className="content" style={{ paddingTop: 28, overflow: 'auto', gap: 24 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div className="eyebrow">Ton matin</div>
            {offline && <span className="chip" style={{ fontSize: 11, padding: '4px 10px' }}>Hors-ligne</span>}
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
            <div>
              <div className="eyebrow" style={{ marginBottom: 8 }}>Intention</div>
              <div className="serif" style={{ fontSize: 42, lineHeight: 1.1, letterSpacing: '-0.02em', fontWeight: 500, fontStyle: 'italic', color: isDark ? 'var(--d-accent)' : 'var(--l-accent)' }}>présence</div>
            </div>

            <div>
              <div className="eyebrow" style={{ marginBottom: 8 }}>Focus</div>
              <div className="serif" style={{ fontSize: 19, lineHeight: 1.45, letterSpacing: '-0.005em' }}>
                Écoute Karim sans préparer ta réponse.<br/>
                Marche vingt minutes, le téléphone reste à la maison.
              </div>
            </div>

            <div>
              <div className="eyebrow" style={{ marginBottom: 8 }}>Rappel</div>
              <div className="serif" style={{ fontSize: 17, lineHeight: 1.5, fontStyle: 'italic', opacity: .75 }}>
                {offline
                  ? "Ton calme du matin n'a pas besoin d'un serveur. Reviens à toi."
                  : "La fatigue passe, la précipitation s'installe. Tu choisis laquelle des deux nourrir."}
              </div>
            </div>
          </div>

          <div style={{ flex: 1, minHeight: 24 }}></div>

          <div style={{ display: 'flex', gap: 12, flexDirection: 'column' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 12, opacity: .55 }}>
              <span>{offline ? 'Mode hors-ligne · template ressenti' : 'Régénérations · 2 / 3 restantes'}</span>
            </div>
            {!offline && <button className="cta secondary">Régénérer</button>}
            <button className="cta primary">Continuer vers le dashboard</button>
          </div>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 14 — Dashboard détail catégorie
// ─────────────────────────────────────────────────────────────
function CategoryDetail({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  const days = [
    { d: 'Dim', v: 'précipité' },
    { d: 'Sam', v: 'posé' },
    { d: 'Ven', v: 'fragile' },
    { d: 'Jeu', v: 'en forme' },
    { d: 'Mer', v: 'fragile' },
    { d: 'Mar', v: 'posé' },
    { d: 'Lun', v: 'curieux' },
  ];
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ paddingTop: 24, gap: 24, overflow: 'auto' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: 15, opacity: .7 }}>← Aujourd'hui</span>
            <span style={{ fontSize: 15, color: isDark ? 'var(--d-accent)' : 'var(--l-accent)' }}>Modifier</span>
          </div>

          <div>
            <div className="eyebrow">Énergie</div>
            <div className="serif" style={{ fontSize: 34, fontWeight: 500, letterSpacing: '-0.015em', marginTop: 8 }}>Posée.</div>
            <div className="serif" style={{ fontSize: 19, fontStyle: 'italic', opacity: .7, marginTop: 6 }}>Un peu fatiguée, mais ouverte.</div>
          </div>

          <div>
            <div className="eyebrow" style={{ marginBottom: 12 }}>Sept derniers jours</div>
            <div className="list">
              {days.map((d, i) => (
                <div className="row" key={i}>
                  <span style={{ fontSize: 13, opacity: .55, width: 40 }}>{d.d}</span>
                  <span className="serif" style={{ fontSize: 17, fontStyle: 'italic', flex: 1, marginLeft: 8 }}>{d.v}</span>
                  <span style={{ fontSize: 12, opacity: .4 }}>{i === 0 ? 'aujourd\'hui' : '07:0' + (4 - i + 1).toString().slice(0, 1)}</span>
                </div>
              ))}
            </div>
          </div>
          <div style={{ flex: 1 }}></div>
          <button className="cta secondary">Ask Lumen sur cette catégorie</button>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 15 — Ask Lumen modal (half-sheet)
// ─────────────────────────────────────────────────────────────
function AskLumen({ mode = 'dark' }) {
  return (
    <div className={`phone ${mode}`}>
      <div className="scr glow-top" style={{ position: 'relative' }}>
        <StatusBar />
        <div className="content" style={{ paddingTop: 24, gap: 18, opacity: .55, filter: 'blur(1px)' }}>
          <div className="eyebrow">Lundi 11 mai</div>
          <div className="serif" style={{ fontSize: 32, fontWeight: 500, letterSpacing: '-0.01em' }}>Aujourd'hui.</div>
          <div style={{ borderRadius: 24, padding: 24, background: 'currentColor', opacity: .08, height: 100 }}></div>
        </div>
        <div className="sheet" style={{ height: 480 }}>
          <div className="grab"></div>
          <div className="eyebrow">Ask Lumen</div>
          <div className="chip" style={{ alignSelf: 'flex-start' }}>Catégorie · Relations</div>
          <div className="serif" style={{ fontSize: 22, lineHeight: 1.3, letterSpacing: '-0.005em', fontWeight: 500 }}>
            Comment je peux écouter Karim sans projeter ?
          </div>
          <div className="serif" style={{ fontSize: 17, lineHeight: 1.5, opacity: .85, fontStyle: 'italic' }}>
            Pose une question, ne propose pas de solution. La présence d'écoute compte plus que la justesse de la réponse — surtout le matin.
          </div>
          <div style={{ display: 'flex', gap: 4, alignItems: 'center', marginTop: 4 }}>
            <span style={{ width: 4, height: 4, borderRadius: 999, background: 'currentColor', opacity: .5, animation: 'pulse 1.2s ease-in-out infinite' }}></span>
            <span style={{ fontSize: 12, opacity: .5 }}>Lumen écrit…</span>
          </div>
          <div style={{ flex: 1 }}></div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, opacity: .55 }}>
            <span>2 / 3 questions restantes</span>
            <span>Fermer</span>
          </div>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 16 — Settings
// ─────────────────────────────────────────────────────────────
function Settings({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBar />
        <div className="content" style={{ paddingTop: 24, gap: 20, overflow: 'auto' }}>
          <div className="eyebrow">Réglages</div>
          <div className="serif" style={{ fontSize: 32, fontWeight: 500, letterSpacing: '-0.01em' }}>Tien.</div>

          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>Rituel</div>
            <div className="group">
              <div className="row"><span>Heure d'alarme</span><span style={{ opacity: .7 }}>07:00</span></div>
              <div className="row"><span>Son</span><span style={{ opacity: .7 }}>Aube</span></div>
              <div className="row"><span>Durée du timer</span><span style={{ opacity: .7 }}>60 s</span></div>
            </div>
          </div>

          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>Apparence</div>
            <div className="group">
              <div className="row"><span>Thème</span><span style={{ opacity: .7 }}>Système</span></div>
            </div>
          </div>

          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>IA & confidentialité</div>
            <div className="group">
              <div className="row"><span>Questions par jour</span><span style={{ opacity: .7 }}>3 / 3</span></div>
              <div className="row"><span>Régénérations synthèse</span><span style={{ opacity: .7 }}>3 / 3</span></div>
              <div className="row"><span>Provider actuel</span><span style={{ opacity: .7 }}>Anthropic</span></div>
              <div className="row"><span>Exporter mes données (JSON)</span><span style={{ color: isDark ? 'var(--d-accent)' : 'var(--l-accent)' }}>→</span></div>
            </div>
          </div>

          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>À propos</div>
            <div className="group">
              <div className="row"><span>Version</span><span style={{ opacity: .7 }}>1.0.0</span></div>
              <div className="row"><span>Confidentialité</span><span style={{ color: isDark ? 'var(--d-accent)' : 'var(--l-accent)' }}>→</span></div>
            </div>
          </div>
        </div>
        <HomeIndicator />
      </div>
    </div>
  );
}

// Export to global
Object.assign(window, {
  OnboardingWelcome, OnboardingPitch, OnboardingPermissions, OnboardingAlarm,
  DashboardEmpty, DashboardIdle, DashboardPost,
  AlarmEdit, AlarmRinging, PresenceTimer,
  Q1Mood, Q2Priority, Q3Gratitude, Q4Intention,
  Synthesis, CategoryDetail, AskLumen, Settings,
});
