// scene-helpers.jsx
// Shared atoms for Lumen Morning animations.
// Loads after animations.jsx, before scene files.

const LUMEN = {
  bg:        '#0F0D0B',
  bgEl:      '#1A1714',
  bgHi:      '#2A241F',
  text:      '#F5EFE6',
  text2:     '#9A8D7D',
  text3:     '#6A5E51',
  accent:    '#E8C39E',
  accentMut: '#A68566',
  divider:   '#2E2822',
  // sunrise palette (alarm)
  sun1: '#1A1410',
  sun2: '#3A2618',
  sun3: '#7A3F2A',
  sun4: '#D88860',
  sun5: '#F5C896',
  sun6: '#FAE6CB',
  // q1 chromatic stops (heavy → light)
  q1Heavy:  '#3B2A4A',
  q1Storm:  '#4F4D5E',
  q1Neutral:'#7A6B5A',
  q1Soft:   '#C4A882',
  q1Bright: '#F5D9A8',
};

const FONTS = {
  serif: '"New York", Charter, "Iowan Old Style", Georgia, serif',
  sans:  '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", system-ui, sans-serif',
  mono:  '"SF Mono", ui-monospace, Menlo, monospace',
};

// ── iPhone frame (simplified, no notch chrome — just the device silhouette)
function PhoneFrame({ x, y, width = 360, height = 780, scale = 1, rotation = 0, opacity = 1, screen, glow = false }) {
  const w = width, h = height;
  return (
    <div style={{
      position: 'absolute',
      left: x, top: y,
      width: w, height: h,
      transform: `translate(-50%, -50%) scale(${scale}) rotate(${rotation}deg)`,
      transformOrigin: 'center',
      opacity,
      willChange: 'transform, opacity',
    }}>
      <div style={{
        position: 'absolute', inset: 0,
        background: '#0a0908',
        borderRadius: w * 0.13,
        boxShadow: glow
          ? `0 30px 80px rgba(232, 195, 158, 0.18), 0 0 0 1.5px rgba(232, 195, 158, 0.25), 0 60px 120px rgba(0,0,0,0.6)`
          : `0 30px 80px rgba(0,0,0,0.5), 0 0 0 1.5px rgba(255,255,255,0.06)`,
      }} />
      <div style={{
        position: 'absolute',
        left: w * 0.025, top: w * 0.025,
        width: w - w * 0.05, height: h - w * 0.05,
        borderRadius: w * 0.105,
        overflow: 'hidden',
        background: LUMEN.bg,
      }}>
        {screen}
      </div>
      {/* dynamic island */}
      <div style={{
        position: 'absolute',
        left: '50%', top: w * 0.05,
        width: w * 0.28, height: w * 0.075,
        marginLeft: -(w * 0.14),
        background: '#000',
        borderRadius: w * 0.04,
      }} />
    </div>
  );
}

