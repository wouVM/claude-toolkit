# Scenario bank

Read only the scenario you picked. "Say" is what you tell the candidate, word for word or close. Everything
under "Hidden" stays hidden until the debrief. `type`: A analytical (GAME), D design / product
sense (goals, users, pains, solutions), B dashboard. `trains:` names the score dimensions the
scenario tests hardest, in that type's letters (A: G, A, M, E, Def, Pack; D: G, U, P, S, M, T;
B: Q, H, Def, Act, Cov, Pack). L = Luke's own, N = new in his style, Q = from the interview
question bank Luke shared on 22.10 (crowdsourced Meta/Google questions).

| id | Scenario | Source | type | Difficulty | trains |
|---|---|---|---|---|---|
| L1 | StreamBox "Pick for me" | Luke 21.10 | A | medium | G, M, Def |
| L2 | Burger Dash upsell screen | Luke 21.10 | A | hard | M, Def, E |
| L3 | Skylark Air mobile check-in | Luke 21.10 | A | hard | Def, M, Pack |
| L4 | Netflix podcast product North Star | Luke, earlier | A | medium | G, M |
| L5 | PayPal: conversion up, monthly actives down | Luke, earlier | A | hard | A, M, Pack |
| L6 | Collections product North Star | Luke, earlier | A | medium | M, Def |
| L7 | Uber rides for seniors | Luke 23.10 | D | medium | U, P, S, T |
| L8 | Spotify executive dashboard | Luke 22.10 | B | medium | Q, H, Act, Cov |
| L9 | Google Maps parking | Luke's own 2025 interview | D | hard | G, P, S |
| L10 | A volunteering product for Meta | Luke 22.10 example | D | medium | G, U, S |
| L11 | Meta Pay goals and success | Luke 22.10 example | A | medium | G, M, Def |
| N1 | FlatSwap instant booking for hosts | new, marketplace | A | medium | G, A, M |
| N2 | LedgerLite onboarding checklist | new, SaaS | A | easy | G, Def |
| N3 | PocketPay round-up savings | new, fintech | A | medium | M, Def, E |
| N4 | QuickCart delivery ETA | new, delivery | A | hard | M, E, Pack |
| N5 | TableTalk WhatsApp booking bot | new, B2B chatbot | A | hard | G, Def, M |
| N6 | Zippa surge pricing redesign | new, ride-hailing | A | hard | M, E, Pack |
| N7 | Sparkly daily match limit | new, dating | A | medium | G, M, E |
| N8 | "North Star dropped 12% this week" | new, drill | A | medium | A, Pack |
| N9 | Minutely AI meeting summary | new, SaaS AI | A | medium | G, M, Def |
| N10 | GrocerGo picker substitutions | new, delivery | A | medium | Def, E |
| N11 | FitTrack streaks | new, consumer | A | easy | G, M |
| N12 | Learnly trial 7 to 14 days | new, subscription | A | medium | Def, E, Pack |
| N13 | JobLink one-click apply | new, marketplace | A | medium | M, E |
| Q1 | Google: a phone for the elderly (65+) | bank | D | easy | U, P, S |
| Q2 | Facebook: help people find a doctor | bank | D | medium | G, U, S |
| Q3 | Facebook Events: RSVPs down 10% overnight | bank | A | medium | A, Pack |
| Q4 | Bike sharing: go freemium? | bank | A | medium | G, E, Pack |
| Q5 | An engineer wants Marketplace items in News Feed | bank | A | hard | G, E, Pack |
| Q6 | Design an app for museums | bank | D | easy | U, P, S |
| Q7 | Any product: build its metrics dashboard (Airbnb) | bank | B | medium | Q, H, Def, Cov |
| Q8 | Amazon: test a gift card for Prime app downloads | bank | A | hard | Def, E |
| Q9 | Facebook Lite: what goals would you set? | bank | A | easy | G, M |
| Q10 | Facebook: improve grocery delivery | bank | D | medium | U, P, T |

---

## L1 StreamBox "Pick for me" (Luke 21.10, medium)

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

## L2 Burger Dash upsell screen (Luke 21.10, hard)

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

## L3 Skylark Air mobile check-in (Luke 21.10, hard)

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

## L6 Collections product North Star (Luke, earlier, medium)

Say: "You own a collections product: customers who owe money get reminders and payment links.
The team has been tracking collection rate. Is that the right North Star?"

Hidden:
- Goals: customer wants an easy, fair way to settle; business wants cash collected at low cost.
- Weakness of collection rate alone: rises if you send fewer hard cases into the funnel or chase
  only small balances.
