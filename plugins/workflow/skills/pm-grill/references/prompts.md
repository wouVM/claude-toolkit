# Scenario bank

Read only the scenario you picked. "Say" is what you tell the PM, word for word or close. Everything
under "Hidden" stays hidden until the debrief. `trains:` names the score dimensions the scenario
tests hardest (G, A, M, E, Def, Pack). L = Luke's own, N = new in his style.

| id | Scenario | Source | Difficulty | trains |
|---|---|---|---|---|
| L1 | StreamBox "Pick for me" | Luke | medium | G, M, Def |
| L2 | Burger Dash upsell screen | Luke | hard | M, Def, E |
| L3 | Skylark Air mobile check-in | Luke | hard | Def, M, Pack |
| L4 | Netflix podcast product North Star | Luke, earlier | medium | G, M |
| L5 | PayPal: conversion up, monthly actives down | Luke, earlier | hard | A, M, Pack |
| L6 | MendWell accident clinic: insurer collections | Luke, earlier (fictionalised) | medium | M, Def |
| N1 | FlatSwap instant booking for hosts | new, marketplace | medium | G, A, M |
| N2 | LedgerLite onboarding checklist | new, SaaS | easy | G, Def |
| N3 | PocketPay round-up savings | new, fintech | medium | M, Def, E |
| N4 | QuickCart delivery ETA | new, delivery | hard | M, E, Pack |
| N5 | TableTalk WhatsApp booking bot | new, B2B chatbot | hard | G, Def, M |
| N6 | Zippa surge pricing redesign | new, ride-hailing | hard | M, E, Pack |
| N7 | Sparkly daily match limit | new, dating | medium | G, M, E |
| N8 | "North Star dropped 12% this week" | new, drill | medium | A, Pack |
| N9 | Minutely AI meeting summary | new, SaaS AI | medium | G, M, Def |
| N10 | GrocerGo picker substitutions | new, delivery | medium | Def, E |
| N11 | FitTrack streaks | new, consumer | easy | G, M |
| N12 | Learnly trial 7 to 14 days | new, subscription | medium | Def, E, Pack |
| N13 | JobLink one-click apply | new, marketplace | medium | M, E |

---

## L1 StreamBox "Pick for me" (Luke, medium)

Say: "You're the PM at StreamBox, a streaming service. The team shipped a 'Pick for me' button:
one tap and it starts something it thinks you'll like. What's the right metric, and how would you
test it?"

Hidden:
- Goals: user wants to stop scrolling and watch something they enjoy; business wants retained
  subscribers. Feature goal: cut time-to-play without lowering satisfaction.
- Company NS: monthly active subscribers who watch (or hours of satisfying viewing) per month.
- Feature primary: share of "Pick for me" plays watched past 10 minutes (or 70% of an episode),
  per user session, weekly. Rate, not level.
- Inputs: button taps, time from app open to play, re-picks per session.
- Guardrails: subscriber churn, total watch sessions per user, "dislike"/skip within 2 minutes.
- Gaming: count taps or plays; autoplay anything long and sticky.
- Traps: "Another team improved the recommendation algorithm and your button clicks stayed flat.
  Success?" (yes if completion-quality rose; clicks were never the goal). "What if watch time
  goes to 24 hours a day, good?" (no: watch time is a proxy, not value; cap it with satisfaction).
- Hypothesis: If we add "Pick for me", the share of sessions that start a show within 2 minutes
  rises without lowering the 10-minute completion rate or retention.

## L2 Burger Dash upsell screen (Luke, hard)

Say: "Burger Dash is a food delivery app. The team added an upsell screen before checkout: 'Add
fries for 2.50?'. Average order value went up. What's the right metric, and was it a success?"

Hidden:
- Goals: user wants their meal quickly at a fair price; business wants profit per order and repeat
  orders. Feature goal: raise basket value without losing orders.
- Key insight: AOV rises partly because small orders abandon at the extra screen. The average is
  computed over survivors (survivorship in an average).
- Company NS: profitable orders per month (or monthly ordering customers).
- Feature primary: profit per checkout started (gross margin of completed orders ÷ checkouts
  started), per week. Denominator is everyone who reached checkout, so abandoners count.
