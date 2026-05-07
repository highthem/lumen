// loops.jsx — 6 micro-loops autonomes, chacun ~4-8s, qui bouclent.
// Chaque LoopXxx prend toute la Stage et se rejoue en boucle.

// ─── 1. Kinetic title — 6s loop ─────────────────────────────────────────────
function LoopKineticTitle() {
  const time = useTime();
  const t = time % 6;

  const bgT = Easing.easeOutCubic(clamp(t / 0.6, 0, 1));
  const sunY = 110 - Easing.easeOutCubic(clamp(t / 2.2, 0, 1)) * 55;
  const lumenT = Easing.easeOutCubic(clamp((t - 0.5) / 0.8, 0, 1));
  const morningT = Easing.easeOutCubic(clamp((t - 0.9) / 0.8, 0, 1));
  const sublineT = Easing.easeOutCubic(clamp((t - 1.6) / 0.6, 0, 1));
  const exitT = clamp((t - 5.0) / 1.0, 0, 1);
  const masterOp = bgT * (1 - Easing.easeInCubic(exitT));

  return (
    <div style={{ position: 'absolute', inset: 0, background: LUMEN.bg, opacity: masterOp }}>
      <div style={{
        position: 'absolute',
        left: '50%', top: `${sunY}%`,
        width: 1100, height: 1100,
        marginLeft: -550, marginTop: -550,
        borderRadius: '50%',
        background: `radial-gradient(circle, ${LUMEN.sun5} 0%, ${LUMEN.accent}66 25%, ${LUMEN.sun3}33 50%, transparent 75%)`,
        opacity: 0.4 + Math.sin(t * 1.2) * 0.06,
        filter: 'blur(40px)',
      }} />
      <div style={{
        position: 'absolute',
        left: '50%', top: '50%',
        transform: 'translate(-50%, -50%)',
        textAlign: 'center',
      }}>
        <div style={{
          fontFamily: FONTS.serif, fontSize: 132, fontWeight: 400,
          letterSpacing: '-0.025em', lineHeight: 1.0, color: LUMEN.text,
        }}>
          <span style={{ display: 'inline-block', opacity: lumenT, transform: `translateY(${(1 - lumenT) * 40}px)` }}>Lumen</span>
          <br/>
          <span style={{ display: 'inline-block', opacity: morningT, transform: `translateY(${(1 - morningT) * 40}px)`, fontStyle: 'italic', color: LUMEN.accent }}>Morning</span>
        </div>
        <div style={{
          marginTop: 28, fontFamily: FONTS.sans, fontSize: 16,
          letterSpacing: '0.3em', textTransform: 'uppercase',
          color: 'rgba(245, 239, 230, 0.55)', opacity: sublineT,
        }}>
          Réveille‑toi sans écran
        </div>
      </div>
      <Vignette opacity={0.8} />
    </div>
  );
}

// ─── 2. Sunrise alarm — 8s loop ─────────────────────────────────────────────
function LoopSunriseAlarm() {
  const time = useTime();
  const t = time % 8;
  const sp = Easing.easeInOutCubic(clamp(t / 6.5, 0, 1));
  const phoneIn = Easing.easeOutCubic(clamp((t - 0.3) / 0.8, 0, 1));
  const stopBtnT = clamp((t - 4.5) / 0.7, 0, 1);
  const exitT = clamp((t - 7.2) / 0.8, 0, 1);
  const op = phoneIn * (1 - Easing.easeInCubic(exitT));

  const minute = 25 + Math.floor((t / 8) * 6);
  const timeStr = `06:${String(Math.min(30, minute)).padStart(2, '0')}`;

  return (
    <div style={{ position: 'absolute', inset: 0 }}>
      <SunriseLayer progress={sp} />
      <div style={{ opacity: op }}>
        <PhoneFrame
          x="50%" y="50%"
          width={360} height={780}
          glow={sp > 0.4}
          screen={
            <div style={{ position: 'absolute', inset: 0 }}>
              <SunriseLayer progress={sp} />
              <div style={{
                position: 'absolute', inset: 0,
                display: 'flex', flexDirection: 'column',
                alignItems: 'center', justifyContent: 'space-between',
                padding: '80px 24px 56px',
              }}>
                <div style={{
                  fontFamily: FONTS.serif, fontSize: 92, fontWeight: 300,
                  color: LUMEN.text, letterSpacing: '-0.02em',
                  textShadow: '0 4px 20px rgba(0,0,0,0.4)',
                }}>{timeStr}</div>
                <div style={{
                  maxWidth: 280, textAlign: 'center',
                  fontFamily: FONTS.serif, fontSize: 19, fontStyle: 'italic',
                  lineHeight: 1.4, color: 'rgba(245, 239, 230, 0.85)',
                  textShadow: '0 2px 12px rgba(0,0,0,0.5)',
                }}>«&nbsp;La première lumière t'appartient.&nbsp;»</div>
                <button style={{
                  padding: '20px 60px', borderRadius: 999, border: 'none',
                  background: 'rgba(245, 239, 230, 0.95)', color: LUMEN.bg,
                  fontFamily: FONTS.sans, fontSize: 18, fontWeight: 600,
                  letterSpacing: '0.05em',
                  opacity: stopBtnT,
                  transform: `scale(${0.92 + 0.08 * stopBtnT})`,
                  boxShadow: '0 8px 32px rgba(0,0,0,0.3)',
                }}>Silence</button>
              </div>
            </div>
          }
        />
      </div>
    </div>
  );
}

