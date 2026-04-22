# Spec 011 — Static Marketing Website & Game Host

**Depends on:** Spec 001 (Project Structure), Spec 006 (AWS Infrastructure)
**Last Updated:** 2026-04-22

---

## Overview

Little Six ships as a Godot web export (HTML5/WASM) embedded inside a small static website. The site has exactly two purposes:

1. **Market the game** — a home page loaded with trailers, screenshots, story, and prominent calls-to-action pointing players into the game.
2. **Host the game** — a full-screen page that renders the Godot canvas edge-to-edge. When the Godot game signals that the player has quit, the host page navigates back to the home page.

The site is built with **plain, idiomatic Bootstrap 5** — server-rendered static HTML, Bootstrap's own components (navbar, hero, card, ratio, modal, button) used the way the Bootstrap docs use them. No SPA framework, no bundler unless strictly needed, no hand-rolled CSS competing with Bootstrap. Any future contributor should be able to read a page and immediately see "this is a Bootstrap site."

The site is served from the same S3 + CloudFront distribution described in Spec 006. No separate infrastructure.

### Persona: "The Idiomatic Bootstrap Author"

When editing files under `web/`, implementers adopt this persona:

- Reaches for Bootstrap utilities and components first; writes custom CSS only when Bootstrap has no equivalent.
- Uses Bootstrap's documented class names verbatim (e.g., `container`, `row`, `col-md-6`, `navbar-expand-lg`, `btn btn-primary btn-lg`, `ratio ratio-16x9`, `card`, `card-body`).
- Favors semantic, standards-compliant HTML5 (`<header>`, `<main>`, `<section>`, `<footer>`, `<nav>`, `<figure>`).
- Mobile-first by default — assumes a phone-sized viewport and lets Bootstrap's grid scale up.
- Does **not** introduce a build step unless a requirement forces it; ships CSS/JS from the Bootstrap CDN with SRI hashes.
- Does **not** introduce jQuery. Bootstrap 5's bundled JS is vanilla and sufficient.

Deviations from this persona require a note in the page's top comment explaining why.

---

## Requirements

### REQ-011-001: Repository Layout

Create a `web/` directory at the repository root with the following structure:

```
web/
├── index.html                 # Home / marketing page
├── play/
│   └── index.html             # Game host page (full-screen Godot canvas)
├── assets/
│   ├── css/
│   │   └── site.css           # Minimal site-specific overrides
│   ├── js/
│   │   ├── play-host.js       # Quit-signal listener, canvas sizing
│   │   └── analytics.js       # Optional: lightweight event pings (stubbed initially)
│   ├── img/
│   │   ├── logo.svg
│   │   ├── hero-still.webp    # Poster frame for hero video
│   │   ├── screenshots/       # In-game screenshots (WebP, 1600×900)
│   │   └── og-card.png        # Open Graph social card (1200×630)
│   └── video/
│       ├── trailer.mp4        # H.264 primary
│       └── trailer.webm       # VP9 fallback
├── game/                      # Populated at build time by Godot web export
│   ├── index.html             # Godot's generated bootstrap (served only when /play/ iframes it; otherwise unused)
│   ├── little_six.js
│   ├── little_six.wasm
│   ├── little_six.pck
│   └── ...                    # All files emitted by the Godot web export
├── 404.html                   # Friendly 404 that links home
├── robots.txt
├── sitemap.xml
└── favicon.ico
```

`web/game/` is **not** checked in. It is produced by `infra/scripts/export-web.sh` (Spec 006 REQ-006-007) and uploaded to S3 alongside the rest of `web/` during deploy.

### REQ-011-002: Technology Choices

- **Bootstrap 5.3.x** loaded from jsDelivr CDN using the official `bootstrap.min.css` and `bootstrap.bundle.min.js`, both pinned with Subresource Integrity (SRI) hashes.
- **No framework** (no React, no Vue, no Svelte, no Next.js).
- **No bundler required.** If a page-specific utility needs a small JS module, ship it as a plain `<script type="module">` from `assets/js/`.
- **Bootstrap Icons** (CDN) for any icon glyphs. No Font Awesome.
- **Fonts:** use the same typefaces the game uses (Press Start 2P for display, Nunito for body — see Spec 007). Load via Google Fonts with `display=swap` and `preconnect`.
- **HTML5** doctype on every page. Pages must validate against the W3C HTML validator.

### REQ-011-003: Home Page (`web/index.html`)

The home page is a single-scroll marketing landing page. Section order, top to bottom:

1. **Navbar** (`<nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top">`)
   - Brand: "LITTLE SIX" in Press Start 2P, Crimson (`#B31B1B`) accent.
   - Links: `#trailer`, `#features`, `#about`, `#faq`.
   - Primary CTA on the right: **"Play Now"** (`btn btn-primary btn-lg`) → `/play/`.

2. **Hero section** (`<section id="hero">` full-viewport-height, dark background)
   - Headline: "The World's Greatest College Weekend." (display-2, Press Start 2P).
   - Subhead: one-sentence pitch (Nunito, lead).
   - Two CTAs side-by-side: primary **"Play Now"** → `/play/`, secondary **"Watch the Trailer"** → scrolls to `#trailer`.
   - Background: looping, muted, autoplay hero video (`hero-loop.mp4`, ~10s) with `hero-still.webp` as poster fallback. Respects `prefers-reduced-motion: reduce` (shows still image only).

3. **Trailer section** (`<section id="trailer">`)
   - Bootstrap `ratio ratio-16x9` wrapper embedding the full trailer with controls (`<video controls preload="metadata" poster=...>`).
   - Short caption below with a **"Play Now"** button.

4. **Features grid** (`<section id="features">`)
   - 2×3 (mobile stacks to 1 column) grid of Bootstrap `card`s. Each card is a pillar: Tamagotchi Training, Real-Time Multiplayer, Spring Series Events, Coaster-Brake Authenticity, Mobile-First, Attract Mode Arcade Feel.
   - Each card: icon, heading, short paragraph, and a small inline CTA ("Jump in →" linking to `/play/`).

5. **Screenshots / gallery** (`<section id="gallery">`)
   - Bootstrap carousel with 4–6 in-game screenshots. Lazy-loaded (`loading="lazy"`).

6. **About the Little 500** (`<section id="about">`)
   - Two-column layout (md: `col-md-6`), body copy on left, archival-style photo or illustration on right.
   - Pulled from README's "Little 500 Tradition" section.

7. **FAQ** (`<section id="faq">`)
   - Bootstrap `accordion` with 4–6 items: "Do I need to install anything?", "Does it work on my phone?", "Is it free?", "Who is this for?", "What's a coaster brake?", "When can I play with friends?".

8. **Final CTA banner** (`<section>` with contrasting background)
   - Single large **"Play Now"** button centered, with a one-liner above it.

9. **Footer** (`<footer class="bg-dark text-light py-5">`)
   - Copyright, credits line, tiny links: Privacy, Credits, Source (GitHub).
   - Tribute line: "A digital tribute to the Little 500."

**CTA rule:** every section from the hero onward must include at least one visible link or button that routes to `/play/`. The navbar CTA is always visible (fixed-top navbar).

**Accessibility:**
- Skip-to-content link at the top.
- Every image has `alt` text.
- Color contrast meets WCAG AA against the dark theme.
- Autoplaying hero video is muted, loops, and is not essential for understanding the page.

### REQ-011-004: Game Host Page (`web/play/index.html`)

The `/play/` page hosts the Godot canvas full-screen. It is intentionally minimal.

**Layout:**
- `<html>` and `<body>` styled with `height: 100%; margin: 0; overflow: hidden; background: #000;`.
- A single `<main id="game-root">` that fills the viewport and contains the Godot bootstrap.
- The Godot web export is embedded directly (not via `<iframe>`) so the `window` reference is shared and `postMessage` / direct JS calls work without cross-origin friction. The export's generated `index.html` is loaded via `<script src="/game/little_six.js">` with the standard Godot `Engine` startup sequence inlined into `play/index.html`.
- No navbar, no footer, no Bootstrap chrome on this page. It imports only the `site.css` variables it needs (background color) and `play-host.js`. Bootstrap is **not required** on `/play/`; keep it out to minimize first paint time.

**Overlays:**
- **Loading overlay**: centered spinner + "Warming up the oval..." while WASM downloads and the engine boots. Hidden once Godot emits its ready signal.
- **"Exit to home" affordance**: a small, unobtrusive back-arrow button fixed top-left, `aria-label="Exit to home"`. Tapping it simulates the in-game quit flow (calls the same handler as REQ-011-006). This exists for users who cannot or do not want to navigate to the in-game quit button; the primary quit path is still inside the game.
- **Orientation hint**: a full-screen overlay ("Rotate your phone sideways to race!") shown when the device is in portrait and the race scene is active. Coordinated with Spec 007 REQ-007-002 — the Godot game emits an orientation-request event; the host can listen and render a native HTML overlay if the browser blocked Godot's orientation lock.