- Company NS for the product: dollars collected per month (level, with the window in the name).
- Guardrail: collection rate (share of due balances collected within 60 days), complaint and
  dispute rate, cost per dollar collected.
- Gaming: exclude old debt from the denominator; chase easy small balances; aggressive reminders
  that lift cash now and churn customers later.
- Trap: "Dollars collected went up because the overdue book doubled. Success?" (normalise:
  watch the rate guardrail; a level needs its rate beside it.)
- Recommendation: Lead with dollars collected per month, guard it with collection rate on the full
  due book and the complaint rate.

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
franc and the change goes into savings. What's the right metric?"

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
- Company NS: paying restaurants with steady guest use (e.g. 5+ guests chatting a week).
- Feature primary: share of booking-intent chats that end in a confirmed booking in the
  restaurant's reservation system without staff, per restaurant, per week.
- Valid outcome: booking honoured (guest showed), not just written.
- Guardrails: no-show rate on chat bookings, bookings the venue had to fix or cancel, handovers
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

## L7 Uber rides for seniors (Luke 23.10, D, medium)

Say: "You're a PM at Uber. Uber is launching a rides product for seniors. How would you define
what success looks like, and what would you launch?"

Hidden (the strongest answers from the 23.10 group call, plus the driver side, which every
candidate missed):
- Clarify: who is a senior (65+ or 75+), which markets. Coverage matters: US retirement belts are
  dense; most Belgian seniors live in villages Uber does not serve.
- Business goal: Uber is a two-sided marketplace. Why seniors: a growing segment that stops
  driving within a decade; fills off-peak supply (mid-morning, early afternoon, when drivers sit
  idle); high lifetime value from predictable weekly trips.
- User groups by need, not age alone: A recently stopped driving (mobile, socially active); B light
  assistance (cane, walker, bags); C full assistance (wheelchair, door-through-door care: out of
  v1, needs a different fleet); caregivers (adult children far away who book and want to see
  arrival); drivers (supply: unpaid waiting, slow boarding).
- Pick: A and B plus caregivers, in a dense senior market (Florida pilot: high share of 65+,
  concentrated in retirement communities, Uber driver coverage already there).
- Pains, widest and deepest first: 1 losing independence (can't drive or afford a car, family
  not nearby); 2 reliability anxiety (late to the appointment, stranded with no ride home);
  3 physical help with bags or a walker; 4 tech friction (busy app, real-time matching is
  stressful); 5 cost on a fixed income (surge, unpredictable fares); 6 social isolation; 7 trust
  and safety (low frequency, high impact: a guardrail, not the v1 lead).
- Solutions mapped: scheduled round-trip rides with reminders (1, 2); opt-in light assistance
  with paid wait time for drivers (3, driver side); caregiver booking and trip notifications
  (1, 4, 7); simple mode or book by phone (4); upfront fixed price, no surge on scheduled rides
  (5). Launch first: scheduled round trips that a caregiver can book, because it hits the two
  widest pains and builds on existing scheduling.
- North Star: share of activated 65+ riders who become habitual, 4+ completed trips a month
  Or successful senior trips per month: accepted, completed, no issue. Rides booked (a common
  first answer) is weaker: booked is not completed, and a level hides whether riders stick.
- Inputs: scheduled trips picked up on time, share booked as round trips, share booked by
  caregivers, 3-month retention of first-time senior riders.
- Guardrails, both sides: driver acceptance on senior trips, driver earnings per online hour,
  cancellations and no-shows, wait times for other riders, safety incidents, contribution margin.
- Hypothesis: If seniors or their caregivers can book scheduled round trips, the share of 65+
  riders in the Florida pilot taking 4+ trips a month rises, without lowering driver acceptance
  or earnings per hour.
- Cheapest test: A/B a simple mode with seniors already on the app before building the full
  product, then the one-metro pilot.
- Traps: "You named it Uber Gray. What problem does it solve?" "Are all seniors bad with tech?"
  "Couldn't a designer just make the icons bigger?" "What do drivers get out of it?" "Rides booked
  doubled because caregivers book. Success?" (only if completed, habitual trips rose).

## L8 Spotify executive dashboard (Luke 22.10, B, medium)

Say: "The CEO of Spotify comes to you and says: I have no idea what's going on with my business,
I want to see it in one place. Design a dashboard for me."

