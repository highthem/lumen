// Lumen V3 — Sunrise Echo voice direction
// One rhythm: --breath-cycle = 4s. No waveform. No microphone glyph.
// Listening = transcription appears letter-by-letter in serif display.
// Synthesis playing = reading focus (paragraphes non-lus s'estompent).

const SBV3 = ({ time = '7:14' }) => (
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
const HIV3 = () => <div className="home"></div>;

// Character-by-character reveal — text becomes a fixed string for screenshots
const Reveal = ({ text, baseDelay = 0, perChar = 38 }) => (
  <span aria-label={text}>
    {text.split('').map((c, i) => (
      <span
        key={i}
        className={`ch${c === ' ' ? ' space' : ''}`}
        style={{ animationDelay: `${baseDelay + i * perChar}ms` }}
      >{c === ' ' ? '\u00A0' : c}</span>
    ))}
  </span>
);

// Static (post-reveal) text — full opacity, no animation
const Settled = ({ text }) => (
  <span>{text.split('').map((c, i) => (
    <span key={i} className={`ch${c === ' ' ? ' space' : ''}`} style={{ opacity: 1, animation: 'none' }}>{c === ' ' ? '\u00A0' : c}</span>
  ))}</span>
);

const KbGlyph = ({ size = 14 }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4">
    <rect x="1" y="3" width="14" height="10" rx="2"/>
    <path d="M4 7h.01M7 7h.01M10 7h.01M13 7h.01M5 10h6"/>
  </svg>
);
const SpkGlyph = ({ size = 16, filled = false }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round">
    <path d="M11 5L6 9H3v6h3l5 4V5z" fill={filled ? 'currentColor' : 'none'}/>
    <path d="M15 9c1.5 1.5 1.5 4.5 0 6" strokeLinecap="round"/>
    <path d="M18 6c3 3 3 9 0 12" strokeLinecap="round"/>
  </svg>
);

// ─── Q3 Gratitude · Sunrise Echo ─────────────────────────────
function Q3VoiceV3({ mode = 'dark', state = 'default' }) {
  const isDark = mode === 'dark';
  const accent = isDark ? 'var(--d-accent)' : 'var(--l-accent)';

  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <SBV3 />
        <div className="content" style={{ paddingTop: 28, gap: 24 }}>
          <div className="prog"><i className="done"></i><i className="done"></i><i className="cur"></i><i></i></div>
          <div>
            <div className="eyebrow">03 / 04 · Gratitude</div>
            <div className="h-title">Une gratitude ?</div>
          </div>

          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', gap: 36 }}>
            {/* Reveal area */}
            <div style={{ minHeight: 130, display: 'flex', alignItems: 'flex-end', justifyContent: 'center' }}>
              {state === 'default' && (
                <div className="serif" style={{ fontSize: 17, fontStyle: 'italic', opacity: .42 }}>Parle, je t'écoute…</div>
              )}
              {state === 'listening' && (
                <div className="transcript-live" style={{ color: accent }}>
                  <Reveal text="Le silence avant que les" />
                </div>
              )}
              {state === 'transcribed' && (
                <div className="transcript-live">
                  <Settled text="Le silence avant que les enfants se lèvent." />
                </div>
              )}
              {state === 'editing' && (
                <textarea autoFocus rows={3} defaultValue="Le silence avant que les enfants se lèvent." style={{ width: 320, appearance: 'none', borderRadius: 14, padding: '14px 18px', fontSize: 19, fontFamily: 'Charter, serif', resize: 'none', background: isDark ? 'var(--d-bg2)' : 'var(--l-bg2)', color: 'inherit', border: `1.5px solid ${accent}`, outline: 0, lineHeight: 1.4 }} />
              )}
            </div>

            {/* Mic button — sunrise echo */}
            {state !== 'editing' && (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
                <button className={`mic ${state === 'listening' ? 'listening' : state === 'transcribed' ? 'transcribed' : 'idle'}`}>
                  <span className="glyph">{state === 'transcribed' ? '·' : '\u201C'}</span>
                </button>
                {state === 'listening' && (
                  <div className="listening-foot" style={{ color: accent }}>
                    <span className="dot"></span>on écoute
                  </div>
                )}
              </div>
            )}
          </div>

          <div style={{ display: 'flex', gap: 8, justifyContent: 'center', flexWrap: 'wrap', minHeight: 32 }}>
            {state === 'default' && (
              <button className="cta ghost" style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}><KbGlyph /> Écrire au clavier</button>
            )}
            {state === 'listening' && (
              <button className="cta ghost" style={{ fontSize: 13 }}>Annuler</button>
            )}
            {state === 'transcribed' && (
              <>
                <button className="cta ghost" style={{ fontSize: 13 }}>↺ Recommencer</button>
                <button className="cta ghost" style={{ fontSize: 13, display: 'flex', alignItems: 'center', gap: 6 }}><KbGlyph /> Modifier</button>
              </>
            )}
            {state === 'editing' && (
              <button className="cta ghost" style={{ fontSize: 13, fontStyle: 'italic', fontFamily: 'Charter, serif' }}>Tu peux aussi reparler →</button>
            )}
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <button className="cta ghost">Passer</button>
            <button className="cta primary" style={{ flex: 1, opacity: state === 'default' || state === 'listening' ? .4 : 1 }}>Suivant</button>
          </div>
        </div>
        <HIV3 />
      </div>
    </div>
  );
}