**Performance:**
- Preconnect to the CDN in `<head>`.
- `<link rel="preload" as="fetch" href="/game/little_six.wasm" crossorigin>` to start the WASM download as soon as the HTML parses.
- No blocking third-party scripts on `/play/`.

### REQ-011-005: Godot-to-Host Quit Signal (contract)

When the player quits the game from inside Godot, Godot must notify the hosting web page so the page can navigate back to `/`.

**Transport:** `window.postMessage` on the same-origin `window`. This works both when the Godot canvas is embedded directly (same `window`) and, in a future refactor, if it is ever wrapped in an iframe.

**Message envelope** (canonical — both sides implement this shape):

```json
{
  "source": "little-six-game",
  "version": 1,
  "type": "<event-name>",
  "payload": { /* event-specific, optional */ }
}
```

`source` must always be the string `"little-six-game"` so the host can filter out unrelated messages.

**Events (version 1):**

| `type` | Direction | Payload | Meaning |
|---|---|---|---|
| `ready` | Godot → host | `{}` | Engine booted; hide loading overlay |
| `quit` | Godot → host | `{ "reason": "player_exit" \| "session_end" \| "error", "message"?: string }` | Player has quit or session ended. Host navigates to `/`. |
| `orientation_request` | Godot → host | `{ "orientation": "portrait" \| "landscape" }` | Host may show a rotate-phone overlay if the browser refused to lock orientation. |
| `analytics` | Godot → host | `{ "event": string, "props"?: object }` | Optional telemetry passthrough (stubbed in Phase 1). |
| `host_ack` | Host → Godot | `{ "ack": "<type>" }` | Optional. Host confirms it received a given event. Godot may ignore. |

**Godot-side responsibilities** (cross-reference — the implementing spec for the Godot side is Spec 002; the EventBus signal in Spec 001 is extended to carry this):

- `NetworkManager` (or a new lightweight `HostBridge` autoload) exposes `emit_host_event(type: String, payload: Dictionary = {}) -> void` which calls `JavaScriptBridge.eval` to invoke `window.postMessage({ source: "little-six-game", version: 1, type, payload }, window.location.origin)`.
- On headless/server builds `JavaScriptBridge` is unavailable; calls become no-ops.
- The game emits `quit` whenever:
  - The player confirms the "Leave Race" dialog (Spec 007 REQ-007-009).
  - The player taps a "Quit to Home" button added to the Main Hub settings / pause menu.
  - `GameManager` transitions to a terminal `QUIT` state (new state — add to Spec 001 REQ-001-005 enum).
- Emit `ready` once the first post-boot scene (`Logo.tscn`) has finished its first `_process` tick.

**Host-side responsibilities** (implemented in `web/assets/js/play-host.js`):

```js
window.addEventListener("message", (event) => {
  if (event.origin !== window.location.origin) return;
  const msg = event.data;
  if (!msg || msg.source !== "little-six-game" || msg.version !== 1) return;

  switch (msg.type) {
    case "ready":
      hideLoadingOverlay();
      break;
    case "quit":
      // Give the engine a moment to release audio/WebGL before unloading.
      setTimeout(() => { window.location.href = "/"; }, 150);
      break;
    case "orientation_request":
      renderOrientationHint(msg.payload?.orientation);
      break;
    case "analytics":
      if (window.__analyticsStub) window.__analyticsStub(msg.payload);
      break;
  }
});
```

The host MUST validate `event.origin === window.location.origin`. It MUST NOT act on messages whose `source` is not `"little-six-game"`.

### REQ-011-006: Navigation Flow

- `/` → home marketing page.
- `/play/` → game host page.
- Every "Play Now" CTA points to `/play/`. No query params are required.
- On quit (REQ-011-005), the host sets `window.location.href = "/"`. Do **not** use `history.back()` — it's unreliable when the user deep-linked to `/play/` or refreshed.
- `/play/` must handle direct loads (user typed the URL or was linked in): the game boots normally; no referrer check.
- The home page's in-page anchors (`#features`, `#about`, etc.) must not use `history.pushState`; rely on native anchor scrolling so the Back button behaves intuitively.

### REQ-011-007: Responsive & Mobile Behavior

- **Home page:** mobile-first Bootstrap grid; all sections legible on a 375px-wide viewport without horizontal scroll.
- **Game host page:** always full viewport (`100vw × 100dvh`). Uses `dvh` (dynamic viewport height) so mobile browser chrome doesn't clip the Godot canvas.
- The home page navbar collapses to a hamburger on `< lg` breakpoints (Bootstrap default).
- The home page hero video is replaced by the still image on viewports below 576px to save bandwidth.

### REQ-011-008: SEO & Social Preview