- Guardrails: checkout completion rate, 30-day reorder rate, delivery time, refund/complaint rate.
- Gaming: $1 fries lifts attach rate and order count while profit falls; or a pushy screen.
- Traps: "AOV is up 8%. Ship it?" (check completion first). "Order count is up: good?" (fries at
  $1). "Is AOV the North Star if cancellations go up?"
- Recommendation: Ship only if profit per checkout started rises and checkout completion does not
  fall beyond the agreed threshold; else limit the screen to large baskets.

## L3 Skylark Air mobile check-in (Luke, hard)

Say: "Skylark Air launched mobile check-in. Leadership wants to know if it's working. What's
the right metric, and how would you test it?"

Hidden:
- Goals: passenger wants to get to the gate without queueing; business wants lower desk cost and
  on-time departures. Feature goal: move passengers off the desk.
- Unit: per passenger, not per booking (a booking holds several passengers; per booking hides
  half-checked-in families).
- Population: eligible passengers only. Exclude the desk-required cohort (bags without online
  drop, special assistance, visa checks), or report it apart.
- Feature primary: share of eligible passengers checked in on mobile before arriving at the
  airport, per departure day, weekly. Rate.
- Valid outcome: passengers who reach the gate without visiting a desk.
- Guardrails: desk queue time, boarding-pass errors at the gate, on-time departure rate.
- Mix shift trap: "Mobile completions went up but desk visits stayed flat. Why?" (more leisure
  travellers without bags this month, or business travellers who used web before; the mix moved,
  not the behaviour. Segment by cohort.)
- Recommendation: Keep it and push it where eligible passengers still go to the desk; judge by
  desk visits per eligible passenger, not by app check-ins.

## L4 Netflix podcast product North Star (Luke, earlier, medium)

Say: "Netflix is launching podcasts inside the app. What should the North Star be for the
podcast product?"

Hidden:
- Goals: user wants something worth listening to when they cannot watch; business wants more
  reasons to stay subscribed (lower churn), not ad minutes.
- Company NS stays retained paying members; podcast feature NS sits under it.
- Feature primary: monthly active podcast listeners with 2+ listening sessions of 10+ minutes in
  the month, as a share of members who opened podcasts (or a count, if the question is volume).
- Inputs: discovery taps, follows, episodes started, completion.
- Guardrails: video viewing hours per member (cannibalisation is fine only if retention holds),
  churn of podcast listeners vs matched non-listeners.
- Gaming: autoplay podcasts after video; count 5-second plays.
- Trap: "Listening hours go up and video hours go down by the same amount. Success?" (only if
  retention improves; otherwise you moved time, not value).
- Hypothesis: If members find a podcast they return to, their churn falls versus similar members,
  without lowering video sessions.

## L5 PayPal: conversion up, monthly actives down (Luke, earlier, hard)

Say: "At PayPal, checkout conversion is up this quarter, but monthly active users are down. What
happened, and what do you do?"

Hidden:
- Goals: users want a fast safe way to pay; business wants active users and payment volume.
- Likely mechanism: a change removed weak or low-intent users from the denominator (stricter
  risk, a login step, a removed entry point), so the remaining users convert better. Or mix:
  fewer casual users, same core.
- Check order: same definitions both periods; segment by new vs returning, country, platform;
  funnel step where users stopped arriving; releases and risk-policy changes; seasonality.
- Company NS: monthly active accounts (or total payment volume per month). Conversion is an input,
  not the goal.
- Gaming: "a junior PM told to raise conversion drops the bad customers."
- Trap: "So conversion improving is good news?" (not on its own; it is a rate over a shrinking base).
- Recommendation: Report completed payments per month as the headline, conversion as a diagnostic,
  and find which cohort stopped arriving before deciding anything.

## L6 MendWell accident clinic: insurer collections (Luke, earlier, fictionalised, medium)

Say: "MendWell runs accident clinics. Patients are treated first, and the clinic bills the
patient's accident insurer afterwards. The team has been tracking collection rate: the share of
bills the insurers pay. Is that the right North Star?"

Hidden:
- Goals: patient wants treatment without chasing paperwork; insurer wants to pay valid claims
  only; business wants cash collected for treatment delivered, at low admin cost.
- Weakness of collection rate alone: rises if you bill fewer hard cases (complex injuries,
  disputed cover) or only submit the claims that are sure to pass.
- Company NS for the product: dollars paid by insurers per month for treated patients (level,
  with the window in the name).