// ─── Q4 Intention · Sunrise Echo ─────────────────────────────
function Q4VoiceV3({ mode = 'dark', state = 'default' }) {
  const isDark = mode === 'dark';
  const accent = isDark ? 'var(--d-accent)' : 'var(--l-accent)';

  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <SBV3 />
        <div className="content" style={{ paddingTop: 28, gap: 24 }}>
          <div className="prog"><i className="done"></i><i className="done"></i><i className="done"></i><i className="cur"></i></div>
          <div>
            <div className="eyebrow">04 / 04 · Intention</div>
            <div className="h-title">Ton intention<br/>en un mot.</div>
          </div>

          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', gap: 36 }}>
            <div style={{ minHeight: 130, display: 'flex', alignItems: 'flex-end', justifyContent: 'center' }}>
              {state === 'default' && (
                <div className="serif" style={{ fontSize: 19, fontStyle: 'italic', opacity: .42 }}>Dis-le…</div>
              )}
              {state === 'listening' && (
                <div className="transcript-live" style={{ fontSize: 64, fontStyle: 'italic', color: accent, lineHeight: 1 }}>
                  <Reveal text="prés" perChar={120} />
                </div>
              )}
              {state === 'transcribed' && (
                <div className="transcript-live" style={{ fontSize: 64, fontStyle: 'italic', color: accent, lineHeight: 1 }}>
                  <Settled text="présence" />
                </div>
              )}
              {state === 'editing' && (
                <input autoFocus defaultValue="présence" style={{ width: 260, appearance: 'none', border: 0, borderBottom: `1px solid ${accent}`, background: 'transparent', textAlign: 'center', fontFamily: 'Charter, serif', fontSize: 64, color: accent, fontStyle: 'italic', fontWeight: 500, padding: '8px 0', outline: 0, letterSpacing: '-0.02em' }} />
              )}
            </div>

            {state !== 'editing' && (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
                <button className={`mic ${state === 'listening' ? 'listening' : state === 'transcribed' ? 'transcribed' : 'idle'}`}>
                  <span className="glyph">{state === 'transcribed' ? '·' : '\u201C'}</span>
                </button>
                {state === 'listening' && (
                  <div className="listening-foot" style={{ color: accent }}>
                    <span className="dot"></span>on écoute
                  </div>
                )}
              </div>
            )}
          </div>

          <div style={{ display: 'flex', gap: 8, justifyContent: 'center', flexWrap: 'wrap', minHeight: 32 }}>
            {state === 'default' && (
              <button className="cta ghost" style={{ fontSize: 13, display: 'flex', alignItems: 'center', gap: 6 }}><KbGlyph /> Écrire au clavier</button>
            )}
            {state === 'listening' && (
              <button className="cta ghost" style={{ fontSize: 13 }}>Annuler</button>
            )}
            {state === 'transcribed' && (
              <>
                <button className="cta ghost" style={{ fontSize: 13 }}>↺ Recommencer</button>
                <button className="cta ghost" style={{ fontSize: 13, display: 'flex', alignItems: 'center', gap: 6 }}><KbGlyph /> Modifier</button>
              </>
            )}
            {state === 'editing' && (
              <button className="cta ghost" style={{ fontSize: 13, fontStyle: 'italic', fontFamily: 'Charter, serif' }}>Tu peux aussi reparler →</button>
            )}
          </div>

          <button className="cta primary" style={{ opacity: state === 'default' || state === 'listening' ? .4 : 1 }}>Voir ma synthèse</button>
        </div>
        <HIV3 />
      </div>
    </div>
  );
}

