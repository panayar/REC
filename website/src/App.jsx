import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import './index.css'

function App() {
  return (
    <div className="min-h-screen bg-bg relative overflow-hidden">
      {/* Flowing line that weaves through the page */}
      <FlowingLine />
      <Nav />
      <Hero />
      <DemoSection />
      <Features />
      <HowItWorks />
      <VoiceMode />
      <Download />
      <Footer />
    </div>
  )
}

/* ─── Decorative Text Line ─── */
function FlowingLine() {
  const poem = "Two roads diverged in a yellow wood and sorry I could not travel both and be one traveler long I stood and looked down one as far as I could to where it bent in the undergrowth · Then took the other as just as fair and having perhaps the better claim because it was grassy and wanted wear though as for that the passing there had worn them really about the same · And both that morning equally lay in leaves no step had trodden black Oh I kept the first for another day yet knowing how way leads on to way I doubted if I should ever come back · I shall be telling this with a sigh somewhere ages and ages hence two roads diverged in a wood and I took the one less traveled by and that has made all the difference · "
  const fullText = poem.repeat(6)

  return (
    <div className="absolute inset-0 pointer-events-none z-0 overflow-hidden hidden md:block">
      <svg
        className="absolute top-0 left-0 w-full"
        style={{ height: '100%' }}
        viewBox="0 0 1440 4200"
        preserveAspectRatio="none"
      >
        <defs>
          {/* Path that follows the red line reference:
              starts top-left, goes down left side, sweeps under hero to the right,
              curves around the mockup, makes a loop near features,
              then continues flowing down with big swoops */}
          <path
            id="textRibbon"
            d="M -20 -20
               C -20 100, -30 300, 80 450
               C 200 650, 500 680, 800 680
               C 1100 680, 1400 650, 1600 780
               C 1800 920, 1800 1100, 1500 1150
               C 1200 1200, 1050 1100, 1100 980
               C 1150 860, 1350 840, 1480 940
               C 1620 1040, 1620 1180, 1480 1280
               C 1300 1400, 900 1380, 600 1420
               C 300 1480, 0 1560, -100 1720
               C -200 1900, 100 1950, 500 1920
               C 900 1890, 1300 1920, 1550 2050
               C 1800 2200, 1700 2380, 1350 2380
               C 1000 2380, 600 2340, 300 2450
               C 0 2570, -100 2750, 100 2880
               C 350 3040, 800 2960, 1150 3000
               C 1500 3040, 1750 3140, 1650 3300
               C 1550 3460, 1200 3440, 850 3420
               C 500 3400, 150 3460, -50 3580
               C -250 3700, -50 3820, 300 3840
               C 700 3870, 1100 3820, 1400 3920
               C 1700 4020, 1750 4150, 1500 4200"
          />
        </defs>

        <motion.text
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 2, delay: 0.3 }}
        >
          <textPath
            href="#textRibbon"
            fill="#000000"
            fillOpacity="0.08"
            style={{
              fontFamily: 'Inter, system-ui, sans-serif',
              fontSize: '22px',
              letterSpacing: '3px',
              fontWeight: 300,
            }}
          >
            {fullText}
          </textPath>
        </motion.text>
      </svg>
    </div>
  )
}

/* ─── Nav ─── */
function Nav() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-bg/80 backdrop-blur-xl">
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        <a href="/" aria-label="Rec home" className="flex items-center">
          <img src="/rec-logo-dark.svg" alt="Rec" className="h-10 w-auto" />
        </a>
        <div className="hidden md:flex items-center gap-8 text-[14px] text-text-secondary">
          <a href="#features" className="hover:text-text transition-colors">Features</a>
          <a href="#how" className="hover:text-text transition-colors">How it works</a>
          <a href="#download" className="hover:text-text transition-colors">Download</a>
        </div>
        <a
          href="#download"
          className="text-[13px] font-medium px-5 py-2 rounded-full bg-accent text-white hover:bg-accent-hover transition-colors cursor-pointer"
        >
          Get Started
        </a>
      </div>
    </nav>
  )
}

/* ─── GitHub star count hook ─── */
function useGitHubStars(repo) {
  const [stars, setStars] = useState(null)
  useEffect(() => {
    let cancelled = false
    fetch(`https://api.github.com/repos/${repo}`)
      .then(r => r.ok ? r.json() : null)
      .then(data => {
        if (!cancelled && data && typeof data.stargazers_count === 'number') {
          setStars(data.stargazers_count)
        }
      })
      .catch(() => {})
    return () => { cancelled = true }
  }, [repo])
  return stars
}

function formatStars(n) {
  if (n == null) return null
  if (n >= 1000) return (n / 1000).toFixed(1).replace(/\.0$/, '') + 'k'
  return String(n)
}

