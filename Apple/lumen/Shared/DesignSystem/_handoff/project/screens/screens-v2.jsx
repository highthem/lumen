// Lumen V2 — Voice screens (Q3, Q4, Synthesis variants, Settings)

const StatusBarV2 = ({ time = '7:14' }) => (
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
const HomeIndicatorV2 = () => <div className="home"></div>;

// SF-style microphone glyph
const MicGlyph = ({ size = 32, filled = true }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="1.6">
    <rect x="9" y="3" width="6" height="12" rx="3" fill="currentColor"/>
    <path d="M5 11a7 7 0 0014 0M12 18v3M8 21h8" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"/>
  </svg>
);
const SpeakerGlyph = ({ size = 18, filled = false }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round">
    <path d="M11 5L6 9H3v6h3l5 4V5z" fill={filled ? 'currentColor' : 'none'}/>
    <path d="M15 9c1.5 1.5 1.5 4.5 0 6" strokeLinecap="round"/>
    <path d="M18 6c3 3 3 9 0 12" strokeLinecap="round"/>
  </svg>
);
const KeyboardGlyph = ({ size = 14 }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4">
    <rect x="1" y="3" width="14" height="10" rx="2"/>
    <path d="M4 7h.01M7 7h.01M10 7h.01M13 7h.01M5 10h6"/>
  </svg>
);

// ─────────────────────────────────────────────────────────────
// Q3 Gratitude — voice (4 states × dark/light)
// ─────────────────────────────────────────────────────────────
function Q3GratitudeVoice({ mode = 'dark', state = 'default' }) {
  const isDark = mode === 'dark';
  const accent = isDark ? 'var(--d-accent)' : 'var(--l-accent)';

  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBarV2 />
        <div className="content" style={{ paddingTop: 28, gap: 24 }}>
          <div className="prog"><i className="done"></i><i className="done"></i><i className="cur"></i><i></i></div>
          <div>
            <div className="eyebrow">03 / 04 · Gratitude</div>
            <div className="h-title">Une gratitude ?</div>
          </div>

          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', gap: 36 }}>
            {/* Transcribed text area */}
            <div style={{ minHeight: 110, maxWidth: 300, textAlign: 'center', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {state === 'default' && (
                <div className="serif" style={{ fontSize: 17, fontStyle: 'italic', opacity: .42, lineHeight: 1.4 }}>
                  Parle, je t'écoute…
                </div>
              )}
              {state === 'listening' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 14, alignItems: 'center' }}>
                  <div className="wave" style={{ color: accent }}><i></i><i></i><i></i><i></i><i></i></div>
                  <div style={{ fontSize: 12, letterSpacing: '.18em', textTransform: 'uppercase', opacity: .6 }}>J'écoute</div>
                </div>
              )}
              {state === 'transcribed' && (
                <div className="serif" style={{ fontSize: 22, lineHeight: 1.35, letterSpacing: '-0.005em', fontWeight: 500, textWrap: 'balance' }}>
                  Le silence avant que les enfants se lèvent.
                </div>
              )}
              {state === 'editing' && (
                <textarea autoFocus rows={3} defaultValue="Le silence avant que les enfants se lèvent." style={{ width: 300, appearance: 'none', borderRadius: 14, padding: '14px 18px', fontSize: 17, fontFamily: 'Charter, serif', resize: 'none', background: isDark ? 'var(--d-bg2)' : 'var(--l-bg2)', color: 'inherit', border: `1.5px solid ${accent}`, outline: 0, lineHeight: 1.4 }} />
              )}
            </div>

            {/* Mic button */}
            {state !== 'editing' && (
              <button className={`mic ${state === 'listening' ? 'listening' : state === 'transcribed' ? 'transcribed' : 'idle'}`}>
                <MicGlyph size={36} />
              </button>
            )}
          </div>

          {/* Action row depending on state */}
          <div style={{ display: 'flex', gap: 8, justifyContent: 'center', flexWrap: 'wrap', minHeight: 36 }}>
            {state === 'default' && (
              <>
                <button className="cta ghost" style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}><KeyboardGlyph /> Écrire au clavier</button>
              </>
            )}
            {state === 'listening' && (
              <button className="cta ghost" style={{ fontSize: 13 }}>Annuler</button>
            )}
            {state === 'transcribed' && (
              <>
                <button className="cta ghost" style={{ fontSize: 13 }}>↺ Recommencer</button>
                <button className="cta ghost" style={{ fontSize: 13, display: 'flex', alignItems: 'center', gap: 6 }}><KeyboardGlyph /> Modifier</button>
              </>
            )}
            {state === 'editing' && (
              <button className="cta ghost" style={{ fontSize: 13 }}>← Retour à la voix</button>
            )}
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <button className="cta ghost">Passer</button>
            <button className="cta primary" style={{ flex: 1, opacity: state === 'default' || state === 'listening' ? .4 : 1 }}>Suivant</button>
          </div>
        </div>
        <HomeIndicatorV2 />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Q4 Intention — voice (4 states × dark/light)