// ── Sunrise gradient layer (animated)
function SunriseLayer({ progress, opacity = 1 }) {
  // progress 0..1 maps through sunrise stages
  const stops = [LUMEN.sun1, LUMEN.sun2, LUMEN.sun3, LUMEN.sun4, LUMEN.sun5, LUMEN.sun6];
  // Mix from bottom: at progress 0 → all sun1; at 1 → full gradient sun1→sun6
  const p = clamp(progress, 0, 1);

  const lerpHex = (c1, c2, tt) => {
    const h1 = parseInt(c1.slice(1), 16), h2 = parseInt(c2.slice(1), 16);
    const r1 = (h1 >> 16) & 255, g1 = (h1 >> 8) & 255, b1 = h1 & 255;
    const r2 = (h2 >> 16) & 255, g2 = (h2 >> 8) & 255, b2 = h2 & 255;
    const rr = Math.round(r1 + (r2 - r1) * tt);
    const gg = Math.round(g1 + (g2 - g1) * tt);
    const bb = Math.round(b1 + (b2 - b1) * tt);
    return `rgb(${rr}, ${gg}, ${bb})`;
  };

  // Each band fades in at its own progress threshold
  const bandAt = (idx) => {
    const total = stops.length - 1;
    const startP = idx / total * 0.6;
    const t = clamp((p - startP) / 0.4, 0, 1);
    return lerpHex(stops[0], stops[idx], t);
  };

  const c0 = bandAt(0);
  const c1 = bandAt(1);
  const c2 = bandAt(2);
  const c3 = bandAt(3);
  const c4 = bandAt(4);
  const c5 = bandAt(5);

  // Sun glow position (rises from below)
  const sunY = 100 - p * 70; // % from top, starts at 100% (below), rises to 30%

  return (
    <div style={{
      position: 'absolute', inset: 0,
      opacity,
      background: `linear-gradient(180deg, ${c5} 0%, ${c4} 25%, ${c3} 50%, ${c2} 72%, ${c1} 88%, ${c0} 100%)`,
      overflow: 'hidden',
    }}>
      {/* radial sun glow */}
      <div style={{
        position: 'absolute',
        left: '50%', top: `${sunY}%`,
        width: 800, height: 800,
        marginLeft: -400, marginTop: -400,
        borderRadius: '50%',
        background: `radial-gradient(circle, ${LUMEN.sun6} 0%, ${LUMEN.sun5}aa 25%, ${LUMEN.sun4}55 45%, transparent 70%)`,
        opacity: p * 0.9,
        filter: `blur(${20 - p * 8}px)`,
      }} />
      {/* film grain / atmosphere */}
      <div style={{
        position: 'absolute', inset: 0,
        background: `radial-gradient(ellipse at 50% 60%, transparent 30%, rgba(0,0,0,0.4) 100%)`,
        opacity: 0.6,
      }} />
    </div>
  );
}

// ── Soft caption (cinema-style, bottom of frame)
function Caption({ children, style }) {
  return (
    <div style={{
      position: 'absolute',
      left: '50%', bottom: 80,
      transform: 'translateX(-50%)',
      fontFamily: FONTS.sans,
      fontSize: 13,
      letterSpacing: '0.18em',
      textTransform: 'uppercase',
      color: 'rgba(245, 239, 230, 0.55)',
      whiteSpace: 'nowrap',
      ...style,
    }}>
      {children}
    </div>
  );
}

// ── Eyebrow (small label, top-left)
function Eyebrow({ children, x = 64, y = 64, color }) {
  return (
    <div style={{
      position: 'absolute',
      left: x, top: y,
      fontFamily: FONTS.sans,
      fontSize: 11,
      letterSpacing: '0.2em',
      textTransform: 'uppercase',
      color: color || 'rgba(245, 239, 230, 0.45)',
      fontWeight: 500,
    }}>
      {children}
    </div>
  );
}

// ── Vignette overlay
function Vignette({ opacity = 1, color = '#000' }) {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: `radial-gradient(ellipse at center, transparent 40%, ${color} 100%)`,
      opacity: opacity * 0.6,
      pointerEvents: 'none',
    }} />
  );
}

// ── Letterbox bars (cinematic)
function Letterbox({ progress = 1, height = 80 }) {
  const h = height * progress;
  return (
    <>
      <div style={{
        position: 'absolute', left: 0, right: 0, top: 0, height: h,
        background: '#000', zIndex: 100, pointerEvents: 'none',
      }} />
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0, height: h,
        background: '#000', zIndex: 100, pointerEvents: 'none',
      }} />
    </>
  );
}

// Helper: split a string into words/letters for staggered animation
function StaggeredWords({ text, baseDelay = 0, perWordDelay = 0.08, entryDur = 0.6, style, color = LUMEN.text }) {
  const { localTime } = useSprite();
  const words = text.split(' ');
  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.3em', ...style }}>
      {words.map((w, i) => {
        const start = baseDelay + i * perWordDelay;
        const t = clamp((localTime - start) / entryDur, 0, 1);
        const eased = Easing.easeOutCubic(t);
        return (
          <span key={i} style={{
            display: 'inline-block',
            opacity: eased,
            transform: `translateY(${(1 - eased) * 24}px)`,
            color,
            willChange: 'transform, opacity',
          }}>{w}</span>
        );
      })}
    </div>
  );
}

Object.assign(window, { LUMEN, FONTS, PhoneFrame, SunriseLayer, Caption, Eyebrow, Vignette, Letterbox, StaggeredWords });
