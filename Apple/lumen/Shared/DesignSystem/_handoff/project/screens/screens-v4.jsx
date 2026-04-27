// Lumen V4 — Q1Mood (sun rising) + AlarmRinging (aube qui se lève)

const SBV4 = ({ time = '7:00' }) => (
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
const HIV4 = () => <div className="home"></div>;

// ─── Sun rising glyph (5 levels of horizon ascent) ──────────
// Each glyph = a circle outline with a horizon line that rises through it.
// Level 0 = horizon at bottom (sun barely visible), Level 4 = sun fully risen / disc filled
function SunGlyph({ level = 2, size = 32 }) {
  // The horizon line is at y position; below the line is filled, above is outline
  // Levels: 0 (sun under horizon) → 4 (sun fully risen)
  const cy = 16; // center
  const r = 13;
  // y position of horizon line (lower y = higher horizon = more sun visible)
  // level 0 → sun fully under (horizon at top of disc, y=cy-r=3 means sun under the line)
  // We invert: at level 0 the horizon CUTS the disc near top (only sliver below),
  // at level 4 the disc is entirely above horizon (full sun)
  const horizonY = [cy + r * 0.85, cy + r * 0.4, cy, cy - r * 0.4, cy - r * 0.95][level];

  const clipId = `clip-sun-${level}-${size}`;
  return (
    <svg width={size} height={size} viewBox="0 0 32 32">
      <defs>
        <clipPath id={clipId}>
          <rect x="0" y="0" width="32" height={horizonY} />
        </clipPath>
      </defs>
      {/* Sun disc — outline */}
      <circle className="ring" cx={cy} cy={cy} r={r} />
      {/* Sun filled portion — above horizon */}
      <circle className="fill" cx={cy} cy={cy} r={r} clipPath={`url(#${clipId})`} />
      {/* Horizon line — extends through full width */}
      <line x1="2" y1={horizonY} x2="30" y2={horizonY} stroke="currentColor" strokeWidth="1" opacity="0.55" strokeLinecap="round" />
    </svg>
  );
}

function Q1MoodV4({ mode = 'dark', selected = 1 }) {
  const tags = ['enfoui', 'fragile', 'posé', 'vif', 'rayonnant'];
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <SBV4 time="7:14" />
        <div className="content" style={{ paddingTop: 28, gap: 24 }}>
          <div className="prog"><i className="cur"></i><i></i><i></i><i></i></div>
          <div>
            <div className="eyebrow">01 / 04 · Ressenti</div>
            <div className="h-title">Comment tu<br/>te sens ?</div>
          </div>

          <div style={{ flex: 1 }}></div>

          <div>
            <div className="mood-row">
              {[0, 1, 2, 3, 4].map(i => (
                <button key={i} className={`mood-glyph${i === selected ? ' sel' : ''}`}>
                  <SunGlyph level={i} size={36} />
                </button>
              ))}
            </div>
            <div className="mood-tags">
              {tags.map((t, i) => (
                <span key={i} className={i === selected ? 'sel' : ''}>{t}</span>
              ))}
            </div>
          </div>

          <div style={{ flex: 1 }}></div>

          <button className="cta primary">Suivant</button>
        </div>
        <HIV4 />
      </div>
    </div>
  );
}

// ─── AlarmRinging — aube qui se lève ──────────────────────
function AlarmRingingV4({ mode = 'dark', copy = 0 }) {
  const lines = [
    "Le matin a commencé sans toi.",
    "Bonjour.",
    "L'aube t'a attendue.",
  ];
  return (
    <div className={`phone ${mode}`}>
      <div className="scr">
        <SBV4 time="7:00" />
        <div className="content" style={{ position: 'relative', paddingTop: 0, justifyContent: 'space-between', zIndex: 2 }}>
          <div style={{ paddingTop: 36, textAlign: 'center' }}>
            <div className="eyebrow">Lundi 11 mai</div>
            <div className="serif" style={{ fontSize: 96, lineHeight: 1, fontWeight: 400, letterSpacing: '-0.03em', marginTop: 20 }}>7:00</div>
            <div className="alarm-horizon"></div>
            <div className="serif" style={{ fontSize: 18, lineHeight: 1.4, fontStyle: 'italic', opacity: .7, marginTop: 18, textWrap: 'balance', maxWidth: 280, marginLeft: 'auto', marginRight: 'auto' }}>
              {lines[copy]}
            </div>
          </div>

          <div style={{ flex: 1 }}></div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, position: 'relative', zIndex: 3 }}>
            <button className="cta secondary" style={{ background: 'rgba(255,255,255,.04)', backdropFilter: 'blur(6px)' }}>Snooze 5 min</button>
            <button className="cta primary">Silence</button>
          </div>
        </div>

        {/* Sunrise gradient — rises from bottom over 4s, then breathes */}
        <div className="alarm-sunrise"></div>

        <HIV4 />
      </div>
    </div>
  );
}

Object.assign(window, { Q1MoodV4, AlarmRingingV4, SunGlyph });