// ─── Synthesis · reading focus (V3) ──────────────────────────
function SynthesisV3({ mode = 'dark', playing = false, focusBlock = 1 }) {
  const isDark = mode === 'dark';
  const dim = (i) => playing && i !== focusBlock ? 0.32 : 1;
  return (
    <div className={`phone ${mode}`}>
      <div className="scr glow-top">
        <SBV3 />
        <div className="content" style={{ paddingTop: 28, overflow: 'auto', gap: 24 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div className="eyebrow">Ton matin</div>
            <button className="spk">
              <SpkGlyph size={16} filled={playing} />
              {playing ? 'Pause' : 'Écouter'}
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
            <div style={{ opacity: dim(0), transition: 'opacity 600ms ease' }}>
              <div className="eyebrow" style={{ marginBottom: 8 }}>Intention</div>
              <div className="serif" style={{ fontSize: 42, lineHeight: 1.1, letterSpacing: '-0.02em', fontWeight: 500, fontStyle: 'italic', color: isDark ? 'var(--d-accent)' : 'var(--l-accent)' }}>présence</div>
            </div>
            <div style={{ opacity: dim(1), transition: 'opacity 600ms ease', position: 'relative' }}>
              <div className="eyebrow" style={{ marginBottom: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
                Focus
                {playing && focusBlock === 1 && <span style={{ width: 5, height: 5, borderRadius: 999, background: isDark ? 'var(--d-accent)' : 'var(--l-accent)', display: 'inline-block', animation: 'breathe var(--breath-cycle) ease-in-out infinite' }}></span>}
              </div>
              <div className="serif" style={{ fontSize: 19, lineHeight: 1.45, letterSpacing: '-0.005em' }}>
                Écoute Karim sans préparer ta réponse.<br/>
                Marche vingt minutes, le téléphone reste à la maison.
              </div>
            </div>
            <div style={{ opacity: dim(2), transition: 'opacity 600ms ease' }}>
              <div className="eyebrow" style={{ marginBottom: 8 }}>Rappel</div>
              <div className="serif" style={{ fontSize: 17, lineHeight: 1.5, fontStyle: 'italic', opacity: .85 }}>
                La fatigue passe, la précipitation s'installe. Tu choisis laquelle des deux nourrir.
              </div>
            </div>
          </div>

          <div style={{ flex: 1, minHeight: 16 }}></div>

          <div style={{ display: 'flex', gap: 12, flexDirection: 'column' }}>
            <div style={{ fontSize: 12, opacity: .55 }}>{playing ? 'Lecture · paragraphe 2 sur 3' : 'Régénérations · 2 / 3 restantes'}</div>
            {!playing && <button className="cta secondary">Régénérer</button>}
            <button className="cta primary">Continuer vers le dashboard</button>
          </div>
        </div>
        <HIV3 />
      </div>
    </div>
  );
}

Object.assign(window, { Q3VoiceV3, Q4VoiceV3, SynthesisV3 });