- `<title>` on home: `Little Six — The World's Greatest College Weekend`.
- `<meta name="description">` ≤ 160 chars.
- Open Graph tags: `og:title`, `og:description`, `og:image` (`/assets/img/og-card.png`), `og:url`, `og:type=website`.
- Twitter card: `summary_large_image`.
- `sitemap.xml` listing `/` and `/play/` (both priority 1.0, `changefreq=weekly` for home, `monthly` for play).
- `robots.txt` allows everything except `/game/` (the raw Godot export is not useful to crawlers).
- Structured data: `VideoGame` JSON-LD on the home page.

### REQ-011-009: Analytics (stub)

Phase 1 ships a no-op analytics stub (`assets/js/analytics.js`) that exposes `window.__analyticsStub(event)` and logs to `console.debug`. The hooks exist so swapping in a real provider (Plausible, Umami, GA4) later is a one-file change. No third-party analytics in Phase 1.

### REQ-011-010: Legal & Credits

- `/credits.html` (linked from the footer): lists game credits, fonts, music, the Little 500 attribution, and the list of Bootstrap / Bootstrap Icons / Godot credits.
- `/privacy.html`: one-paragraph privacy statement. Until a real backend account system ships, the statement says "Little Six does not collect personal data. Your progress is stored locally in your browser."
- Both pages use the same Bootstrap chrome as home (navbar + footer) and no hero.

### REQ-011-011: Build & Deploy Integration

- `infra/scripts/export-web.sh` (Spec 006) produces the Godot web export into `dist/web-game/`.
- A new `infra/scripts/build-site.sh`:
  1. Copies `web/` into `dist/site/`.
  2. Copies `dist/web-game/*` into `dist/site/game/`.
  3. Injects the current build version into `dist/site/index.html` and `dist/site/play/index.html` via a `<!-- BUILD:VERSION -->` sentinel comment replaced with the Git short SHA.
  4. Runs `html-validate` against every `.html` file (non-blocking warning in dev, blocking error in CI).
- The CI/CD workflow (Spec 006 REQ-006-007) uploads `dist/site/` to the existing S3 bucket. The CloudFront invalidation path becomes `/index.html`, `/play/index.html`, and `/game/*`.
- The CloudFront response-headers policy from Spec 006 REQ-006-003 already covers COOP/COEP (needed if the Godot export ever moves to threaded WASM). No new headers required for this spec.

### REQ-011-012: Page Weight Budget

- Home page first load: **≤ 500 KB transferred** (excluding hero video). Video is lazy-loaded after first paint.
- Game host page first paint (HTML + CSS + `play-host.js`): **≤ 20 KB transferred**. The WASM/PCK download begins immediately after but does not count against first-paint.

### REQ-011-013: Future / Deferred (not in scope)

The following are explicitly **documented and deferred**. They must not be implemented as part of this spec. See `docs/FUTURE_IDEAS.md`.

- **Annual forum / community page.** A possible future addition is a once-a-year "community forum" page (for example, gathering tournament results or player stories around the real Little 500 weekend). It is an idea only — no requirements, no design, no route reserved. Do not build it.

---

## Data Structures

No persistent data. All state on the website is stateless HTML.

The only runtime "data structure" is the postMessage envelope in REQ-011-005.

---

## Page/Component Hierarchy

### `index.html` (home)

```
<html lang="en" data-bs-theme="dark">
  <head> ... Bootstrap CDN, fonts, OG tags, JSON-LD ... </head>
  <body>
    <a class="visually-hidden-focusable" href="#main">Skip to content</a>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top">...</nav>
    <main id="main">
      <section id="hero"> ... </section>
      <section id="trailer" class="py-5"> ... </section>
      <section id="features" class="py-5 bg-body-tertiary"> ... </section>
      <section id="gallery" class="py-5"> ... </section>
      <section id="about" class="py-5 bg-body-tertiary"> ... </section>
      <section id="faq" class="py-5"> ... </section>
      <section id="cta" class="py-5 text-center"> ... </section>
    </main>
    <footer class="bg-dark text-light py-5"> ... </footer>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.x/dist/js/bootstrap.bundle.min.js" ...></script>
  </body>
</html>
```

### `play/index.html` (game host)

```
<html lang="en">
  <head>
    <title>Little Six — Play</title>
    <link rel="preconnect" href="https://cdn.jsdelivr.net">
    <link rel="preload" as="fetch" href="/game/little_six.wasm" crossorigin>
    <link rel="stylesheet" href="/assets/css/site.css">
  </head>
  <body>
    <main id="game-root">
      <canvas id="godot-canvas" tabindex="0"></canvas>
      <div id="loading-overlay"> ... spinner + caption ... </div>
      <button id="exit-button" class="exit-affordance" aria-label="Exit to home">←</button>
      <div id="orientation-hint" hidden> ... </div>
    </main>
    <script src="/game/little_six.js"></script>
    <script type="module" src="/assets/js/play-host.js"></script>
  </body>
</html>
```

