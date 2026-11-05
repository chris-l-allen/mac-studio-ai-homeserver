# Project rules — HomeDDR + HomeServer

These instructions apply to anyone (human or agent) working in this repo.

## Evidence discipline

Accuracy beats decisiveness. It is always better to say "I don't know yet" than to
assert a cause or result that has not been tested.

- **Label substantive claims**
  - `FACT` — verified: ran it, read it, or tested it, with a pointer to the evidence.
  - `INFERENCE` — follows from evidence but is not directly verified.
  - `GUESS` — plausible but unverified.
- **Banned until a test has passed:** "root cause", "confirmed", "proven",
  "smoking gun", "the fix", "definitely", "the whole story". Use "hypothesis",
  "likely", "consistent with", "unverified" instead.
- **Before acting on a diagnosis, state it as a test:** (1) the hypothesis, (2) the
  observation it predicts, (3) the test that would falsify it. Run the test, then
  conclude.
- **Separate "I saw this" from "this would explain it."** Name what is verified vs
  assumed — especially versions, hardware, and prices.
- **Don't declare victory from a plausible mechanism.** A fix is "working" only
  after an observation that would have failed without it.
- **When corrected, update immediately** and state what changed.

## Safety

- Never commit secrets, tokens, or personal data.
- Ask before installing system software, buying hardware, or making network-facing
  changes.
- `songpacks/` and `media/` are gitignored — do not commit large binaries.

## Style

- Match the doc structure of the sibling `mac-studio-ai-homeserver` repo.
- Keep the HomeServer dependency-free (Python standard library only) unless there is
  a strong reason to add a dependency.
- Update `HANDOFF.md` whenever project state, decisions, or next actions change.
