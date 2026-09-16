---
name: product-film-craft
description: How to make product/demo films that feel alive instead of flat — structure, rhythm, motion parameters, type kinetics, UI choreography, sound, and the honesty rules, distilled from the genre's canon (Linear, Amie, Apple, Ordinary Folk, Algo) and motion-design literature into implementable numbers for code-rendered video (Remotion). Load this BEFORE scripting, directing, building, or reviewing any product film, demo video, launch clip, hero loop, or motion piece. Pairs with eigendesk-design-language for this app's register.
---

# Product film craft

The core diagnosis behind every boring product film: **uniform rhythm** (one pace, one easing,
one visual field = a metronome, not a pulse), **polite motion** (opacity fades, gentle
ease-out everywhere), **dead pixels** (static screenshots in a moving film), and **a feature
brief** ("here's what it does") where a story brief belonged ("here's the customer's day,
before and after"). Fix those four before touching any technique below.

## 1. The brief test (boring is a brief problem first)

- One film = ONE claim, dramatized. If the brief lists features, rewrite the brief.
- Choose the motion ENERGY from the product's claim, never from a style library: fast because
  the product is fast; calm because the product resolves chaos. Calm still needs contrast to
  register as calm.
- If the format will recur (release films, monthly recaps), build a parametrized system, not a
  bespoke comp (the Algo/Family lesson).

## 2. Structure

- Hook 0-30% (front-loaded attention), build 30-70%, ONE hit moment (the film's single visual
  peak — spend anticipation + blur + light-sweep + sound TOGETHER there and nowhere else),
  resolve/CTA last 10-15%.
- Baseline shot length 4-6s; the alive pattern is short-short-short-LONG, never constant.
- At least one TRUE stillness hold (nothing animating, 1-2s) adjacent to the hit moment.
  Continuous motion reads as anxious; the zero is what makes the fast parts fast.
- A held shot stays alive by reframing INSIDE the hold (drift, push), not by cutting away.
- Openings: cold-open on product motion for audiences who know the category; problem-staging
  type card for audiences who do not. Zero seconds of brand preamble either way.

## 3. The beat grid

- Pick a BPM; `framesPerBeat = round((60/bpm) * fps)`. Snap every cut and sequence boundary to
  the grid. Cut 1-2 frames EARLY on energetic sections (reads crisp), on-grid for calm ones.
- Cuts group into breathing patterns (two-on two-off; four-on pause-two), never one per beat.
- Define a cut-density envelope over the film: dense hook, sparse middle, dense close.

## 4. The motion system (tokens, never ad-hoc values)

Three springs, one file, nothing else:
- SETTLE `{mass:1, damping:14, stiffness:120}` — large elements, display type, considered.
- SNAP `{mass:0.8, damping:20, stiffness:260}` — small UI, captions, supporting moves.
- BOUNCE `{mass:1, damping:9, stiffness:140}` — children/follow-through only, one overshoot.
Duration tokens (30fps): 6 / 12 / 18 frames; 15 frames (500ms) is the ceiling for any single
transition that is not a deliberate hold. Exits run 15-20% faster than enters, never mirrored.
Published curves worth importing verbatim via `Easing.bezier`:
- M3 emphasized `0.2, 0, 0, 1` (confident container moves)
- emphasized-decelerate `0.05, 0.7, 0.1, 1` (content entering)
- anticipate `1, -0.4, 0.35, 0.95` (the wind-up; ONE use per film, on the hit moment)
- easeOutBack `0.34, 1.56, 0.64, 1` (calibrated overshoot; icons may overshoot 2-8%,
  full-screen panels under 3%)
Stagger siblings 40-100ms (per-word type at 80-120ms, per-character 30-60ms). Children trail
parents 40-120ms with LOWER damping than the parent (follow-through). Size implies mass:
big moves slow, small moves snap; a display headline never moves as fast as a caption.

## 5. Type kinetics

- Never opacity-only fades on headlines. The premium reveals: mask (clip-path inset sweep) and
  blur-in (the 10px blur + 20% offset + 0 opacity → all-zero recipe, three properties in ONE
  interpolate). Keep animated blur under 20px.
- Variable-font axis animation (wght/wdth entering light and settling heavy) is the rare
  premium move template tools cannot fake; use where the font supports it.
- Scale reveals slow and subtle (50→100% slow ease = considered; the same fast = notification).

## 6. Camera, depth, and the frame

- The crop is the story: 80% of a raw screen recording is dead chrome; zoom so the meaningful
  10% fills the frame. The camera has an opinion, expressed as a crop, not a caption.
- Ken Burns on stills: push 1.0→1.2-1.4x with transform-origin ON the detail that matters,
  never center-zoom.
- Cursor-as-actor: spring-eased glide (never teleport); clicks and submits are cue points that
  trigger zoom-in / pull-back.
- Disguise the best cut as continuous motion (Apple grammar): push INTO an element until it
  fills frame, cut at saturation, reveal the next scene pulling out of the same anchor.
- One shared depth factor per layer (0.15 / 0.5 / 1.0) drives BOTH micro-parallax offsets and
  fake DOF blur (`blur = depth * maxPx`, 4-12px range). One source value, coherent depth.
- Motion blur ONLY on fast/large moves: Remotion `<CameraMotionBlur samples={8}
  shutterAngle={180}>`. Its absence on a whip-move is the #1 "this is slides" tell; applying it
  globally just burns render time.
- One light sweep per film maximum (skewed gradient, -20° to -45°, 1.5-2.5s) on the hero
  surface at the hit moment.
- A 2-3% opacity film-grain overlay (SVG feTurbulence fractalNoise), position-stepped per few
  frames (never smoothly sliding), kills the flat-vector tell.

## 7. Sound

- SFX land ON the cut — a tick/whoosh exactly on the edit is the cheapest produced-ness signal
  there is. Ticks for caption arrivals, low thocks for scene cuts, one swell into the close.
- A barely-audible low bed (felt, not heard) beats digital silence; duck it to real silence for
  the stillness beat and the final second.
- Voiceover-free is legitimate for audiences who read UI fluently — but then the UI choreography
  IS the narration and must carry it.
- Mix by measurement when ears are unavailable: bed ~-34 LUFS, ticks ≤-20dBFS TP, full mix
  -28 to -22 LUFS integrated, ≤-3dBFS true peak, end on near-silence.
- If music drives, the grid (sect. 3) is the music's BPM and cuts land on its hits.

## 8. Honesty rules (the line that keeps demos sellable)

- NEVER show a UI state the product cannot produce. The industry line is not
  recorded-vs-recreated; it is "delivery must match the demo."
- Capture is the source of truth; idealized MOTION on top of real states is legitimate craft
  (choreographing the reveal of a real screen is film grammar; fabricating a screen is fraud).
- Speed-ramp the dead beats (loading, transitions), never the informative beat.
- Missing captures are labelled on screen as pending, not faked.

## 8b. The copy diet (earned the hard way, owner review 2026-09-07)

Authored caption density is itself an AI tell, independent of how good each line is. The
genre's best films barely speak: the UI narrates and words appear only where the product
cannot show the point. Budget: max ~3 caption cards per short film plus the close. When a
film leans on footage-plus-type because the product surfaces are not ready to carry it, the
honest move is usually to WAIT for the surfaces (or fix them), not to compensate with cinema:
**the product carries the film; if it cannot, that is a product finding, not a compositing
problem.** Corollary: every in-app recording pass files what looked bad as UI issues — the
film pipeline doubles as UI QA.

## 9. Failure modes (check the cut against these)

Uniform shot length. One easing everywhere. Opacity fades on every headline. A static
screenshot with nothing moving inside the hold. Every beat scored, no silence. The generic
brand video register (aspirational narration that fits any product, stock music, "quirky
ukulele"). Fifteen features in ninety seconds. Motion chosen from a trend, not from the claim.
Overshoot on everything (toy) or nothing (dead). The logo before the product.

## 10. Remotion implementation notes

- `springs.ts` exports the three tokens; scenes import, never inline configs.
- `premountFor={fps}` on every sequence whose entrance springs, or frame 1 pops.
- `<TransitionSeries>` for scene joins: `springTiming({config:{damping:200}})` calm,
  `linearTiming` snapped to the beat grid for hits.
- Beat grid as a util: all `from`/`durationInFrames` derive from `framesPerBeat`; timings are
  computed in a timeline module, never typed into scenes.
- Audio-reactive garnish: `visualizeAudio()` amplitude → the shared depth factor, so hits give
  the camera a barely-perceptible kick synced to the actual waveform.
- Reference architecture: github.com/noamdorr/saas-product-demo-video (librosa beat detection,
  snare-locked boundaries, TypedText/MaskReveal/PopIn primitives, typing-budget validator).
- Process order (the Ordinary Folk discipline): block ALL camera/timing as rough mockups
  FIRST, review the blocking, only then detail passes. A 10-15s hero sequence deserves days,
  not hours; budget accordingly or cut scope.

## 11. Review checklist (run before showing anyone)

Reading-speed: max ~3 words/sec on any caption against its hold. Pace variance: no three
consecutive beats with equal length and equal spring. One hit moment, with stillness beside
it. Sound lands on cuts. Fonts verified rendered (no silent fallback). Zero em-dashes on
screen. Every UI state shown is producible. **Diegetic arithmetic: any number in a caption
must be countable in the frame it sits on — check caption numbers against the pixels, not
against the script** (a caption saying "nine" over a board labeled "(3)" is a lie the viewer
catches instantly; stage the data to match the copy or strip the number). Watch it muted once,
small once, and if possible have a human watch it moving — frames catch composition, only
playback catches rhythm.