// ─────────────────────────────────────────────────────────────
function Q4IntentionVoice({ mode = 'dark', state = 'default' }) {
  const isDark = mode === 'dark';
  const accent = isDark ? 'var(--d-accent)' : 'var(--l-accent)';

  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBarV2 />
        <div className="content" style={{ paddingTop: 28, gap: 24 }}>
          <div className="prog"><i className="done"></i><i className="done"></i><i className="done"></i><i className="cur"></i></div>
          <div>
            <div className="eyebrow">04 / 04 · Intention</div>
            <div className="h-title">Ton intention<br/>en un mot.</div>
          </div>

          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', gap: 36 }}>
            <div style={{ minHeight: 110, textAlign: 'center', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {state === 'default' && (
                <div className="serif" style={{ fontSize: 19, fontStyle: 'italic', opacity: .42 }}>Dis-le…</div>
              )}
              {state === 'listening' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 14, alignItems: 'center' }}>
                  <div className="wave" style={{ color: accent }}><i></i><i></i><i></i><i></i><i></i></div>
                  <div style={{ fontSize: 12, letterSpacing: '.18em', textTransform: 'uppercase', opacity: .6 }}>J'écoute</div>
                </div>
              )}
              {state === 'transcribed' && (
                <div className="serif" style={{ fontSize: 56, lineHeight: 1, fontWeight: 500, fontStyle: 'italic', letterSpacing: '-0.02em', color: accent }}>
                  présence
                </div>
              )}
              {state === 'editing' && (
                <input autoFocus defaultValue="présence" style={{ width: 240, appearance: 'none', border: 0, borderBottom: `1px solid ${accent}`, background: 'transparent', textAlign: 'center', fontFamily: 'Charter, serif', fontSize: 56, color: accent, fontStyle: 'italic', fontWeight: 500, padding: '8px 0', outline: 0, letterSpacing: '-0.02em' }} />
              )}
            </div>

            {state !== 'editing' && (
              <button className={`mic ${state === 'listening' ? 'listening' : state === 'transcribed' ? 'transcribed' : 'idle'}`}>
                <MicGlyph size={36} />
              </button>
            )}
          </div>

          <div style={{ display: 'flex', gap: 8, justifyContent: 'center', flexWrap: 'wrap', minHeight: 36 }}>
            {state === 'default' && (
              <button className="cta ghost" style={{ fontSize: 13, display: 'flex', alignItems: 'center', gap: 6 }}><KeyboardGlyph /> Écrire au clavier</button>
            )}
            {state === 'listening' && (
              <button className="cta ghost" style={{ fontSize: 13 }}>Annuler</button>
            )}
            {state === 'transcribed' && (
              <>
                <button className="cta ghost" style={{ fontSize: 13 }}>↺ Recommencer</button>
                <button className="cta ghost" style={{ fontSize: 13, display: 'flex', alignItems: 'center', gap: 6 }}><KeyboardGlyph /> Modifier</button>
              </>
            )}
            {state === 'editing' && (
              <button className="cta ghost" style={{ fontSize: 13 }}>← Retour à la voix</button>
            )}
          </div>

          <button className="cta primary" style={{ opacity: state === 'default' || state === 'listening' ? .4 : 1 }}>Voir ma synthèse</button>
        </div>
        <HomeIndicatorV2 />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Synthesis V2 — Cloud + Listen button (idle / playing)