- Guardrails: collection rate on every billable treatment (share paid within 60 days), claim
  rejection and dispute rate, admin cost per dollar collected, patients billed directly because
  the insurer claim was never filed.
- Gaming: leave old or complex claims out of the denominator; bill only easy, small claims;
  over-bill now and lose the insurer's trust later.
- Trap: "Dollars collected went up because patient volume doubled. Success?" (normalise:
  watch the rate guardrail; a level needs its rate beside it.)
- Recommendation: Lead with dollars collected per month, guard it with collection rate on all
  billable treatments and the rejection rate.

## N1 FlatSwap instant booking for hosts (marketplace, medium)

Say: "FlatSwap is a short-stay rental marketplace. Hosts can now turn on 'Instant book' so guests
don't wait for approval. What's the right metric, and how would you test it?"

Hidden:
- Goals: guest wants a confirmed place fast; host wants good guests and occupancy; business wants
  completed stays (take rate).
- Funnel: search, listing view, request or instant book, confirmed, stayed, reviewed.
- Company NS: nights stayed per month (completed, not cancelled).
- Feature primary: completed stays per guest search session on instant-book listings vs others,
  weekly; or request-to-confirmed-stay rate.
- Guardrails: host cancellation rate, host opt-out rate (hosts turning it off), damage/complaint
  rate, review score.
- Gaming: push all hosts to instant book; count bookings, not stays.
- Trap: "Bookings up 15%, host cancellations up 10%. Ship?" (count completed stays; host side is
  the scarce side of a marketplace).
- Hypothesis: If guests can book instantly, completed stays per search rise without raising host
  cancellations or host opt-outs.

## N2 LedgerLite onboarding checklist (SaaS, easy)

Say: "LedgerLite is invoicing software for freelancers. The team added an onboarding checklist
for new sign-ups. How do you know if it works?"

Hidden:
- Goals: freelancer wants to get paid with less admin; business wants paying, retained accounts.
- First value: first invoice sent to a real client (not a test to self).
- Feature primary: share of new sign-ups who send a first real invoice within 7 days of sign-up,
  per weekly sign-up cohort. Rate, cohort-based.
- Guardrails: trial-to-paid conversion, 30-day retention, support tickets per new account.
- Gaming: count checklist completions; let users tick items without doing them.
- Trap: "Checklist completion is 80%. Done?" (output, not outcome).
- Hypothesis: If new users get a checklist, more send a real invoice within 7 days, without
  lowering trial-to-paid.

## N3 PocketPay round-up savings (fintech, medium)

Say: "PocketPay, a banking app, launches round-ups: each card purchase rounds up to the next
whole dollar and the change goes into savings. What's the right metric?"

Hidden:
- Goals: user wants to save without thinking; business wants deposits and primary-account usage.
- Company NS: monthly active primary-account customers (salary in, card used).
- Feature primary: share of users who turned round-ups on and still had a round-up deposit in
  each of the following 3 months (retained savers), monthly cohort.
- Secondary: savings balance from round-ups, median per saver (median, not mean; a few whales).
- Guardrails: overdraft or declined-payment rate (round-ups draining checking), card spend per
  user, opt-out rate.
- Gaming: default-on round-ups; report total balance driven by a few large savers.
- Trap: "Total round-up balance tripled. Success?" (check median and the count of savers).
- Hypothesis: If users can round up purchases, more of them keep saving 3 months later without
  more overdrafts.

## N4 QuickCart delivery ETA (delivery, hard)

Say: "QuickCart delivers groceries in under an hour. The team rebuilt the ETA model shown at
checkout. What's the right metric, and how would you test it?"

Hidden:
- Goals: customer wants to know when food arrives and trust it; business wants orders and repeat
  orders at low support cost.
- Feature primary: share of orders delivered within ±5 minutes of the ETA shown at checkout,
  weekly. Accuracy against the first promise, not the last update.
- Company NS: weekly ordering customers (or orders completed per week).
- Guardrails: checkout conversion, average promised ETA (padding check), "where is my order"
  contacts per 100 orders, 30-day reorder.
- Gaming: pad every ETA by 15 minutes; accuracy rises, conversion falls.
- Trap: "Accuracy went from 60% to 85%. Ship?" (did the promised ETA get longer? did conversion
  drop?). "Late deliveries fell but early ones rose. Fine?"