Hidden:
- Business questions, ranked: 1 is the listening audience growing? 2 are we making more money,
  and from which engine (subscriptions vs ads)? 3 are people getting value? 4 where does the
  funnel leak (sign-up, active, paid, churn)? 5 is the ad side healthy?
- Top tile: monthly active users (played 30+ seconds in the last 28 days), all plans. Above paid
  subscribers because free users earn ad revenue too (a candidate switched to it on 22.10 for exactly this reason).
- Money row: revenue per month split subscriptions and ads; ARPU (revenue ÷ monthly actives) by
  plan; paid subscribers.
- Value row: listening minutes per user per week (all monthly actives in the denominator). Time
  normalises songs, podcasts and books, which plays do not. Per user, not per active user: per
  active hides users dropping off, and can rise while many go inactive.
- Funnel row: sign-up to paid within 30 days (completions ÷ sign-ups in the window), split by
  path (direct vs via trial); trial-to-paid; monthly paid churn.
- Ads: advertisers active, revenue per 1,000 ad impressions; the ad funnel has a second side,
  advertisers buying space, which nobody covered on 22.10.
- Not on it: total costs (barely move month to month, no action follows); 20 equal-size tiles;
  top-artist share (a drill-down, not an exec tile).
- Every tile: its equation, and "if it drops, the next thing I check is".
- Traps: "Why is that above daily actives?" "Define conversion there." "Books are long, songs are
  short, how do you compare?" "Per user or per active user?" "How much do costs move month to
  month?"
- Package: one number for health (monthly actives), two for money (revenue split, ARPU), one for
  value (listening per user), two for leaks (conversion, churn).

## L9 Google Maps parking (Luke's own 2025 interview, D, hard)

Say: "You're a PM on Google Maps. Build a parking solution."

Hidden:
- Trap Luke named: jumping straight to sensors on every space or Street View cars counting spots.
- Business goal: Maps exists to get people where they are going; parking is the last mile where
  the trip fails. Business: daily use of Maps and local partners (garages, merchants).
- User groups: drivers to dense city centres (commuters with a routine, occasional visitors,
  event-goers), drivers in unfamiliar cities, drivers with disability permits; other side: garage
  operators, cities. Pick occasional drivers to dense unfamiliar areas: large and deeply felt.
- Pains: don't know before leaving if parking exists near the destination; circling the block
  (time, stress, late); price and rules unclear; paying is fiddly; forgetting where you parked.
  Widest and deepest: uncertainty before leaving and circling.
- Solutions: parking difficulty forecast at the destination from aggregated location data
  (circling detection); route straight to a nearby garage with walk time; reserve and pay with
  garage partners; remember where I parked. Launch first: the forecast plus "route to a garage",
  because it uses data Maps already has and needs no hardware.
- North Star: median minutes from entering the destination zone to parked, per navigation to a
  dense destination, weekly. Inputs: forecast views, garage routes taken. Guardrails: ETA
  accuracy, navigation starts, privacy complaints, partner satisfaction.
- Hypothesis: If Maps shows parking difficulty and offers a garage route, median circling time
  falls without lowering navigation starts.

## L10 A volunteering product for Meta (Luke 22.10 example, D, medium)

Say: "Build a product for volunteering at Meta."

Hidden:
- Business goal: Meta's mission is community and bringing people closer; volunteering is
  community offline. For Meta: more meaningful use of Groups and Events, and time well spent.
- User groups: would-be volunteers (students who need hours, retirees, professionals with skills,
  one-off vs regular), non-profit organisers (the other side, and the scarce one), friends.
- Pains: volunteers don't know what is near and when, or how big the commitment is, and going
  alone is awkward. Organisers: no-shows, recruiting cost, managing shifts. Deepest: organisers'
  no-shows; widest: volunteers finding a one-off near them.
- Solutions: volunteer shifts on Events with sign-up, reminders and "friends going"; organiser
  tools for shifts and attendance; skills matching. Launch first: shifts on Events, because it
  reuses Events and serves both sides.
- North Star: attended volunteer shifts per month, confirmed by the organiser. Guardrails:
  no-show rate, organisers posting again, scam reports.
- Hypothesis: If organisers can post shifts on Events with reminders and friends going, attended
  shifts per month rise without more no-shows.
- Trap: "Sign-ups tripled. Success?" (sign-ups are not attendance).

## L11 Meta Pay goals and success (Luke 22.10 example, A, medium)

Say: "Define the goals and the success metrics for Meta Pay, Meta's checkout product."

Hidden:
- Goals: user wants to pay fast and safely without typing card details; business wants more
  commerce on Meta, which makes ads worth more to merchants. Fees are minor.