/* ─── Hero ─── */
function Hero() {
  const stars = useGitHubStars('panayar/REC')
  return (
    <section className="min-h-screen flex items-center pt-20 md:pt-16 pb-16 px-6 relative z-10">
      <div className="max-w-6xl mx-auto w-full">
        <div className="grid md:grid-cols-2 gap-8 md:gap-12 items-center">
          {/* Left: Copy */}
          <div>
            {/* Badge */}
            <div className="inline-flex items-center gap-2 px-4 md:px-5 py-2 md:py-2.5 rounded-full text-[11px] md:text-[12px] font-medium text-emerald-700 mb-6 md:mb-8 shadow-[0_2px_16px_rgba(34,197,94,0.2),inset_0_1px_1px_rgba(255,255,255,0.6)] bg-gradient-to-b from-emerald-100/80 to-emerald-50/60 border border-emerald-200/50 backdrop-blur-md">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse shadow-[0_0_6px_rgba(34,197,94,0.6)]" />
              Voice Tracking Available
            </div>

            <h1 className="text-[36px] sm:text-[44px] md:text-[56px] font-bold tracking-[-0.03em] leading-[1.08] mb-5 md:mb-6 text-text">
              Prompting for{' '}
              <span className="font-serif italic font-normal">creators</span>{' '}
              on Mac
            </h1>

            <p className="text-[15px] md:text-[17px] text-text-secondary leading-relaxed mb-7 md:mb-8 max-w-md">
              A teleprompter that lives in your Mac's notch. Invisible during screen sharing. Your voice sets the pace.
            </p>

            {/* CTAs */}
            <div className="flex flex-wrap items-center gap-3 mb-10">
              <a
                href="#download"
                className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-accent text-white font-medium hover:bg-accent-hover transition-all cursor-pointer text-[14px]"
              >
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 16l-5-5h3V4h4v7h3l-5 5zm-8 2v2h16v-2H4z"/></svg>
                Download for Mac
              </a>
              <a
                href="https://github.com/panayar/REC"
                target="_blank"
                className="inline-flex items-center gap-2 pl-5 pr-2 py-2 rounded-full border border-border text-text-secondary font-medium hover:text-text hover:border-text-muted transition-all cursor-pointer text-[14px]"
              >
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z"/></svg>
                Star
                <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full bg-surface-2 text-[12px] font-semibold text-text">
                  <svg className="w-3 h-3 text-amber-500" fill="currentColor" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
                  {stars != null ? formatStars(stars) : '—'}
                </span>
              </a>
            </div>

            {/* Social proof */}
            <p className="text-[12px] text-text-muted mb-3">Open source · Trusted by creators</p>
          </div>

          {/* Right: Realistic meeting mockup */}
          <div className="relative flex justify-center overflow-hidden">
            <motion.div
              className="relative origin-top scale-[0.62] sm:scale-[0.78] md:scale-100 -my-[13vh] sm:-my-[6vh] md:my-0"
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.3, ease: [0.16, 1, 0.3, 1] }}
            >
              {/* Mac screen */}
              <div className="w-[540px] rounded-[16px] border border-gray-200 shadow-[0_30px_80px_rgba(0,0,0,0.08),0_0_0_1px_rgba(0,0,0,0.03)] overflow-hidden bg-[#242424]">
                {/* Menu bar */}
                <div className="h-7 bg-[#2c2c2c] flex items-center px-3 relative border-b border-white/5">
                  <div className="flex gap-[6px] items-center">
                    <div className="w-[10px] h-[10px] rounded-full bg-[#ff5f57]" />
                    <div className="w-[10px] h-[10px] rounded-full bg-[#febc2e]" />
                    <div className="w-[10px] h-[10px] rounded-full bg-[#28c840]" />
                  </div>
                  <div className="flex-1 flex justify-center">
                    <div className="flex items-center gap-1.5 bg-white/5 rounded px-2.5 py-0.5">
                      <svg className="w-2.5 h-2.5 text-green-400" fill="currentColor" viewBox="0 0 24 24"><circle cx="12" cy="12" r="8"/></svg>
                      <span className="text-[9px] text-white/50 font-medium">Zoom Meeting — Screen Sharing</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-1">
                    <div className="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse" />
                    <span className="text-[8px] text-red-400 font-medium">REC</span>
                  </div>
                </div>

                {/* Meeting content area */}
                <div className="relative h-[400px] overflow-hidden">
                  {/* Main presentation */}
                  <div className="absolute inset-0 bg-gradient-to-br from-[#1e1e2e] to-[#16161e]">
                    {/* Slide — chart at bottom so it's visible below teleprompter */}
                    <div className="absolute inset-4 bg-white rounded-xl overflow-hidden flex flex-col justify-end">
                      {/* Slide header — top */}
                      <div className="px-6 pt-4 pb-2 absolute top-0 left-0 right-0">
                        <span className="text-[8px] text-gray-400 uppercase tracking-[0.15em]">Quarterly Business Review</span>
                        <div className="text-gray-900 text-[15px] font-semibold tracking-tight">Revenue Growth Overview</div>
                      </div>

                      {/* Chart — bottom half */}
                      <div className="px-5 pb-3 flex gap-2">
                        {/* Y axis */}
                        <div className="flex flex-col justify-between text-[6px] text-gray-300 shrink-0">
                          <span>$4M</span>
                          <span>$2M</span>
                          <span>$0</span>
                        </div>

                        {/* Bars */}
                        <div className="flex-1 flex items-end gap-2 border-l border-b border-gray-100 pl-2 pb-4 h-[70px]">
                          {[
                            { h: 20, label: 'Jan' },
                            { h: 28, label: 'Feb' },
                            { h: 25, label: 'Mar' },
                            { h: 38, label: 'Apr' },
                            { h: 48, label: 'May' },
                            { h: 42, label: 'Jun' },
                            { h: 62, label: 'Jul', highlight: true },
                          ].map((bar, i) => (
                            <div key={i} className="flex-1 flex flex-col items-center justify-end h-full relative">
                              <motion.div
                                className={`w-full max-w-[22px] rounded-t-sm ${bar.highlight ? 'bg-gradient-to-t from-blue-600 to-blue-400' : 'bg-gradient-to-t from-blue-300/80 to-blue-200/60'}`}
                                initial={{ height: 0 }}
                                animate={{ height: bar.h }}
                                transition={{ delay: 0.8 + i * 0.12, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
                              />
                              <span className={`text-[6px] absolute -bottom-3.5 ${bar.highlight ? 'text-blue-600 font-bold' : 'text-gray-300'}`}>{bar.label}</span>
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Stats row */}
                      <div className="px-5 pb-3 flex gap-5">
                        <div>
                          <div className="text-[6px] text-gray-400">Total Revenue</div>
                          <div className="text-[11px] font-bold text-gray-900">$15.9M</div>
                        </div>
                        <div>
                          <div className="text-[6px] text-gray-400">Growth</div>
                          <div className="text-[11px] font-bold text-emerald-600">+32%</div>
                        </div>
                        <div>
                          <div className="text-[6px] text-gray-400">Best Month</div>
                          <div className="text-[11px] font-bold text-blue-600">July</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Meeting toolbar — bottom */}
                  <div className="absolute bottom-0 left-0 right-0 h-12 bg-[#1a1a1a] border-t border-white/5 flex items-center justify-center gap-3 px-4">
                    {[
                      { icon: 'M12 18.75a6 6 0 006-6v-1.5m-6 7.5a6 6 0 01-6-6v-1.5m6 7.5v3.75m-3.75 0h7.5M12 15.75a3 3 0 01-3-3V4.5a3 3 0 116 0v8.25a3 3 0 01-3 3z', active: true },
                      { icon: 'M15.75 10.5l4.72-4.72a.75.75 0 011.28.53v11.38a.75.75 0 01-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 002.25-2.25v-9a2.25 2.25 0 00-2.25-2.25h-9A2.25 2.25 0 002.25 7.5v9a2.25 2.25 0 002.25 2.25z', active: true },
                      { icon: 'M9 8.25H7.5a2.25 2.25 0 00-2.25 2.25v9a2.25 2.25 0 002.25 2.25h9a2.25 2.25 0 002.25-2.25v-9a2.25 2.25 0 00-2.25-2.25H15M9 12l3 3m0 0l3-3m-3 3V2.25', active: false },
                    ].map((btn, i) => (
                      <div key={i} className={`w-8 h-8 rounded-full flex items-center justify-center ${btn.active ? 'bg-white/10' : 'bg-green-500/20'}`}>
                        <svg className={`w-3.5 h-3.5 ${btn.active ? 'text-white/60' : 'text-green-400'}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d={btn.icon} /></svg>
                      </div>
                    ))}
                    <div className="w-8 h-8 rounded-full bg-red-500/90 flex items-center justify-center ml-2">
                      <svg className="w-3.5 h-3.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
                    </div>
                  </div>

                  {/* Participants — Zoom style: bottom right */}
                  <div className="absolute bottom-14 right-3 flex flex-col gap-2">
                    {[
                      { name: 'Sarah K.', img: '/avatar1.jpg' },
                      { name: 'Mike R.', img: '/avatar2.jpg' },
                      { name: 'You', img: '/avatar3.jpg', you: true },
                    ].map((p, i) => (
                      <motion.div
                        key={i}
                        className={`w-[104px] h-[76px] rounded-xl bg-[#2a2a2a] flex flex-col items-center justify-center relative overflow-hidden border border-white/5`}
                        initial={{ opacity: 0, x: 20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 1.2 + i * 0.15 }}
                      >
                        {/* Circle avatar centered with green ring for You */}
                        <div className={`relative mb-1 ${p.you ? '' : ''}`}>
                          <div className={`w-11 h-11 rounded-full overflow-hidden ${p.you ? 'border-2 border-emerald-400' : 'border-2 border-white/10'}`}>
                            <img src={p.img} alt={p.name} className="w-full h-full object-cover" />
                          </div>
                          {p.you && (
                            <motion.div
                              className="absolute -inset-1.5 rounded-full border border-emerald-400/50"
                              animate={{ scale: [1, 1.15, 1], opacity: [0.5, 0, 0.5] }}
                              transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
                            />
                          )}
                        </div>
                        {/* Name */}
                        <span className={`text-[9px] font-medium ${p.you ? 'text-emerald-300' : 'text-white/40'}`}>{p.name}</span>


                        {/* Mic icon for others */}
                        {!p.you && (
                          <div className="absolute top-1.5 right-1.5">
                            <svg className="w-3 h-3 text-white/20" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M12 18.75a6 6 0 006-6v-1.5m-6 7.5a6 6 0 01-6-6v-1.5m6 7.5v3.75m-3.75 0h7.5M12 15.75a3 3 0 01-3-3V4.5a3 3 0 116 0v8.25a3 3 0 01-3 3z" /></svg>
                          </div>
                        )}
                      </motion.div>
                    ))}
                  </div>

                  {/* ─── Teleprompter overlay (only you see this) ─── */}
                  <motion.div
                    className="flex justify-center absolute top-0 left-0 right-0 z-20"
                    initial={{ y: -100, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: 1.5, duration: 0.5, type: 'spring', damping: 20 }}
                  >
                    <div className="w-[260px] bg-black rounded-b-[20px] pt-3 px-4 pb-4 shadow-[0_15px_50px_rgba(0,0,0,0.7)]">
                      <SyncedTeleprompter />
                    </div>
                  </motion.div>

                  {/* "Only you" pill — very top */}
                  <motion.div
                    className="absolute top-1 right-3 z-30"
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 2.2, duration: 0.4 }}
                  >
                    <div className="bg-black/60 backdrop-blur-xl rounded-full px-3 py-1.5 flex items-center gap-1.5 border border-white/10 shadow-lg">
                      <svg className="w-3 h-3 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.64 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.64 0-8.573-3.007-9.963-7.178z" /><path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                      <span className="text-[9px] text-white/80 font-medium">Only you see this</span>
                    </div>
                  </motion.div>
                </div>
              </div>

              {/* Floating stealth badge */}
              <motion.div
                className="absolute -bottom-5 -left-5 bg-white rounded-2xl shadow-lg border border-border px-4 py-3 flex items-center gap-3"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 2.5, duration: 0.5 }}
              >
                <div className="w-8 h-8 rounded-full bg-emerald-50 flex items-center justify-center">
                  <svg className="w-4 h-4 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12c1.292 4.338 5.31 7.5 10.066 7.5.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" /></svg>
                </div>
                <div>
                  <p className="text-[11px] font-semibold text-text">Stealth Mode</p>
                  <p className="text-[10px] text-text-muted">Hidden from sharing</p>
                </div>
              </motion.div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  )
}

