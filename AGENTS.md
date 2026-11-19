# Repository instructions

Follow [the documentation standard](docs/DOCUMENTATION.md) for first-person author voice throughout project documentation, factual changelogs, and naming the AI tool and verified model for each contribution.

This repository supports **World of Warcraft Forever exclusively**. Baseline: 1.60.1 / Interface 16001; reverify on client updates.

Before changes, read this file, `docs/DOCUMENTATION.md`, README, concept, roadmap, changelog, relevant Lua and TOC files; review branch, status, commits, and tags. Protect unrelated work.

Babuni controls concept, scope and public release decisions. Preserve existing user-confirmed behavior and avoid engine hacks that interfere with target selection, circle, target frame, combat or UI safety. Clearly distinguish verified Forever behavior from historical WoW references and untested guesses.

Document implementation, tests, limitations and AI contributions accurately. Development commits may be pushed, but **never tag, publish GitHub Release, or upload to CurseForge without explicit approval for that version**. No release is authorized currently.

## Human–AI collaboration record

`docs/AI_COLLABORATION.md` is the short record of how Babuni works with AI and who did what, with the same text in all of Babuni's repositories. Do not add dated entries, session notes or per-change attribution to it. Record each contribution in `docs/DEVLOG.md` (what Babuni asked for and what the AI did, naming the tool and model) and in `CHANGELOG.md`. Change `docs/AI_COLLABORATION.md` only to add a row to its "Who did what" table when a new AI tool or model starts contributing to this project, or when Babuni revises the shared text.

## Repository layout

The repository root holds only `README.md`, `AGENTS.md`, `LICENSE` and `CHANGELOG.md` (plus any additional license files). All other documentation lives in `docs/`; put new documents there.