- Actions: add a payment method, start checkout, pay, pay again.
- Company NS: daily active people (or ad revenue); feature NS: monthly active payers, people with
  1+ successful Meta Pay payment in 28 days. Successful payment volume per month beside it.
- Definitions: payments that succeeded, net of refunds and chargebacks.
- Guardrails: fraud and chargeback rate, payment failure rate, merchant refund rate.
- Gaming: cashback promotions buy payments; counting cards added.
- Trap: "Payment volume up 30% because one big merchant joined. Success?" (concentration; watch
  active payers). "Checkout conversion up, payers flat?" (fewer, warmer shoppers).

## Q1 Google: a phone for the elderly, 65+ (bank, D, easy)

Say: "Design a phone for the elderly, 65 plus."

Hidden:
- Business goal: why Google: Android reach into a growing group that is under-served, and
  family who buy and set up devices.
- User groups by need: active 65 to 75 who are fine with smartphones (out); declining eyesight
  or hearing; early memory decline; living alone; caregivers who set up and support remotely.
  Pick: living alone with declining eyesight, plus the caregiver.
- Pains, widest and deepest: missing calls from family; small text and busy menus; an emergency
  or fall with nobody around; scam calls; medication.
- Solutions: a simple home screen with big tiles that family set up remotely; fall detection and
  one-tap emergency; scam call screening; reminders. Launch first: the remotely managed simple
  mode, cheap as an Android setting, serves the widest pain.
- North Star: weekly active seniors who make or take 3+ calls or messages with family. Guardrails:
  support calls per device, returns, false emergency alerts.
- Trap: "Isn't that just bigger buttons? Why a new product?" (tie it to the deeper pain: staying
  in touch and safe alone).

## Q2 Facebook: help people find a doctor (bank, D, medium)

Say: "Design a product to help people find a doctor."

Hidden:
- Business goal: why Facebook: trusted recommendations from friends and local groups, which
  Google and booking sites lack; more meaningful use of Groups.
- User groups: people new to a city, parents looking for a paediatrician, people with a chronic
  condition, urgent needs (out: emergencies belong elsewhere). Pick people new to a city.
- Pains: who is good and trusted; who takes my insurance and new patients; wait times; booking.
- Solutions: structured "recommend a doctor" asks in friends and local groups; doctor pages with
  "accepting new patients"; a booking link. Launch first: recommendations, Facebook's unique edge.
- North Star: share of doctor searches that end in a booked appointment within 14 days.
  Guardrails: health privacy complaints, misinformation reports.
- Traps: "Why would Facebook win here?" "Health data: what do you not touch?"

## Q3 Facebook Events: RSVPs down 10% overnight (bank, A, medium)

Say: "You're the PM of Facebook Events. Overnight, RSVPs dropped 10%. How do you figure out
what happened?"

Hidden, the order (overnight and sudden points to something mechanical first):
1. Is it real: logging change, pipeline delay, definition change ("interested" vs "going").
2. Last night's releases and experiments, and outages.
3. Segment: platform, app version, country, event type. One segment or all?
4. Funnel: event impressions, event views, RSVP taps. Which step fell?
5. External: a holiday, a big event that ended, news.
6. Then a hypothesis and a decision: roll back, fix, or wait.
- Traps: "Only iOS, since last night's release." (roll back or hotfix, confirm with the funnel).
  "'Interested' is up as much as 'going' is down." (a UI change moved taps, not intent; judge by
  attendance if measurable).

## Q4 Bike sharing: go freemium? (bank, A, medium)

Say: "A bike-sharing company is considering a freemium model. Should they do it?"