/* ─── Features ─── */
function Features() {
  const features = [
    {
      img: '/icon-monitor.png',
      title: 'Dynamic Island',
      desc: 'Expands from your Mac\'s notch with a fluid spring animation.',
    },
    {
      img: '/icon-mic.png',
      title: 'Voice Tracking',
      desc: 'Words highlight as you speak. Powered by Apple Speech + Whisper AI.',
    },
    {
      img: '/icon-eye.png',
      title: 'Stealth Mode',
      desc: 'Invisible during screen sharing, video calls, and screenshots.',
    },
    {
      img: '/icon-doc.png',
      title: 'Script Manager',
      desc: 'Notion-style editor with auto-titles and drag-and-drop import.',
    },
    {
      img: '/icon-phone.png',
      title: 'Remote Control',
      desc: 'Control from your phone via QR code. No app needed.',
    },
    {
      img: '/icon-mirror.png',
      title: 'Mirror Mode',
      desc: 'Flip text for beam-splitter teleprompter hardware.',
    },
  ]

  return (
    <section id="features" className="py-16 md:py-24 px-6 relative z-10">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-[13px] text-text-muted uppercase tracking-widest mb-3">Features</p>
          <h2 className="text-[28px] sm:text-[36px] md:text-[44px] font-bold tracking-[-0.03em] leading-tight">
            We keep details{' '}
            <span className="font-serif italic font-normal">strong</span> and simple
          </h2>
        </div>

        {/* Bento grid */}
        <div className="grid grid-cols-1 md:grid-cols-12 gap-3">
          {/* Dynamic Island — with notch visual */}
          <motion.div
            className="group md:col-span-7 rounded-3xl bg-white border border-border hover:shadow-xl transition-all duration-500 cursor-default overflow-hidden"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
          >
            <div className="p-6 pb-0 text-center">
              <h3 className="text-[30px] font-bold mb-2 text-text tracking-tight">{features[0].title}</h3>
              <p className="text-[16px] text-text-secondary leading-relaxed mx-auto max-w-[360px]">{features[0].desc}</p>
            </div>
            {/* Notch mockup — transparent background, bigger */}
            <div className="mt-6 mb-6 h-[240px] relative overflow-hidden">
              <div className="flex justify-center">
                <motion.div
                  className="bg-black rounded-b-[26px] px-7 pt-4 pb-6"
                  initial={{ width: 144, height: 34 }}
                  whileInView={{ width: 384, height: 156 }}
                  viewport={{ once: true }}
                  transition={{ delay: 0.5, duration: 0.7, type: 'spring', damping: 15 }}
                >
                  <div className="flex items-center gap-1.5 mb-3 opacity-80">
                    {[0, 1, 2].map(i => (
                      <motion.div
                        key={i}
                        className="w-[5px] h-[5px] rounded-full bg-emerald-400"
                        animate={{ opacity: [0.3, 1, 0.3] }}
                        transition={{ duration: 1.2, delay: i * 0.2, repeat: Infinity }}
                      />
                    ))}
                    <span className="text-[11px] text-emerald-400/60 ml-1">Listening</span>
                  </div>
                  <p className="text-[13px] leading-[1.6] text-center">
                    <span className="text-emerald-400">As you can see in the chart, our </span>
                    <span className="text-white font-medium">revenue </span>
                    <span className="text-white/20">grew 32% quarter over quarter driven by strong adoption...</span>
                  </p>
                </motion.div>
              </div>
            </div>
          </motion.div>

          {/* Voice Tracking — dark, centered vertical */}
          <motion.div
            className="group md:col-span-5 rounded-3xl bg-[#111] text-white border border-gray-800 hover:shadow-xl transition-all duration-500 cursor-default overflow-hidden relative"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
          >
            <div className="p-6 pb-4 text-center relative z-10">
              <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-500/10 text-emerald-400 text-[10px] font-medium mb-3">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                AI Powered
              </div>
              <h3 className="text-[30px] font-bold mb-2 tracking-tight">{features[1].title}</h3>
              <p className="text-[16px] text-white/50 leading-relaxed mx-auto max-w-[260px]">{features[1].desc}</p>
            </div>
            <div className="flex justify-center pb-5">
              <img
                src={features[1].img}
                alt={features[1].title}
                className="w-44 h-44 object-contain drop-shadow-xl group-hover:scale-110 transition-transform duration-500"
              />
            </div>
          </motion.div>

          {/* Bottom 3 cards */}
          {[2, 3, 4].map((idx, i) => (
            <motion.div
              key={idx}
              className="group md:col-span-4 rounded-3xl bg-white border border-border hover:shadow-xl transition-all duration-500 cursor-default overflow-hidden"
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.2 + i * 0.1 }}
            >
              <div className="p-5 flex items-center gap-4 h-full">
                <div className="flex-1 min-w-0">
                  <h3 className="text-[18px] font-bold mb-1.5 text-text tracking-tight">{features[idx].title}</h3>
                  <p className="text-[13px] text-text-secondary leading-relaxed">{features[idx].desc}</p>
                </div>
                <img
                  src={features[idx].img}
                  alt={features[idx].title}
                  className="w-20 h-20 shrink-0 object-contain drop-shadow-lg group-hover:scale-110 transition-transform duration-500"
                />
              </div>
            </motion.div>
          ))}

          {/* Mirror Mode — full width */}
          <motion.div
            className="group md:col-span-12 rounded-3xl bg-surface-2 border border-border hover:shadow-xl transition-all duration-500 cursor-default overflow-hidden"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.5 }}
          >
            <div className="p-5 flex items-center justify-center gap-5">
              <div>
                <h3 className="text-[18px] font-bold mb-1 text-text tracking-tight">{features[5].title}</h3>
                <p className="text-[13px] text-text-secondary leading-relaxed">{features[5].desc}</p>
              </div>
              <img src={features[5].img} alt={features[5].title} className="w-16 h-16 shrink-0 object-contain drop-shadow-md group-hover:scale-110 group-hover:-rotate-3 transition-transform duration-500" />
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}

