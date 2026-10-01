# Theodore Ball — Mobile Web/PWA handoff

## Goal
Build and host the already-prepared **Mobile Web PWA** version of Theodore Ball so it can be opened on an iPhone in Safari and added to the Home Screen. **Do not implement mobile networking yet.**

## Important project state
This source is already based on the latest cumulative game state used in the previous ChatGPT session:
- 6v6 AI architecture Parts 1–4 are present.
- Shared world model / spatial processor / event-driven significance budgets / multicore tactical path are present.
- Mobile Web compatibility is present.
- Touch gameplay controls are present (virtual movement joystick + SHOT / ABILITY / PASS / CALL / pause).
- Desktop controls remain intact in the canonical project; this handoff archive intentionally omits the bulky GodotSteam addon because the Web build does not use Steam.
- GodotSteam references were made optional/dynamic so the Web project parses without the addon.
- Mobile networking is intentionally disabled/not implemented yet.
- Blue Ridge and Golden Peaks were removed from the selectable maps.
- Lime Stripes remains, including the reduced goal-light intensity from the prior map patch.
- The compact trapezoid scoreboard redesign with aggregate + leg display is present.

## Godot version
Use **Godot 4.7.1 stable**, not another version.

The export preset already exists:
`Mobile Web PWA`

Output path:
`game/mobile_web/index.html`

The preset is intentionally:
- Web / GL Compatibility
- no Web threads (better iPhone/Safari compatibility)
- Progressive Web App enabled
- landscape orientation
- touch/mobile metadata and PWA icons configured
- GodotSteam excluded

## Easiest hosting route
The project now contains `vercel.json` and `ci/build_web.sh`.

Once this project is in a **private GitHub repository**, connect that repo to Vercel and deploy it. Vercel should automatically run:

`bash ci/build_web.sh`

and serve:

`game/mobile_web`

The script downloads the official Godot 4.7.1 Linux editor and the official **web_nothreads_release** export template from Godot's GitHub releases. It first attempts an HTTP-range extraction so it normally does not need to download the entire ~1.3 GB all-platform template archive; it has a full-download fallback.

Vercel HTTPS is sufficient for the PWA. After deployment, on iPhone:
1. Open the Vercel URL in Safari.
2. Rotate to landscape.
3. Share → **Add to Home Screen**.
4. Launch Theodore Ball from the Home Screen.

## Alternative build route
There is also a ready GitHub Actions workflow:
`.github/workflows/build-mobile-web.yml`

It builds on free `ubuntu-latest`, caches Godot + the Web template, and uploads `theodore-ball-mobile-web` as an artifact. No macOS runner is required for a Web build.

## What the next ChatGPT should do
1. Accept this ZIP/project from the user.
2. Do **not** redo the mobile controls or AI optimization architecture.
3. Get the source into the user's correct private GitHub repo (or guide/use a GitHub connector if available).
4. Connect/deploy that repo to Vercel.
5. Inspect the Vercel build logs if export fails and fix only the build/deployment problem.
6. Verify the live URL returns `index.html` and the Godot `.wasm`/`.pck` resources successfully.
7. Give the user the HTTPS URL to open on iPhone.
8. Only after a real-device test should touch layout/performance be tuned.

## Current known limitation
This ChatGPT environment could not resolve `github.com` from its container, so it could not download the official Godot Web template and create the final WASM locally. That is an infrastructure/network limitation, not a project/export-preset error. The build automation in this archive is prepared specifically to finish that step on Vercel/GitHub infrastructure.

## Do not do
- Do not add Nakama/networking yet.
- Do not reintroduce Steam into the Web export.
- Do not use threaded Web export for the first iPhone test.
- Do not lower gameplay physics/input rates just to get the first Web build running.
- Do not regenerate or replace existing game art unnecessarily.
