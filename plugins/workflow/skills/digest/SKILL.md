---
name: digest
description: >
  Dispatch a cheap scout to read a long document (a PDF, a transcript, a deck, a spec, a folder of
  notes, a web page) and return the findings, instead of pulling the whole thing into the
  coordinator's context. Load this whenever the next move is "let me read that" and the thing is
  long: the user drops a PDF or transcript, points at a doc to extract from, asks what a file or a
  page says, or asks you to compare several documents. Extraction is not judgment, so it belongs on
  the cheap model. NOT for reading the 2-3 source files a change actually touches, and not for a
  diff you are reviewing - those are the coordinator's own job.
---

# /digest - read the long thing on the cheap model

ELI16 first: a role fence can stop a coordinator from EDITING build code, because an edit is an unambiguous
boundary. It cannot stop it from READING, because reviewing a diff is the coordinator's real job and blocking
reads would break it. So the read side has no mechanism, only this: a pre-written paragraph that makes
delegating a long read cheaper than doing it.

**Reading a 30-page PDF as rendered images, or a 1,200-line transcript, on the coordinating model is the most
expensive way to learn what a document says.** It is extraction: find the claims, quote the load-bearing
lines, report. That is scout work, and the answer comes back in a page instead of a context window.

## When this fires

Reach for it BEFORE the first Read, whenever the thing is long and the goal is to know what it says:
- a PDF, deck, or scanned document (worst case: PDF pages arrive as images, the priciest tokens there are)
- a meeting transcript or call notes
- a folder of documents to survey or compare
- a long web page or a doc-set to answer a specific question from
- a big file whose STRUCTURE you need before deciding what matters

Do NOT use it for: the handful of source files a change actually touches, a diff under review, a short file,
or anything where your own judgment of nuance in the raw text is the point. If you would quote it line by
line in your answer, read it yourself.

## The dispatch

Use this plugin's `explorer` agent (already pinned to a cheap model and read-only), or any scout, with a
prompt that names the QUESTION and the SHAPE of the answer. A scout told only "summarize this" returns a
summary you cannot act on:

> Read `<path or URL>`. Do not read anything else, and do not edit anything.
>
> WHAT I NEED FROM IT: `<the specific question, or the list of things to extract>`
>
> REPORT BACK:
> - The answer to the question above, first, in a few sentences.
> - The load-bearing quotes VERBATIM, with a page or line reference for each. Do not paraphrase the
>   evidence - the quotes are the point.
> - Anything in the document that contradicts itself, or contradicts `<what I believe>`.
> - What you did NOT cover, and where your reading was thin.
>
> Do not summarize away the specifics. Names, numbers, dates and exact wording survive; adjectives do not.

For several documents, dispatch one scout per document in a single message so they run in parallel, then do
the synthesis yourself: comparing sources IS judgment, and it is yours.

## What comes back, and what you do with it

The scout's report is evidence, not truth. Two habits keep it honest:
- **Check the negatives.** "Nothing in the document covers X" is the claim most worth a second look, because
  a scout that missed a section reports the same sentence as a scout that read it all.
- **Quotes or it did not happen.** A finding with no verbatim line behind it is the scout's impression. Ask
  for the line before you build on it.

Then the synthesis, the judgment, and the decision are the coordinator's, on the coordinator's model. That
split is the whole point: cheap model reads, expensive model decides.