/* ─── Scroll-triggered Video (starts 1.5s after it enters view) ─── */
function InViewVideo({ src, muted, className }) {
  const ref = useRef(null)

  useEffect(() => {
    const video = ref.current
    if (!video) return

    let timeoutId = null

    const observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0]
        if (entry.isIntersecting) {
          timeoutId = setTimeout(() => {
            video.play().catch(() => {})
          }, 1500)
        } else {
          clearTimeout(timeoutId)
          video.pause()
          video.currentTime = 0
        }
      },
      { threshold: 0.4 }
    )

    observer.observe(video)
    return () => {
      observer.disconnect()
      clearTimeout(timeoutId)
    }
  }, [])

  return (
    <video
      ref={ref}
      src={src}
      loop
      muted={muted}
      playsInline
      preload="metadata"
      className={className}
    />
  )
}

/* ─── Sound Toggle Button ─── */
function SoundToggle({ muted, onToggle }) {
  return (
    <button
      onClick={onToggle}
      aria-label={muted ? 'Unmute' : 'Mute'}
      className="absolute bottom-4 right-4 z-10 w-10 h-10 rounded-full bg-black/60 backdrop-blur-md border border-white/15 text-white flex items-center justify-center hover:bg-black/80 transition-colors cursor-pointer"
    >
      {muted ? (
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M17.25 9.75L19.5 12m0 0l2.25 2.25M19.5 12l2.25-2.25M19.5 12l-2.25 2.25m-10.5-6l4.72-4.72a.75.75 0 011.28.53v15.88a.75.75 0 01-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.01 9.01 0 012.25 12c0-.83.112-1.633.322-2.396C2.806 8.757 3.63 8.25 4.51 8.25H6.75z" />
        </svg>
      ) : (
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M19.114 5.636a9 9 0 010 12.728M16.463 8.288a5.25 5.25 0 010 7.424M6.75 8.25l4.72-4.72a.75.75 0 011.28.53v15.88a.75.75 0 01-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.01 9.01 0 012.25 12c0-.83.112-1.633.322-2.396C2.806 8.757 3.63 8.25 4.51 8.25H6.75z" />
        </svg>
      )}
    </button>
  )
}