// ─── 3. Voice transcription — 6s loop ───────────────────────────────────────
function LoopVoice() {
  const time = useTime();
  const t = time % 6;
  const phrase = "Je me sens un peu lourd ce matin… mais reposé.";
  const words = phrase.split(' ');
  const inT = Easing.easeOutCubic(clamp(t / 0.5, 0, 1));
  const exitT = clamp((t - 5.3) / 0.7, 0, 1);
  const op = inT * (1 - Easing.easeInCubic(exitT));
  const wordStart = 0.5;
  const wordEnd = 4.5;
  const perWord = (wordEnd - wordStart) / words.length;
  const pulse = 1 + Math.sin(t * 4.5) * 0.06;
  const ripplePhase = (t * 0.6) % 1;

  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: LUMEN.bg, opacity: op,
    }}>
      <div style={{
        position: 'absolute', left: '50%', bottom: -200,
        width: 900, height: 900, marginLeft: -450, borderRadius: '50%',
        background: `radial-gradient(circle, ${LUMEN.sun3}55 0%, ${LUMEN.bg}00 60%)`,
        filter: 'blur(40px)',
      }} />
      <Eyebrow>Voix · transcription locale</Eyebrow>
      <div style={{
        position: 'absolute', left: '50%', top: '38%',
        transform: 'translate(-50%, -50%)', maxWidth: 1100, textAlign: 'center',
        fontFamily: FONTS.serif, fontSize: 60, fontWeight: 400, fontStyle: 'italic',
        lineHeight: 1.3, color: LUMEN.text, letterSpacing: '-0.01em',
      }}>
        {words.map((w, i) => {
          const wt = clamp((t - wordStart - i * perWord) / 0.3, 0, 1);
          const eased = Easing.easeOutCubic(wt);
          const isAccent = /lourd|reposé/.test(w);
          return (
            <span key={i} style={{
              display: 'inline-block',
              opacity: eased,
              transform: `translateY(${(1 - eased) * 16}px)`,
              color: isAccent ? LUMEN.accent : LUMEN.text,
              marginRight: 14,
            }}>{w}</span>
          );
        })}
      </div>
      {/* Mic */}
      <div style={{ position: 'absolute', left: '50%', bottom: 200, marginLeft: -200, width: 400, height: 400 }}>
        {[0, 0.33, 0.66].map((offset, i) => {
          const tt = (ripplePhase + offset) % 1;
          const size = 80 + tt * 280;
          return (
            <div key={i} style={{
              position: 'absolute',
              left: '50%', top: '50%',
              width: size, height: size,
              marginLeft: -size / 2, marginTop: -size / 2,
              borderRadius: '50%',
              border: `1.5px solid ${LUMEN.accent}`,
              opacity: (1 - tt) * 0.4,
            }} />
          );
        })}
        <div style={{
          position: 'absolute',
          left: '50%', top: '50%',
          width: 96, height: 96,
          marginLeft: -48, marginTop: -48,
          borderRadius: '50%',
          background: `radial-gradient(circle, ${LUMEN.accent} 0%, ${LUMEN.accentMut} 100%)`,
          transform: `scale(${pulse})`,
          boxShadow: `0 0 40px ${LUMEN.accent}66`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="36" height="36" viewBox="0 0 36 36" fill="none">
            <rect x="14" y="6" width="8" height="18" rx="4" fill={LUMEN.bg} />
            <path d="M9 18a9 9 0 0018 0M18 27v4M14 31h8" stroke={LUMEN.bg} strokeWidth="2" strokeLinecap="round" />
          </svg>
        </div>
      </div>
    </div>
  );
}