// ─────────────────────────────────────────────────────────────
function SynthesisV2Cloud({ mode = 'dark', playing = false }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr glow-top">
        <StatusBarV2 />
        <div className="content" style={{ paddingTop: 28, overflow: 'auto', gap: 24 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div className="eyebrow">Ton matin</div>
            <button className={`spk ${playing ? 'playing' : ''}`}>
              <SpeakerGlyph size={16} filled={playing} />
              {playing ? (
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
                  <span>Lecture</span>
                  <span className="wave" style={{ height: 14 }}><i style={{ height: 6 }}></i><i style={{ height: 10 }}></i><i style={{ height: 14 }}></i><i style={{ height: 8 }}></i></span>
                </span>
              ) : 'Écouter'}
            </button>
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
                La fatigue passe, la précipitation s'installe. Tu choisis laquelle des deux nourrir.
              </div>
            </div>
          </div>

          <div style={{ flex: 1, minHeight: 16 }}></div>

          <div style={{ display: 'flex', gap: 12, flexDirection: 'column' }}>
            <div style={{ fontSize: 12, opacity: .55 }}>Régénérations · 2 / 3 restantes</div>
            <button className="cta secondary">Régénérer</button>
            <button className="cta primary">Continuer vers le dashboard</button>
          </div>
        </div>
        <HomeIndicatorV2 />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Synthesis V2 — Apple Intelligence on-device
// ─────────────────────────────────────────────────────────────
function SynthesisV2AppleIntel({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr glow-top">
        <StatusBarV2 />
        <div className="content" style={{ paddingTop: 28, overflow: 'auto', gap: 24 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
            <div className="eyebrow">Ton matin</div>
            <button className="spk">
              <SpeakerGlyph size={16} />Écouter
            </button>
          </div>

          <div className="ai-badge" style={{ alignSelf: 'flex-start' }}>
            <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor"><path d="M5 0L6 4L10 5L6 6L5 10L4 6L0 5L4 4Z"/></svg>
            On-device · Apple Intelligence
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
            <div>
              <div className="eyebrow" style={{ marginBottom: 8 }}>Intention</div>
              <div className="serif" style={{ fontSize: 42, lineHeight: 1.1, letterSpacing: '-0.02em', fontWeight: 500, fontStyle: 'italic', color: isDark ? 'var(--d-accent)' : 'var(--l-accent)' }}>présence</div>
            </div>
            <div>
              <div className="eyebrow" style={{ marginBottom: 8 }}>Focus</div>
              <div className="serif" style={{ fontSize: 19, lineHeight: 1.45, letterSpacing: '-0.005em' }}>
                Écouter Karim sans projeter de réponse.<br/>
                Une marche de vingt minutes, sans téléphone.
              </div>
            </div>
            <div>
              <div className="eyebrow" style={{ marginBottom: 8 }}>Rappel</div>
              <div className="serif" style={{ fontSize: 17, lineHeight: 1.5, fontStyle: 'italic', opacity: .75 }}>
                Le calme tient mieux quand on l'a choisi tôt dans la journée.
              </div>
            </div>
          </div>

          <div style={{ flex: 1, minHeight: 16 }}></div>

          <div style={{ display: 'flex', gap: 12, flexDirection: 'column' }}>
            <div style={{ fontSize: 12, opacity: .55 }}>Généré localement · aucun envoi réseau</div>
            <button className="cta primary">Continuer vers le dashboard</button>
          </div>
        </div>
        <HomeIndicatorV2 />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Synthesis V2 — Queued (offline, waiting for network)
// ─────────────────────────────────────────────────────────────
function SynthesisV2Queued({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBarV2 />
        <div className="content" style={{ paddingTop: 28, gap: 24 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div className="eyebrow">Ton matin</div>
            <span className="chip" style={{ fontSize: 11, padding: '5px 11px', display: 'flex', gap: 6, alignItems: 'center' }}>
              <span style={{ width: 6, height: 6, borderRadius: 999, background: '#D89C5A', display: 'inline-block' }}></span>
              Hors-ligne
            </span>
          </div>

          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 40, textAlign: 'center' }}>
            <div className="slowpulse" style={{ color: isDark ? 'var(--d-accent)' : 'var(--l-accent)' }}></div>
            <div style={{ maxWidth: 280 }}>
              <div className="serif" style={{ fontSize: 26, lineHeight: 1.3, letterSpacing: '-0.005em', fontWeight: 500, textWrap: 'balance' }}>
                Ta synthèse arrive.
              </div>
              <div className="serif" style={{ fontSize: 17, lineHeight: 1.5, fontStyle: 'italic', opacity: .7, marginTop: 12, textWrap: 'balance' }}>
                On te notifie au retour réseau. Tes réponses sont gardées au chaud.
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div style={{ fontSize: 12, opacity: .55, textAlign: 'center' }}>En attente · vérifié toutes les 30 s</div>
            <button className="cta secondary">Aller au dashboard</button>
          </div>
        </div>
        <HomeIndicatorV2 />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Settings V2 — section Voice + section IA waterfall
// ─────────────────────────────────────────────────────────────
function SettingsV2({ mode = 'dark' }) {
  const isDark = mode === 'dark';
  const accent = isDark ? 'var(--d-accent)' : 'var(--l-accent)';
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <StatusBarV2 />
        <div className="content" style={{ paddingTop: 24, gap: 24, overflow: 'auto' }}>
          <div className="eyebrow">Réglages</div>
          <div className="serif" style={{ fontSize: 32, fontWeight: 500, letterSpacing: '-0.01em' }}>Tien.</div>

          {/* Voice */}
          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>Voice</div>
            <div className="group">
              <div className="row">
                <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <span>Mode vocal par défaut</span>
                  <span style={{ fontSize: 12, opacity: .6 }}>Q3 · Q4 · synthèse</span>
                </div>
                <div className="tog on"><i></i></div>
              </div>
              <div className="row" style={{ flexDirection: 'column', alignItems: 'stretch', gap: 10, paddingTop: 14, paddingBottom: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span>Voix de lecture</span>
                  <span style={{ opacity: .65, fontSize: 13 }}>Audrey (FR) · Premium ›</span>
                </div>
                <div style={{ fontSize: 12, opacity: .55 }}>Tap pour prévisualiser dans la liste</div>
              </div>
              <div className="row" style={{ flexDirection: 'column', alignItems: 'stretch', gap: 10, paddingTop: 14, paddingBottom: 14 }}>
                <span>Vitesse de lecture</span>
                <div className="seg"><span>0.8×</span><span className="sel">1.0×</span><span>1.2×</span></div>
              </div>
              <div className="row" style={{ flexDirection: 'column', alignItems: 'flex-start', gap: 6, paddingTop: 14, paddingBottom: 14 }}>
                <span style={{ fontSize: 13, opacity: .85 }}>L'audio reste sur ton téléphone.</span>
                <span style={{ fontSize: 12, opacity: .55 }}>Aucun envoi à Apple ou ailleurs. Reconnaissance & synthèse traitées on-device.</span>
              </div>
              <div className="row">
                <span>Vérifier les permissions iOS</span>
                <span style={{ color: accent }}>→</span>
              </div>
            </div>
          </div>

          {/* IA waterfall */}
          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>IA · chaîne de fallback</div>
            <div className="group" style={{ padding: '6px 16px' }}>
              <div className="water">
                <div className="step">
                  <div className="dot live"></div>
                  <div className="lbl">OpenAI · GPT-4o-mini<div style={{ fontSize: 12, fontWeight: 400, opacity: .6 }}>Cloud · primaire</div></div>
                  <div className="st">En cours</div>
                </div>
                <div className="step">
                  <div className="dot standby"></div>
                  <div className="lbl">Anthropic · Claude Haiku 4.5<div style={{ fontSize: 12, fontWeight: 400, opacity: .6 }}>Cloud · secours</div></div>
                  <div className="st">Stand-by</div>
                </div>
                <div className="step warn">
                  <div className="dot warn"></div>
                  <div className="lbl">Apple Intelligence<div style={{ fontSize: 12, fontWeight: 400, opacity: .6 }}>On-device · iOS 26+ · A17 Pro+</div></div>
                  <div className="st">Indispo</div>
                </div>
                <div className="step">
                  <div className="dot standby"></div>
                  <div className="lbl">File d'attente<div style={{ fontSize: 12, fontWeight: 400, opacity: .6 }}>Génération différée au retour réseau</div></div>
                  <div className="st">Stand-by</div>
                </div>
              </div>
            </div>
            <div style={{ fontSize: 12, opacity: .55, marginTop: 10, lineHeight: 1.5 }}>
              On essaie chaque service dans l'ordre. Tu n'as rien à choisir.
            </div>
          </div>

          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>Quotas</div>
            <div className="group">
              <div className="row"><span>Questions par jour</span><span style={{ opacity: .7 }}>3 / 3</span></div>
              <div className="row"><span>Régénérations synthèse</span><span style={{ opacity: .7 }}>3 / 3</span></div>
              <div className="row"><span>Exporter mes données (JSON)</span><span style={{ color: accent }}>→</span></div>
            </div>
          </div>

          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>À propos</div>
            <div className="group">
              <div className="row"><span>Version</span><span style={{ opacity: .7 }}>1.0.0</span></div>
              <div className="row"><span>Confidentialité</span><span style={{ color: accent }}>→</span></div>
            </div>
          </div>
        </div>
        <HomeIndicatorV2 />
      </div>
    </div>
  );
}

Object.assign(window, {
  Q3GratitudeVoice, Q4IntentionVoice,
  SynthesisV2Cloud, SynthesisV2AppleIntel, SynthesisV2Queued,
  SettingsV2,
});