/* ─── Demo Section ─── */
function DemoSection() {
  const videoRef = useRef(null)
  const [muted, setMuted] = useState(true)
  return (
    <section className="py-16 md:py-24 px-6 relative z-10">
      <div className="max-w-3xl mx-auto">
        <div className="text-center mb-12">
          <p className="text-[13px] text-text-muted uppercase tracking-widest mb-3">See it in action</p>
          <h2 className="text-[28px] sm:text-[36px] md:text-[44px] font-bold tracking-[-0.03em] leading-tight">
            Watch Rec{' '}
            <span className="font-serif italic font-normal">come alive</span>
          </h2>
          <p className="text-[15px] text-text-secondary mt-4 max-w-md mx-auto">
            From notch to teleprompter in one click. See how it looks during a real presentation.
          </p>
        </div>

        {/* Demo container */}
        <motion.div
          className="relative rounded-3xl overflow-hidden border border-border bg-white shadow-[0_20px_80px_rgba(0,0,0,0.06)]"
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
        >
          <div className="bg-black relative flex items-center justify-center">
            <InViewVideo
              src="/manual-demo.mp4"
              muted={muted}
              className="w-full h-auto block"
            />
            <SoundToggle muted={muted} onToggle={() => setMuted(m => !m)} />
          </div>

          {/* Caption bar */}
          <div className="px-6 py-4 border-t border-border flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-2 h-2 rounded-full bg-green animate-pulse" />
              <span className="text-[13px] text-text-secondary">Manual mode — notch teleprompter in action</span>
            </div>
            <span className="text-[12px] text-text-muted">macOS 14+</span>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

/* ─── How It Works ─── */
function HowItWorks() {
  const steps = [
    {
      num: '1',
      title: 'Write your script',
      desc: 'Type or paste your text. The first line becomes the title, just like Notes.',
    },
    {
      num: '2',
      title: 'Hit play',
      desc: 'The teleprompter expands from your notch with a smooth Dynamic Island animation.',
    },
    {
      num: '3',
      title: 'Read & record',
      desc: 'Your text scrolls automatically or follows your voice. Invisible to everyone else.',
    },
  ]

  return (
    <section id="how" className="py-24 px-6 bg-white/80 backdrop-blur-sm relative z-10">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-[13px] text-text-muted uppercase tracking-widest mb-3">How it works</p>
          <h2 className="text-[28px] sm:text-[36px] md:text-[44px] font-bold tracking-[-0.03em] leading-tight">
            Three steps to{' '}
            <span className="font-serif italic font-normal">read naturally</span>
          </h2>
        </div>

        <div className="grid md:grid-cols-3 gap-8 pt-10">
          {steps.map((s, i) => {
            const shapes = [
              'rounded-tl-[64px] rounded-tr-2xl rounded-br-[64px] rounded-bl-2xl',
              'rounded-tl-2xl rounded-tr-[64px] rounded-br-2xl rounded-bl-[64px]',
              'rounded-tl-[64px] rounded-tr-2xl rounded-br-[64px] rounded-bl-2xl',
            ]
            const tilts = ['md:-rotate-1', 'md:rotate-1', 'md:-rotate-1']
            return (
              <div
                key={i}
                className={`relative p-10 pt-12 text-center bg-gradient-to-br from-white to-surface-2 border border-border-light shadow-sm hover:shadow-md transition-all hover:-translate-y-1 ${shapes[i]} ${tilts[i]}`}
              >
                <div className="absolute -top-7 -left-5 w-16 h-16 rounded-2xl bg-gradient-to-br from-gray-900 to-gray-700 text-white flex items-center justify-center text-[28px] font-bold shadow-lg shadow-gray-400/40 rotate-6">
                  {s.num}
                </div>
                <h3 className="text-[22px] font-semibold mb-3 text-text tracking-tight">{s.title}</h3>
                <p className="text-[14px] text-text-secondary leading-relaxed">{s.desc}</p>
              </div>
            )
          })}
        </div>

        {/* Quote */}
        <div className="mt-16 max-w-2xl mx-auto bg-white rounded-2xl border border-border p-8 shadow-sm">
          <div className="text-[28px] text-text-muted leading-none mb-4 font-serif">"</div>
          <p className="text-[16px] text-text leading-relaxed mb-6 font-serif italic">
            Rec was built with a mission: turn your Mac's notch into the most useful space on your screen.
          </p>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-surface-2 flex items-center justify-center">
              <img src="/app-icon.png" alt="" className="w-6 h-6 rounded" />
            </div>
            <div>
              <p className="text-[13px] font-semibold text-text">Rec Team</p>
              <p className="text-[11px] text-text-muted">Open Source</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

/* ─── Voice Mode ─── */
function VoiceMode() {
  const [muted, setMuted] = useState(true)
  return (
    <section id="voice" className="py-16 md:py-24 px-6 relative z-10">
      <div className="max-w-6xl mx-auto">
        {/* Editorial header — left-aligned instead of centered stack */}
        <div className="flex flex-col md:flex-row md:items-end md:justify-between mb-12 gap-4">
          <div className="max-w-xl">
            <p className="text-[11px] text-text-muted uppercase tracking-[0.2em] mb-4 font-medium">— Voice tracking</p>
            <h2 className="text-[32px] sm:text-[40px] md:text-[52px] font-bold tracking-[-0.03em] leading-[1.05]">
              Reads along<br />
              <span className="font-serif italic font-normal text-text-secondary">with your voice.</span>
            </h2>
          </div>
          <p className="text-[15px] text-text-secondary leading-relaxed max-w-sm">
            Words turn green the moment you say them. The scroll follows your pace — not a preset speed.
          </p>
        </div>

        {/* Bento: big live demo + stacked facts */}
        <div className="grid md:grid-cols-12 gap-4">
          {/* Live demo — real video */}
          <div className="md:col-span-7 rounded-3xl bg-black relative overflow-hidden flex items-center justify-center">
            <InViewVideo
              src="/voice-demo.mp4"
              muted={muted}
              className="w-full h-auto block"
            />
            {/* Overlay pill */}
            <div className="absolute top-5 left-5 flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-black/60 backdrop-blur-md border border-white/10 z-10">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-[10px] font-medium text-emerald-300">Live · voice tracking</span>
            </div>
            <SoundToggle muted={muted} onToggle={() => setMuted(m => !m)} />
          </div>

          {/* Right column: two facts */}
          <div className="md:col-span-5 grid gap-4">
            {/* Private */}
            <div className="rounded-3xl bg-surface-2 border border-border-light p-8 relative overflow-hidden">
              <div className="flex items-start justify-between mb-6">
                <div className="text-[52px] sm:text-[64px] font-bold tracking-[-0.05em] leading-none text-text">100<span className="text-[22px] sm:text-[28px] align-top text-text-secondary">%</span></div>
                <svg className="w-6 h-6 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
                </svg>
              </div>
              <h3 className="text-[18px] font-semibold mb-1 tracking-tight">On-device.</h3>
              <p className="text-[13px] text-text-secondary leading-relaxed">
                Audio never leaves your Mac. Apple Speech + Whisper run locally. Nothing sent to any server.
              </p>
            </div>

            {/* Languages */}
            <div className="rounded-3xl bg-surface-2 border border-border-light p-8 relative overflow-hidden">
              <div className="flex flex-wrap gap-1.5 mb-5">
                {['English', 'Español', '日本語', 'Français', 'Deutsch', '中文', 'Português'].map((lang, i) => (
                  <span
                    key={i}
                    className="text-[11px] px-2.5 py-1 rounded-full bg-white border border-border-light text-text-secondary"
                  >
                    {lang}
                  </span>
                ))}
                <span className="text-[11px] px-2.5 py-1 rounded-full bg-text text-white">+more</span>
              </div>
              <h3 className="text-[18px] font-semibold mb-1 tracking-tight">Any language.</h3>
              <p className="text-[13px] text-text-secondary leading-relaxed">
                Follows your system locale. Switch language and it keeps up.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

/* ─── Download ─── */
function Download() {
  return (
    <section id="download" className="py-16 md:py-24 px-6 relative z-10">
      <div className="max-w-3xl mx-auto text-center">
        <img src="/app-icon.png" alt="Rec" className="w-20 h-20 mx-auto mb-6 rounded-2xl shadow-lg" />
        <h2 className="text-[28px] sm:text-[36px] md:text-[44px] font-bold tracking-[-0.03em] leading-tight mb-4">
          Ready to read{' '}
          <span className="font-serif italic font-normal">naturally?</span>
        </h2>
        <p className="text-[15px] text-text-secondary max-w-md mx-auto mb-8">
          Free, open source, and built for macOS. Works on MacBooks with or without a notch.
        </p>
        <div className="flex items-center justify-center gap-4 mb-4">
          <a
            href="/Rec.dmg"
            className="inline-flex items-center gap-2 px-8 py-3.5 rounded-full bg-accent text-white font-semibold hover:bg-accent-hover transition-all cursor-pointer text-[14px]"
          >
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 16l-5-5h3V4h4v7h3l-5 5zm-8 2v2h16v-2H4z"/></svg>
            Download .dmg
          </a>
          <a
            href="https://github.com/panayar/REC"
            target="_blank"
            className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full border border-border text-text-secondary font-medium hover:text-text hover:border-text-muted transition-all cursor-pointer text-[14px]"
          >
            View Source
          </a>
        </div>
        <p className="text-[12px] text-text-muted mb-10">v1.0 · macOS 14+ · Apple Silicon & Intel</p>

        {/* First-launch instructions */}
        <div className="text-left max-w-xl mx-auto bg-surface-2 border border-border-light rounded-2xl p-6">
          <div className="flex items-center gap-2 mb-3">
            <svg className="w-4 h-4 text-text-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
            </svg>
            <h3 className="text-[13px] font-semibold text-text">First launch on macOS</h3>
          </div>
          <p className="text-[12px] text-text-secondary leading-relaxed mb-3">
            Rec is open-source and not yet notarized, so macOS will show a warning the first time you open it. This is normal — here's how to open it:
          </p>
          <ol className="text-[12px] text-text-secondary leading-relaxed space-y-1.5 list-decimal pl-5">
            <li>Drag <span className="font-mono text-text">Rec.app</span> to your Applications folder.</li>
            <li><strong>Right-click</strong> (or Ctrl-click) on <span className="font-mono text-text">Rec.app</span> → <strong>Open</strong>.</li>
            <li>In the warning dialog, click <strong>Open</strong> again.</li>
            <li>Done — macOS remembers your choice for future launches.</li>
          </ol>
        </div>
      </div>
    </section>
  )
}

/* ─── Footer ─── */
function Footer() {
  return (
    <footer className="border-t border-border py-10 px-6">
      <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <img src="/rec-logo-dark.svg" alt="Rec" className="h-6 w-auto" />
          <span className="text-[12px] text-text-muted">A teleprompter for your Mac's notch</span>
        </div>
        <div className="flex items-center gap-6 text-[13px] text-text-muted">
          <a href="https://github.com/panayar/REC" target="_blank" className="hover:text-text transition-colors cursor-pointer">GitHub</a>
          <a href="#" className="hover:text-text transition-colors cursor-pointer">Privacy</a>
          <span>© 2026</span>
        </div>
      </div>
    </footer>
  )
}

/* ─── Synced Teleprompter + Waveform ─── */
function SyncedTeleprompter() {
  const words = [
    'As', 'you', 'can', 'see', 'in', 'the', 'chart,', 'our',
    'revenue', 'grew', '32%', 'quarter', 'over', 'quarter,',
    'driven', 'by', 'strong', 'enterprise', 'adoption', 'in',
    'July.', "Let's", 'dive', 'into', 'the', 'key', 'metrics.'
  ]

  const [activeIndex, setActiveIndex] = useState(0)
  const [speaking, setSpeaking] = useState(false)

  useEffect(() => {
    // Simulate natural speech: vary timing per word
    const baseSpeed = 800
    const tick = () => {
      setActiveIndex(prev => {
        const next = (prev + 1) % words.length
        const word = words[prev]
        const hasPause = word.endsWith('.') || word.endsWith(',')
        setSpeaking(true)
        setTimeout(() => setSpeaking(false), 400)
        return next
      })
    }
    const interval = setInterval(tick, baseSpeed + Math.random() * 300)
    return () => clearInterval(interval)
  }, [])

  return (
    <>
      {/* Voice chip */}
      <div className="flex items-center justify-between mb-2.5">
        <div className="flex items-center gap-1.5">
          {/* Listening dots — bouncing wave */}
          <div className="flex items-end gap-[2px] h-3">
            {[0, 1, 2].map((i) => (
              <motion.div
                key={i}
                className="w-[4px] h-[4px] rounded-full bg-emerald-400"
                animate={{ y: [0, -4, 0] }}
                transition={{
                  duration: 1,
                  delay: i * 0.25,
                  repeat: Infinity,
                  repeatDelay: 0.6,
                  ease: [0.4, 0, 0.2, 1],
                }}
              />
            ))}
          </div>
          <span className="text-[8px] text-emerald-400 font-medium">Listening</span>
        </div>
        <motion.span
          className="text-[7px] text-emerald-400/40"
          animate={{ opacity: activeIndex === 0 ? 1 : 0 }}
        >
          Speak now
        </motion.span>
      </div>

      {/* Animated text */}
      <p className="text-[12px] leading-[1.9] text-center">
        {words.map((word, i) => (
          <motion.span
            key={i}
            animate={{
              color: i < activeIndex
                ? 'rgb(52, 211, 153)'
                : i === activeIndex
                ? 'rgb(255, 255, 255)'
                : 'rgba(255, 255, 255, 0.15)',
              scale: i === activeIndex ? 1.05 : 1,
            }}
            transition={{ duration: 0.15 }}
            style={{ display: 'inline' }}
          >
            {word}{' '}
          </motion.span>
        ))}
      </p>
    </>
  )
}

export default App
