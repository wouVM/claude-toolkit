# Quiz bank

Ask the Q; keep the A hidden until he answers. Ids are stable, the log records missed ones.
Sources: Luke Filipos's PM group calls (October 2026) and his metrics page. Luke's
21.10 call.

## North Star and Luke's five criteria

T1. Q: Name Luke's five criteria for a North Star.
A: Customer value, company strategic value, influence, responsiveness, resistance to gaming.

T2. Q: What does "customer value" mean as a criterion?
A: The metric rises only when the end user gets real value, not when they merely click or spend time.

T3. Q: What is "strategic value"? Give Luke's example of high customer value, low strategic value.
A: It matters for the company's business. "We could give cards away free": customers love it, the company gains nothing.

T4. Q: What is "influence"?
A: How directly the team controls it: the gas pedal, not the speedometer. Stock price scores 1. Score relative to the other candidates.

T5. Q: What is "responsiveness", and what is the Goldilocks zone?
A: It moves soon after what we do, but is not so noisy we cannot tell why. Too slow arrives after the decision; too noisy hides the cause.

T6. Q: What is "resistance to gaming"? Give Luke's example.
A: Hard to raise without real value. "A junior PM told to raise conversion drops the bad customers."

T7. Q: How do you make a metric harder to game in its very name?
A: Put the anti-gaming word in it: "paid certified patients", "steady paying customers" (group call 14.10).

T8. Q: Why is revenue usually not the product North Star?
A: It lags and can rise through price or discounts without the product getting better. It stays the business outcome above the North Star.

T9. Q: Does the North Star depend on company stage?
A: Yes. A new company needs people in (acquisition, activation); a mature one like Netflix watches churn.

## GAME and interview shape

T10. Q: What does GAME stand for?
A: Goals, Actions, Metrics, Execution.

T11. Q: What goes into Goals, and in what order?
A: The business goal and the customer's goal in plain English, then the feature's goal. Before any metric.

T12. Q: What goes into Metrics in GAME?
A: List candidates, organise them into the funnel, pick the one closest to the user goal with the most business influence. Name the company North Star and the feature metric apart.

T13. Q: What goes into Execution, and how long should it take to say?
A: Hypothesis, guardrails, what you do if a guardrail moves. 30 to 60 seconds.

T14. Q: Luke's takeaway from the 21.10 grill, in one line?
A: Stay on end business value and end user value; don't over-complicate; keep the hypothesis simple.

T15. Q: "Company North Star or feature metric?" What is the right answer?
A: Both. The company has one L1; each feature has its own L1 that ladders into it.

## Metric roles

T16. Q: Name the seven metric roles on Luke's page.
A: Business outcome, product North Star, initiative outcome, input, guardrail, diagnostic, delivery output.

T17. Q: What is a guardrail?
A: A metric that must not get worse while you push the primary one (cost, errors, cancellations).