// ─── 4. Card deck Q2 — 7s loop ──────────────────────────────────────────────
function LoopCardDeck() {
  const time = useTime();
  const t = time % 7;
  const cards = [
    { label: 'Appeler maman', sub: 'Promis hier' },
    { label: 'Marcher 20 min', sub: 'Avant le travail' },
    { label: 'Écrire 30 min', sub: 'Le chapitre 3' },
  ];

  const inT = Easing.easeOutCubic(clamp(t / 0.6, 0, 1));
  const swipe1 = Easing.easeInOutCubic(clamp((t - 1.0) / 0.7, 0, 1));
  const swipe2 = Easing.easeInOutCubic(clamp((t - 2.4) / 0.7, 0, 1));
  const selT = clamp((t - 3.5) / 0.5, 0, 1);
  const exitT = clamp((t - 6.2) / 0.8, 0, 1);
  const op = inT * (1 - Easing.easeInCubic(exitT));

  const cardTransform = (i) => {
    let stackPos, translateX = 0, rotate = 0, opacity = 1;
    if (i === 0) {
      stackPos = 0;
      translateX = swipe1 * 800;
      rotate = swipe1 * 18;
      opacity = 1 - swipe1;
    } else if (i === 1) {
      stackPos = 1 - swipe1;
      translateX = swipe2 * 800;
      rotate = swipe2 * 18;
      opacity = 1 - swipe2;
    } else {
      stackPos = 2 - swipe1 - swipe2;
    }
    const scale = 1 - Math.max(0, stackPos) * 0.06;
    const baseOp = stackPos < 0 ? 0 : Math.max(0, 1 - Math.max(0, stackPos) * 0.3);
    return { translateX, ty: Math.max(0, stackPos) * 26, scale, rotate, opacity: opacity * baseOp };
  };

  return (
    <div style={{ position: 'absolute', inset: 0, background: LUMEN.bg, opacity: op }}>
      <Eyebrow>Q2 · Une priorité</Eyebrow>
      <div style={{
        position: 'absolute',
        left: '50%', top: '50%',
        width: 560, height: 360,
        marginLeft: -280, marginTop: -180,
      }}>
        {cards.map((c, i) => {
          const tr = cardTransform(i);
          const isSelected = i === 2 && t > 3.5;
          return (
            <div key={i} style={{
              position: 'absolute', left: 0, top: 0,
              width: 560, height: 360,
              zIndex: 100 - i,
              background: isSelected
                ? `linear-gradient(180deg, ${LUMEN.accent} 0%, ${LUMEN.accentMut} 100%)`
                : LUMEN.bgEl,
              borderRadius: 28,
              border: `1px solid ${isSelected ? LUMEN.accent : LUMEN.divider}`,
              transform: `translate(${tr.translateX}px, ${tr.ty}px) scale(${tr.scale}) rotate(${tr.rotate}deg)`,
              opacity: tr.opacity,
              boxShadow: isSelected
                ? `0 30px 80px ${LUMEN.accent}55`
                : '0 20px 50px rgba(0,0,0,0.4)',
              padding: 44,
              display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
              overflow: 'hidden',
            }}>
              <div style={{
                fontFamily: FONTS.sans, fontSize: 11,
                letterSpacing: '0.2em', textTransform: 'uppercase',
                color: isSelected ? LUMEN.bg : LUMEN.text3,
                opacity: 0.7,
              }}>Option {i + 1} / 3</div>
              <div>
                <div style={{
                  fontFamily: FONTS.serif, fontSize: 50, fontWeight: 500,
                  color: isSelected ? LUMEN.bg : LUMEN.text,
                  letterSpacing: '-0.01em', lineHeight: 1.1,
                }}>{c.label}</div>
                <div style={{
                  marginTop: 10, fontFamily: FONTS.sans, fontSize: 19,
                  color: isSelected ? 'rgba(15, 13, 11, 0.7)' : LUMEN.text2,
                }}>{c.sub}</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─── 5. Breathing timer — 8s loop (one full breath cycle) ───────────────────
function LoopBreathing() {
  const time = useTime();
  const t = time % 8;
  const bp = (t / 4) % 2;
  const isInhale = bp < 1;
  const phaseT = isInhale ? bp : 2 - bp;
  const eased = Easing.easeInOutSine(phaseT);
  const scale = 0.55 + eased * 0.45;
  const word = isInhale ? 'Inspire' : 'Expire';
  const wordOp = Math.sin(phaseT * Math.PI) ** 0.5;

  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: `radial-gradient(ellipse at center, ${LUMEN.bgHi} 0%, ${LUMEN.bg} 70%)`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <Eyebrow>Pause · 4 minutes</Eyebrow>
      <div style={{
        position: 'relative', width: 600, height: 600,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{
          position: 'absolute', width: 600, height: 600,
          borderRadius: '50%', border: `1px solid ${LUMEN.divider}`,
          opacity: 0.4,
        }} />
        <div style={{
          width: 480, height: 480, borderRadius: '50%',
          background: `radial-gradient(circle, ${LUMEN.accent} 0%, ${LUMEN.accentMut}88 50%, transparent 80%)`,
          transform: `scale(${scale})`,
          filter: `blur(${(1 - eased) * 8 + 6}px)`,
          opacity: 0.55 + eased * 0.3,
        }} />
        <div style={{
          position: 'absolute', width: 80, height: 80, borderRadius: '50%',
          background: LUMEN.accent,
          transform: `scale(${0.5 + eased * 0.5})`,
          boxShadow: `0 0 40px ${LUMEN.accent}aa`,
        }} />
        <div style={{
          position: 'absolute', fontFamily: FONTS.serif,
          fontSize: 38, fontStyle: 'italic',
          color: LUMEN.text, opacity: wordOp * 0.9,
          marginTop: 280, letterSpacing: '0.04em',
        }}>{word}</div>
      </div>
    </div>
  );
}

// ─── 6. Synthesis reveal — 7s loop ──────────────────────────────────────────
function LoopSynthesis() {
  const time = useTime();
  const t = time % 7;
  const inT = Easing.easeOutCubic(clamp(t / 0.5, 0, 1));
  const b1 = Easing.easeOutCubic(clamp((t - 0.5) / 0.6, 0, 1));
  const b2 = Easing.easeOutCubic(clamp((t - 1.1) / 0.6, 0, 1));
  const b3 = Easing.easeOutCubic(clamp((t - 1.7) / 0.6, 0, 1));
  const playerT = Easing.easeOutCubic(clamp((t - 2.6) / 0.6, 0, 1));
  const playProgress = clamp((t - 3.4) / 2.5, 0, 1);
  const exitT = clamp((t - 6.3) / 0.7, 0, 1);
  const op = inT * (1 - Easing.easeInCubic(exitT) * 0.4);

  const Block = ({ tt, eyebrow, title, body, accent }) => (
    <div style={{
      opacity: tt, transform: `translateY(${(1 - tt) * 24}px)`,
      background: LUMEN.bgEl, border: `1px solid ${LUMEN.divider}`,
      borderRadius: 24, padding: 32,
    }}>
      <div style={{
        fontFamily: FONTS.sans, fontSize: 11,
        letterSpacing: '0.22em', textTransform: 'uppercase',
        color: accent || LUMEN.text3, marginBottom: 12,
      }}>{eyebrow}</div>
      <div style={{
        fontFamily: FONTS.serif, fontSize: 32, fontWeight: 500,
        color: LUMEN.text, letterSpacing: '-0.01em',
        lineHeight: 1.2, marginBottom: 10,
      }}>{title}</div>
      <div style={{
        fontFamily: FONTS.sans, fontSize: 16,
        color: LUMEN.text2, lineHeight: 1.5,
      }}>{body}</div>
    </div>
  );

  return (
    <div style={{ position: 'absolute', inset: 0, background: LUMEN.bg, opacity: op, padding: 64 }}>
      <div style={{
        position: 'absolute', right: -200, top: -200,
        width: 700, height: 700, borderRadius: '50%',
        background: `radial-gradient(circle, ${LUMEN.accent}33 0%, transparent 60%)`,
        filter: 'blur(40px)',
      }} />
      <Eyebrow>Synthèse · 06:42</Eyebrow>
      <div style={{
        fontFamily: FONTS.serif, fontSize: 56, fontWeight: 400,
        color: LUMEN.text, letterSpacing: '-0.02em', marginTop: 24,
        opacity: inT,
      }}>
        Ce que tu portes <span style={{ fontStyle: 'italic', color: LUMEN.accent }}>ce matin</span>
      </div>
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
        gap: 24, marginTop: 56, maxWidth: 1500,
      }}>
        <Block tt={b1} eyebrow="Couleur du jour" title="Sable chaud" body="Lent, mais stable." accent={LUMEN.accent} />
        <Block tt={b2} eyebrow="Boussole" title="Le chapitre 3" body="30 min. Avant le reste." accent="#7FA58A" />
        <Block tt={b3} eyebrow="Phrase à garder" title="« Calme, mais stable. »" body="Le ton de ta voix te le disait." accent="#D4A853" />
      </div>
      <div style={{
        position: 'absolute', left: 64, right: 64, bottom: 64,
        opacity: playerT, transform: `translateY(${(1 - playerT) * 30}px)`,
      }}>
        <div style={{
          background: `linear-gradient(180deg, ${LUMEN.bgEl} 0%, ${LUMEN.bgHi} 100%)`,
          border: `1px solid ${LUMEN.divider}`,
          borderRadius: 24, padding: '20px 28px',
          display: 'flex', alignItems: 'center', gap: 20,
        }}>
          <div style={{
            width: 56, height: 56, borderRadius: '50%',
            background: LUMEN.accent,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 4px 16px ${LUMEN.accent}55`,
          }}>
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
              <path d="M5 3l12 7-12 7V3z" fill={LUMEN.bg} />
            </svg>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{
              fontFamily: FONTS.sans, fontSize: 11,
              letterSpacing: '0.2em', textTransform: 'uppercase',
              color: LUMEN.text3, marginBottom: 8,
            }}>Écouter ta synthèse · 1 min 12</div>
            <div style={{ height: 4, background: LUMEN.divider, borderRadius: 2, overflow: 'hidden' }}>
              <div style={{
                width: `${playProgress * 100}%`, height: '100%',
                background: `linear-gradient(90deg, ${LUMEN.accent} 0%, ${LUMEN.sun5} 100%)`,
              }} />
            </div>
          </div>
          <div style={{
            fontFamily: FONTS.mono, fontSize: 13,
            color: LUMEN.text2, fontVariantNumeric: 'tabular-nums',
          }}>{`${Math.floor(playProgress * 72 / 60)}:${String(Math.floor(playProgress * 72 % 60)).padStart(2, '0')}`}</div>
        </div>
      </div>
    </div>
  );
}

// ─── 7. Ambient — quiet hero background, 14s ────────────────────────────────
// Slow breathing sunrise glow, drifting particles, no text. Designed to live
// behind hero copy without competing.
function LoopAmbient() {
  const time = useTime();
  const t = time % 14;
  const breath = (Math.sin((t / 14) * Math.PI * 2 - Math.PI / 2) + 1) / 2;

  const cx = 960 + Math.sin((t / 14) * Math.PI * 2) * 80;
  const cy = 720 + Math.cos((t / 14) * Math.PI * 2) * 40;

  const particles = React.useMemo(() => {
    const arr = [];
    for (let i = 0; i < 14; i++) {
      arr.push({
        x: 80 + (i * 137) % 1760,
        offset: (i * 1.7) % 14,
        speed: 0.6 + (i % 3) * 0.15,
        r: 1.2 + (i % 4) * 0.4,
      });
    }
    return arr;
  }, []);

  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: '#0F0D0B',
      overflow: 'hidden',
    }}>
      <div style={{
        position: 'absolute',
        left: cx - 900, top: cy - 900,
        width: 1800, height: 1800,
        borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(232,195,158,0.22) 0%, rgba(166,133,102,0.10) 30%, rgba(15,13,11,0) 65%)',
        opacity: 0.55 + breath * 0.35,
        filter: 'blur(40px)',
      }} />

      <div style={{
        position: 'absolute',
        left: 960 - Math.sin((t / 14) * Math.PI * 2) * 200 - 700,
        top: 200,
        width: 1400, height: 1400,
        borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(122,63,42,0.12) 0%, rgba(15,13,11,0) 60%)',
        opacity: 0.4 + (1 - breath) * 0.3,
        filter: 'blur(60px)',
      }} />

      <svg viewBox="0 0 1920 1080" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
        {particles.map((p, i) => {
          const localT = ((t + p.offset) % 14) / 14;
          const y = 1080 - localT * 1200 * p.speed;
          const opacity = localT < 0.15 ? localT / 0.15
                        : localT > 0.85 ? (1 - localT) / 0.15
                        : 1;
          return (
            <circle
              key={i}
              cx={p.x + Math.sin(localT * Math.PI * 4) * 12}
              cy={y}
              r={p.r}
              fill="#E8C39E"
              opacity={opacity * 0.5}
            />
          );
        })}
      </svg>

      <div style={{
        position: 'absolute', inset: 0,
        background: 'radial-gradient(ellipse at center, rgba(15,13,11,0) 30%, rgba(15,13,11,0.4) 70%, rgba(15,13,11,0.85) 100%)',
        pointerEvents: 'none',
      }} />
    </div>
  );
}

Object.assign(window, {
  LoopKineticTitle, LoopSunriseAlarm, LoopVoice,
  LoopCardDeck, LoopBreathing, LoopSynthesis,
  LoopAmbient,
});