- Recommendation: Ship if accuracy rises with promised ETA flat and conversion within threshold;
  measure as an A/B by zone, two weeks, covering weekends.

## N5 TableTalk WhatsApp booking bot (B2B chatbot, hard)

Say: "TableTalk sells an AI WhatsApp concierge to restaurants. Guests can now book a table
inside the chat, with no staff involved. What's the right metric, and how would you test it?"

Hidden:
- Goals: two customers. Guest wants a confirmed table quickly; restaurant owner wants more
  covers with less phone time. TableTalk wants restaurants that keep paying.
- Company NS: restaurants still paying after 3 months whose guests book through the chat every
  week.
- Feature primary: share of booking-intent chats that end in a confirmed booking in the
  restaurant's reservation system without staff, per restaurant, per week.
- Valid outcome: booking honoured (guest showed), not just written.
- Guardrails: no-show rate on chat bookings, bookings the restaurant had to fix or cancel, handovers
  left unanswered, guest complaint rate.
- Gaming: "containment rate": the bot never hands over, so chats look resolved while guests
  leave. Or count bookings the system rejected later.
- Unreliable narrator: the bot's own transcript says "booked"; check the reservation system.
- Trap: "Booking rate is 70%, but owners say they still get the calls. What happened?" (the
  phone-booking guests never reached the chat; adoption, not conversion, is the gap).
- Hypothesis: If guests can book in the chat, confirmed and honoured bookings per booking-intent
  chat rise without more no-shows or unanswered handovers.

## N6 Zippa surge pricing redesign (ride-hailing, hard)

Say: "Zippa, a ride-hailing app, redesigned surge pricing: smoother multipliers and an upfront
fare. Leadership asks if it worked. What do you measure?"

Hidden:
- Goals: rider wants a ride when needed at a fair, known price; driver wants earnings; Zippa
  wants completed trips and margin, and trust.
- Company NS: completed trips per week.
- Feature primary: completed trips per ride request during high-demand hours (fulfilment rate in
  surge windows), weekly.
- Guardrails: rider cancellations after seeing the quote, driver earnings per online hour, rider
  complaints about price, regulatory price caps.
- Gaming: raise multipliers to lift revenue per trip; tighten the definition of "surge hours".
- Traps: "Completed trips went up 6%. Was it your redesign?" (more drivers online that month, a
  concert, a rain week; compare with a holdout city or time-sliced test). "Revenue per trip up,
  trips flat. Good?"
- Recommendation: Judge by surge-hour fulfilment against a holdout, guarded by driver earnings
  per hour and quote cancellations; do not ship on revenue per trip alone.

## N7 Sparkly daily match limit (dating, medium)

Say: "Sparkly, a dating app, wants to limit swipes to 20 profiles a day to improve match quality.
What's the right metric?"

Hidden:
- Goals: user wants a good date, eventually not needing the app; business wants subscribers and
  word of mouth.
- Company NS: weekly users in active two-way conversations (or dates arranged per month, if
  measurable).
- Feature primary: share of matches that reach 3+ messages from each side within 7 days, weekly.
- Guardrails: retention of the scarce side (often women), reports and blocks per match, premium
  conversion.
- Gaming: time in app, swipes, total matches.
- Trap: "Users who find a partner leave. Is churn bad here?" (separate happy churn: ask on exit
  or track "met someone"). "Daily active users fell 10%. Kill it?"
- Hypothesis: If users get 20 profiles a day, more matches turn into real conversations without
  lowering retention of the scarcer side.

## N8 "North Star dropped 12% this week" (diagnostic drill, medium)

Say: "Monday morning. Your North Star, weekly active users, dropped 12% week on week. What do
you check first, and in what order?"

Hidden, the order:
1. Is it real: tracking, pipeline, definition change, a delayed data load, a bot filter.
2. Seasonality and calendar: same week last year (YoY) and the month before (MoM) as diagnostics,
   holidays, school breaks.
3. External: outage, app-store change, competitor launch, news, weather.
4. Segment: platform, country, new vs returning, acquisition channel. Is it one segment or all?
5. Funnel: which step lost users (open, sign-in, core action).
6. Internal changes: releases, experiments, pricing, marketing spend cut.
7. Then hypothesis and a decision: roll back, fix, or wait one more week.
- Trap: "It's only in Android, Germany. Next?" (release notes, app-store review, payment method).
- Good answers say what each check would rule out, and stop at the first one that explains it.