T18. Q: What is a diagnostic metric?
A: One that explains where or why performance differs (a step's failure rate, a segment), not one you steer by.

T19. Q: Is "we shipped the new onboarding flow" an outcome?
A: No, a delivery output: it records work. "More customers reached first value" records an effect.

T20. Q: Input or output: is retention an input or an output?
A: Both. Input and output are relative: retention is an output of the experience and an input to the future customer base.

T21. Q: Leading vs lagging: give an example of each for a subscription product.
A: Leading: weekly engagement (drops before revenue). Lagging: revenue, NPS (after the money event).

T22. Q: Metric vs target?
A: The metric has no number in it ("share of chats scored 7 or lower, per month"). The target is a separate statement with its own reason ("10% by December").

T23. Q: What is a composite metric, and its risk?
A: Several measures blended into one score. Risk: opaque, nobody can say what moved it (fails clarity).

## Defining a metric

T24. Q: What four parts does a metric definition need?
A: Unit, population, event, window, so someone else can reproduce it.

T25. Q: Why put the time window in the metric's name?
A: A rate per period ("per month") shows performance against the last period; a cumulative total always rises and hides decline. Totals only for company milestones.

T26. Q: Rate or level: when do you use which?
A: Rate when the question is a share (staff-booked ÷ all booked); level or count when it is volume. Often report a level with its rate beside it.

T27. Q: Zero eligible accounts this week: is the rate zero?
A: No, undefined. And never drop accounts from the denominator just because they produced no event.

T28. Q: Per passenger or per booking for mobile check-in, and why?
A: Per passenger: a booking holds several people, and per booking hides half-checked-in groups.

## Trees and reading numbers

T29. Q: What do the arrows [A], [P] and [C] mean in a metric tree?
A: Arithmetic identity, prediction (correlation, may be selection), causal hypothesis that needs a test.

T30. Q: What is mix shift?
A: The total moves because the share of segments changed, not because any segment's behaviour changed. Completions up, valid outcome flat.

T31. Q: What is survivorship in an average? Use Burger Dash.
A: The average is over those who stayed. AOV rises because small orders abandon at the upsell screen; count everyone who started checkout.

T32. Q: How do you read seasonality?
A: Compare with the month before (MoM) and the same period a year earlier (YoY), as diagnostics, so a season is not read as churn.

T33. Q: Luke's "how do you know?" holds two questions. Which?
A: How do I know it is a problem (evidence: a count over a denominator) and why it is a problem (the consequence).

T34. Q: What is an "unreliable narrator" in metrics?
A: A source that reports its own success, like a chatbot transcript saying "booked". Check the record of truth (the reservation system).

T35. Q: Foundation, speedometer, funnel: what is the order and why?
A: Foundation: data you trust and agreed definitions. Speedometer: the one North Star read every period. Funnel: the steps beneath it, to find where it leaks. Each needs the one before.

T36. Q: When is a Sankey diagram the right picture?
A: When you show flow between states (stage to stage, kept, lost, recovered), so leaks and their size are visible at once.

T37. Q: Your North Star drops 12% week on week. What is the check order?
A: Is it real (tracking, definitions), seasonality (YoY, MoM, holidays), external events, segments, funnel step, internal releases or experiments; then a hypothesis and a decision.

## Hypothesis and execution

T38. Q: Say Luke's interview hypothesis format.
A: "If we do X, Y improves without hurting Z."

T39. Q: Say the page's longer hypothesis format.
A: "If we change X for this group, Y should improve because Z", with primary metric, baseline, population, window, guardrails and the result that justifies the next step.

T40. Q: Output vs outcome, in one line?
A: Output is what the team made; outcome is the change in customer behaviour or business result it caused.

T41. Q: A guardrail moves the wrong way in your test. What do you do?
A: Decide in advance: a threshold that pauses or rolls back, then diagnose by segment before relaunching. Never redefine the guardrail after the fact.

T42. Q: Another team improved the algorithm and your button clicks stayed flat. Success?
A: Judge by the outcome the button served, not clicks. If the user goal metric rose, fine; clicks were an input.

## Product sense and prioritising (Luke 23.10)

T43. Q: Name the three interview question types Luke described.
A: Behavioral (tell me about a time), analytical thinking or execution (define success, pick the metric), product sense (build X for Y).

T44. Q: What is Luke's chain for a product-sense question?
A: Business goals, user groups, pain points, solutions; then the success metric, hypothesis and test.

T45. Q: Two ways to slice user cohorts, besides "seniors"?
A: Demographics (age, location, income) and needs (weekly medical trips, trouble with tech). Location includes coverage: is there supply where they live?

T46. Q: How do you prioritise user groups?
A: A 2x2: how big the group is by how much it matters to the core business.

T47. Q: How do you prioritise pain points, and where does a rare but catastrophic one go?
A: How widespread by how deeply felt; the sweet spot is many people feeling it deeply. A low-frequency, high-impact pain (trust and safety) becomes a guardrail.

T48. Q: How do you prioritise solutions?
A: How many it helps and how much, against the lift to build it; then launch one first and say why.

T49. Q: You assume seniors are not tech-savvy. How do you say that in an interview?
A: As an assumption about a share: "we assume a large enough share is like this to focus on, and we would validate it". Some seniors are tech-savvy.

T50. Q: What does a two-sided marketplace oblige you to cover in every answer?
A: The other side: what drivers (hosts, sellers) get, with guardrails such as acceptance rate and earnings per hour. Without supply there is no business.

T51. Q: For Uber seniors, why does "share of activated 65+ riders with 4+ completed trips a month" beat "rides booked"?
A: Completed, not booked; and a rate over activated riders shows a habit, while a level of bookings can rise from a few heavy users or one-off caregiver bookings.

T52. Q: What is the cheapest way to test a new senior product before building it?
A: A/B a small version (simple mode) with seniors already on the app, or a one-city pilot.

## Dashboards (Luke 22.10)

T53. Q: First step in designing an executive dashboard?
A: The business questions it must answer, ranked. Then one metric per question, most important on top, working down.

T54. Q: What test must every tile pass?
A: If it moves, you know the next thing you would check and what you would do; and it moves enough to matter. Total costs fail.

T55. Q: Define conversion rate.
A: Completions divided by attempts, over a set window. It needs a funnel with a start step.

T56. Q: What is ARPU?
A: Average revenue per user: revenue in the period divided by all users in the period, free ones included.

T57. Q: Listening time per user or per active user, and why?
A: Per user. Per active user hides people dropping off, and can rise while many go inactive.

T58. Q: How do you compare engagement across songs, podcasts and books?
A: Time listened per user per period, not plays or items; plays favour short songs.

T59. Q: Why did active users belong above paid subscribers on the 22.10 Spotify dashboard?
A: Free users bring ad revenue too, so the audience is the wider engine; subscribers sit below it.

T60. Q: What second funnel does an ad business have?
A: Advertisers: acquiring and keeping the businesses that buy ad space, not only listeners seeing ads.