`play-host.js` is responsible for:
- Instantiating the Godot `Engine` against `#godot-canvas`.
- Wiring the `message` listener from REQ-011-005.
- Handling the `#exit-button` click (same path as receiving a `quit` message).

---

## Signal Interface

This spec defines an **external** signal interface (HTML page ↔ Godot engine via `postMessage`), not a Godot `EventBus` signal. See REQ-011-005 for the full event catalog.

Godot-side signals that cross the bridge (added to the `EventBus` in Spec 001 as part of the follow-up):

```
host_event_sent(type: String, payload: Dictionary)
host_event_received(type: String, payload: Dictionary)   # future: host → game
```

---

## Acceptance Criteria

- [ ] `web/index.html` renders without console errors in Safari iOS 15+, Chrome Android 90+, Firefox 115+, desktop Chrome/Safari/Firefox/Edge (latest).
- [ ] Every CTA on the home page routes to `/play/`.
- [ ] The navbar "Play Now" CTA is visible and clickable at every scroll position.
- [ ] Home page Lighthouse scores (mobile): Performance ≥ 90, Accessibility ≥ 95, Best Practices ≥ 95, SEO ≥ 95.
- [ ] Home page first-load transfer (excluding hero video) ≤ 500 KB.
- [ ] `/play/index.html` first-paint transfer ≤ 20 KB.
- [ ] `/play/` boots the Godot game and the canvas fills the viewport on a 375×667 mobile viewport without scrollbars.
- [ ] Godot engine boot triggers a `ready` postMessage; the loading overlay disappears on receipt.
- [ ] Triggering the in-game "Quit" action causes `window.location.href` to become `/` within 500 ms.
- [ ] The host ignores postMessages where `event.origin` mismatches or `source !== "little-six-game"`.
- [ ] Tapping the top-left exit-to-home button on `/play/` navigates to `/` (same path as the Godot-originated quit).
- [ ] Home page and `/play/` both validate as HTML5 (W3C validator, zero errors).
- [ ] Hero video is not requested on viewports < 576px.
- [ ] Hero video is replaced by poster image when `prefers-reduced-motion: reduce` is set.
- [ ] `robots.txt` disallows `/game/`.
- [ ] Open Graph card renders correctly in the Facebook/Twitter/Discord preview debuggers.
- [ ] `docs/FUTURE_IDEAS.md` exists and references the annual forum idea; no forum page, route, or navbar link is implemented.

---

## Implementation Notes

1. **Why Bootstrap, not Tailwind or hand-rolled CSS.** The site is small, marketing-focused, and will be edited infrequently by many hands (human or agent). Bootstrap's out-of-the-box components give an instantly coherent look with zero design work, and the class-name vocabulary is lingua franca.
2. **Why no SPA.** Two pages. Hard navigation between them is fine, matches the user's mental model (marketing → game is a context switch, not a tab switch), and keeps the play page's first-paint budget tight.
3. **Why `postMessage` instead of a global JS function call.** It decouples the game from the host. If we later wrap the game in an iframe (e.g., for embedding on a partner site), the exact same envelope works. It also gives a clean origin-check seam.
4. **Why the host listens for `quit` instead of the game calling `window.location`.** The game should not know about its host's URL structure. The host owns navigation.
5. **Why the exit-to-home button in REQ-011-004 exists alongside the in-game quit.** Mobile users occasionally get stuck in the Godot canvas (e.g., if the game's pause menu fails to render). A host-level escape hatch is good UX insurance.
6. **Why Compatibility renderer is referenced but not re-specified here.** The renderer requirement lives in Spec 001 (REQ-001-001). This spec just assumes the game export is WebGL 2.0 compatible. If Spec 001 changes, nothing in this spec needs to.
7. **Canvas sizing.** Use `ResizeObserver` on `#game-root` in `play-host.js` to call `Engine.requestAnimationFrame` / canvas resize when the viewport changes (landscape rotation is the primary case). Do not rely on Godot's default `full-window` behavior alone — on iOS Safari it occasionally misreads the viewport on orientation change.
8. **Font loading.** Preconnect to `fonts.googleapis.com` and use `font-display: swap`. The hero headline in Press Start 2P can render with a system monospace fallback for the first 100 ms without hurting LCP.