## N9 Minutely AI meeting summary (SaaS AI, medium)

Say: "Minutely is a notes app for teams. It added an AI button that summarises a meeting. Usage
is high. Is it a success?"

Hidden:
- Goals: user wants the decisions and actions from a meeting without rewriting notes; business
  wants teams that keep paying and add seats.
- Company NS: weekly active teams (3+ members creating or editing notes).
- Feature primary: share of generated summaries kept (shared or reused within 24 hours, not
  deleted or rewritten), per week.
- Guardrails: error reports per summary, time spent editing the summary, seat churn.
- Gaming: auto-generate summaries for every meeting; count generations.
- Trap: "Usage is high" is output. "Summaries generated tripled, kept rate halved. Good?"
- Hypothesis: If teams get AI summaries, the share of meetings with a shared summary rises
  without more error reports or seat churn.

## N10 GrocerGo picker substitutions (delivery, medium)

Say: "At GrocerGo, when an item is out of stock the shopper picks a substitute. The team built
smarter suggestions for the shopper. What do you measure?"

Hidden:
- Goals: customer wants the meal they planned; business wants complete orders with low refunds.
- Feature primary: share of substituted items accepted by the customer (not refunded or
  rejected), per order with a substitution, weekly.
- Company NS: weekly ordering customers.
- Guardrails: refund cost per order, order rating, shopper picking time.
- Mix shift trap: "Acceptance went up, but refunds per order did not fall. Why?" (more
  substitutions of cheap staples this month; segment by category).
- Gaming: substitute only cheap, safe items; or stop substituting (fewer rejections, more
  missing items).
- Hypothesis: If shoppers get better suggestions, more substitutes are kept without longer
  picking time.

## N11 FitTrack streaks (consumer, easy)

Say: "FitTrack, a workout app, added streaks: keep working out every day to grow your streak.
What's the right metric?"

Hidden:
- Goals: user wants to get fitter by exercising regularly; business wants retained subscribers.
- Company NS: weekly active exercisers (3+ logged workouts of 15+ minutes a week).
- Feature primary: share of users with 3+ workouts a week, four weeks after first seeing streaks.
- Guardrails: workout duration (no 1-minute "workouts"), injury or rest-day complaints,
  subscription churn.
- Gaming: streak counts, daily opens, logging fake workouts.
- Trap: "Daily opens rose 30%. Good?" (24-hours-a-day logic: activity is not value).
- Hypothesis: If users see streaks, more of them keep 3 real workouts a week after a month,
  without shorter workouts.

## N12 Learnly trial 7 to 14 days (subscription, medium)

Say: "Learnly, a language app, wants to extend its free trial from 7 to 14 days. How would you
decide?"

Hidden:
- Goals: learner wants to see progress before paying; business wants paid subscribers who stay.
- Feature primary: paid subscribers still paying at day 45 per trial started, per weekly trial
  cohort (net of refunds).
- Guardrails: revenue per trial started (cash arrives a week later), refund rate, lesson
  completion during trial.
- Window trap: "After two weeks the 14-day arm has fewer paid users. Kill it?" (the 14-day arm
  has not reached its paywall yet; compare at the same day after trial end).
- Gaming: count trial starts; push annual plans with refunds.
- Recommendation: Run an A/B by cohort, read at day 45, ship if paid-at-45 per trial rises and
  refunds hold.

## N13 JobLink one-click apply (marketplace, medium)

Say: "JobLink, a jobs marketplace, launched one-click apply. Applications are up 40%. Is it a
success?"

Hidden:
- Goals: seeker wants a job; employer wants good candidates fast; JobLink wants employers who
  keep paying for listings.
- Company NS: hires per month (or interviews per active seeker per month as a proxy).
- Feature primary: interviews per seeker using one-click apply per month, vs before.
- Guardrails: recruiter response rate, employer renewal rate, applications per listing per
  recruiter hour.
- Gaming: applications count; spammy mass-apply.
- Trap: "Recruiters say they are drowning. Does it matter if applications are up?" (the paying
  side is employers; volume without fit hurts renewals).
- Recommendation: Keep one-click only if interviews per seeker rise and recruiter response holds;
  otherwise add a fit check before apply.