Hidden:
- Goals: rider wants a cheap bike nearby for a short trip; business wants higher revenue per
  rider and conversion to paid (the bank answer's framing).
- Actions: first free ride, paid ride, membership.
- Risk: free riders take bikes at peak, crowding out paying commuters; each ride costs
  rebalancing and wear.
- Test: free tier only off-peak, aimed at tourists outside commute hours (the bank answer).
- Metric: paid rides per new rider within 30 days, per weekly cohort; revenue per bike per day.
  Guardrails: empty-station rate at peak, paying riders who find no bike, damage per ride.
- Package: test first, off-peak only; ship if revenue per bike rises and peak availability holds.

## Q5 An engineer wants Marketplace items in News Feed (bank, A, hard)

Say: "A smart engineer comes to you with an idea: show recommended Marketplace items in News
Feed. What do you do?"

Hidden:
- Not yes or no. Goals: Marketplace wants transactions; Feed wants meaningful content and ad
  revenue. Feed space is the most valuable inventory, so items push out friends' posts and ads.
- Users: buyers browsing, sellers wanting reach, Feed users who never shop.
- Hypothesis: If Feed shows relevant items, buyer-seller conversations rise without lowering Feed
  sessions or ad revenue.
- Test: a 1% holdout. Primary: Marketplace conversations started per Feed user per week.
  Guardrails: Feed sessions per user, ad revenue per user, hides and "see less".
- Prioritise against the backlog: reach and impact against effort; credit the engineer.
- Package: run the small test; ship if net conversations rise and Feed guardrails hold.

## Q6 Design an app for museums (bank, D, easy)

Say: "Design an app for museums."

Hidden:
- Clarify: for visitors, and whose business (the museum's own app). Museum goals: visits,
  memberships, donations.
- User groups: tourists with little time, families with kids, members and regulars, school
  groups, visitors needing accessibility. Pick tourists with little time: biggest group, deep pain.
- Pains: too big to know what to see in 90 minutes; queues; language; no context for what is in
  front of them.
- Solutions: "my 90 minutes" route with the must-sees; audio in my language; timed tickets.
  Launch first: the route with audio.
- North Star: share of app visitors who finish a route. Museum side: membership sign-ups or
  return visits within a year. Guardrails: crowding at highlights, complaints about phones.

## Q7 Any product: build its metrics dashboard (bank, B, medium)

Say: "Pick a product you know. You're the only PM on it. Build its metrics dashboard." If he
hesitates more than a few seconds: "Take Airbnb."

Hidden (Airbnb):
- Business questions: is the marketplace growing on both sides? Are guests finding stays (is it
  liquid)? Are we making money? Do stays go well?
- Top tile: nights booked and completed per month, not cancelled.
- Guest side: monthly bookers; search-to-booking rate (bookings ÷ search sessions, weekly).
- Host side: active listings with 1+ booked night in the month; host cancellation rate.
- Money: gross booking value and take rate, revenue per month.
- Quality: review score, guest complaints per 1,000 stays.
- Each tile: if it drops, the next check (city, new vs repeat, host or guest side).
- Trap: "Bookings up, host cancellations up. Good?" (the host side is the scarce one).

## Q8 Amazon: test a gift card for Prime app downloads (bank, A, hard)

Say: "How would you design a test to measure the success of a gift card promotion that gets
Prime members to download the Prime mobile app?"

Hidden:
- Goals: Amazon wants members in the app, where they buy more often; members want value.
- Design: randomise at member level, control gets no offer; maybe two offer sizes.
- Primary: incremental monthly active app users at day 60 per member offered, not downloads.
  Downstream: orders per member over 90 days.
- Guardrails: cost per incremental active app user against its value; web orders just moving to
  the app (not new spend); gift card abuse.
- Traps: "Downloads up five times. Success?" (download, redeem, delete). "Members who downloaded
  spend more." (selection; the control answers it).
- Window: read at 60 and 90 days, not at the end of the promotion.

## Q9 Facebook Lite: what goals would you set? (bank, A, easy)

Say: "You're the PM of Facebook Lite, the app for low-end phones and slow networks. What goals
would you set?"

Hidden:
- Goals: people on cheap phones and costly data want to stay in touch; business wants daily
  users in growth markets.
- Company NS: daily active people. Feature NS: share of new Lite installs still daily active at
  day 30, in target markets.
- Guardrails: data used per session, crash rate, load time on 2G, app size.
- Trap: "Lite daily actives up, main app daily actives down by the same amount." (moved, not grew).

## Q10 Facebook: improve grocery delivery (bank, D, medium)

Say: "How would you improve the grocery delivery experience for Facebook?"

Hidden (the bank answer's approach: clarify, goal, segment and persona, needs, brainstorm,
prioritise, design):
- Clarify: Facebook does not deliver; it connects people to local stores and couriers through
  Marketplace, Groups and local businesses.
- Goal: more local commerce through Facebook; user wants groceries with less time spent.
- Segment: working adults short on time (the bank answer's pick); also parents, the elderly.
- Pains: planning the shop, finding which local store delivers, repeat orders.
- Solutions: reorder last week's basket from a local store's page; a group order with
  neighbours; a meal plan to basket. Launch first: one-tap reorder from local store pages.
- North Star: weekly repeat grocery orders through Facebook per active buyer. Guardrail: store
  fulfilment errors, delivery complaints.
- Test: pilot with a few stores in one city.
