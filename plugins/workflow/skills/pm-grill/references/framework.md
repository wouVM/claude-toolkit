# Luke's framework, compact

The method behind the grill and the quiz, as Luke Filipos teaches it. Section numbers (s1 to s7)
are what `terms.md` cites.

## s1 GAME, the interview shape

1. Goals: the business goal and the customer's goal in plain English, then the feature's goal.
   Before any metric.
2. Actions: what users do, step by step; the funnel.
3. Metrics: list candidates, organise them into the funnel, pick the one closest to the user goal
   with the most business influence. Name the company North Star and the feature metric apart:
   the company has one North Star, and each feature has its own primary metric that ladders into it.
4. Execution: hypothesis, guardrails, what you do if a guardrail moves. 30 to 60 seconds.

Takeaway: stay on end business value and end user value; do not over-complicate; keep the
hypothesis simple.

## s2 The five North Star criteria

Score each candidate 1 to 3, relative to the other candidates (revenue is the usual comparison).

- Customer value: it rises only when the end user gets real value, not when they merely click or
  spend time.
- Strategic value: it matters for the company's business. High customer value with low strategic
  value: "we could give cards away free". Customers love it; the company gains nothing.
- Influence: how directly the team controls it, the gas pedal, not the speedometer. Stock price
  scores 1.
- Responsiveness: it moves soon after what the team does, but is not so noisy nobody can tell why
  (the Goldilocks zone). Too slow arrives after the decision; too noisy hides the cause.
- Resistance to gaming: hard to raise without real value. "A junior PM told to raise conversion
  drops the bad customers." Put the anti-gaming word in the metric's name ("paid", "steady",
  "completed", "honoured").

Revenue is usually not the product North Star: it lags and can rise through price or discounts
without the product getting better. It stays the business outcome above the North Star. The right
North Star depends on company stage: a new company needs people in (acquisition, activation), a
mature one watches churn.

## s3 Metric roles

- Business outcome: the money result (revenue, margin).
- Product North Star: the one metric that best captures value delivered, read every period.
- Initiative outcome: the change one initiative is meant to cause.
- Input: a lever that drives the North Star.
- Guardrail: must not get worse while you push the primary metric (cost, errors, cancellations).
- Diagnostic: explains where or why performance differs (a step's failure rate, a segment); you do
  not steer by it.
- Delivery output: records work done ("we shipped the flow"), not an effect.

Input and output are relative: retention is an output of the experience and an input to the future
customer base. Leading metrics move before the money event (weekly engagement); lagging ones after
it (revenue, NPS). A composite metric blends several measures into one score; its risk is that
nobody can say what moved it.

## s4 Defining a metric

- Four parts: unit, population, event, window, so someone else can reproduce it.
- Put the window in the name ("per month"). A rate per period shows performance against the last
  period; a cumulative total always rises and hides decline. Totals only for company milestones.
- Rate when the question is a share, level or count when it is volume. Often report a level with
  its rate beside it.
- Zero eligible units in a period: the rate is undefined, not zero. Never drop units from the
  denominator because they produced no event.
- Metric and target are separate: the metric has no number in it; the target is its own statement
  with its own reason ("10% by December").

## s5 Trees and reading numbers

- Metric tree arrows: [A] arithmetic identity, [P] prediction (correlation, may be selection),
  [C] causal hypothesis that needs a test.
- Mix shift: the total moves because the share of segments changed, not because any segment's
  behaviour did.
- Survivorship in an average: the average is over those who stayed; count everyone who started.
- Seasonality: compare with the period before (MoM) and the same period a year earlier (YoY), as
  diagnostics, so a season is not read as churn.
- Unreliable narrator: a source that reports its own success (a bot transcript saying "booked").
  Check the record of truth.
- "How do you know?" holds two questions: how do I know it is a problem (a count over a
  denominator) and why it is a problem (the consequence).
- Order of work: foundation (data you trust, agreed definitions), speedometer (the one North Star
  read every period), funnel (the steps beneath it, to find the leak). Each needs the one before.
- A Sankey diagram fits when you show flow between states (kept, lost, recovered).

## s6 The diagnostic drill

North Star dropped week on week: is it real (tracking, definitions, data loads), seasonality,
external events, segments, funnel step, internal releases or experiments; then a hypothesis and a
decision. Say what each check rules out and stop at the first one that explains it.

## s7 Hypothesis and execution

- Interview format: "If we do X, Y improves without hurting Z."
- Long format: "If we change X for this group, Y should improve because Z", with primary metric,
  baseline, population, window, guardrails and the result that justifies the next step.
- Output vs outcome: output is what the team made; outcome is the change in customer behaviour or
  business result it caused.
- A guardrail moves the wrong way: decide the threshold in advance (pause or roll back), diagnose
  by segment before relaunching, never redefine the guardrail after the fact.
