# Future Ideas — Little Six

**Purpose:** Park raw ideas that have come up during design but are **not in scope** for the current implementation. Each entry records just enough context to evaluate the idea later. Do not implement anything from this document. When an idea is promoted into scope, move it into a real spec and delete it from here.

**Last Updated:** 2026-04-22

---

## Annual Community Forum Page

**Raised:** 2026-04-22 (during spec 011 drafting)
**Status:** Idea only — no requirements, no design, no route reserved.

**Sketch:** A page on the marketing site (Spec 011) dedicated to the real-world Little 500 weekend — for example, collected player stories, tournament results, screenshots, or a once-a-year promotional push timed to IU's Spring Series. Could live at `/forum`, `/community`, or `/weekend`; naming is unresolved.

**Why deferred:** Unclear whether this is user-submitted content, editorially curated, or just a once-a-year static page. All three imply different infrastructure and moderation requirements. The core product (game + marketing site) has to ship first and prove it has an audience before building any community surface.

**Revisit trigger:** After the game has been live for one full Spring Series cycle (so there's actual content and actual players to anchor a community page). Also revisit if a specific partnership with IU or Little 500 organizers materializes.

**Explicit non-requirements for current work:**
- Do **not** add a "Forum" or "Community" link to the navbar.
- Do **not** reserve a route (`/forum`, `/community`) in the static site or CDN config.
- Do **not** add forum-related capability to the postMessage contract or game client.

If this idea is ever promoted, it will get its own spec (likely `spec_012_community_forum.md`).
