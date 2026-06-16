# Contributing a gadget

`claudisms` is a grab-bag of small, **self-contained** Claude Code tooling. There
is no build, no test harness, and no package manifest — a gadget is some
script(s) plus the prose that makes it portable. Keep that bar: if a newcomer
can't drop your gadget onto a fresh machine from its own directory, it isn't
done.

## Anatomy of a gadget

One gadget per subdirectory, containing the script(s) **and** a `README.md`. That
README is the gadget — it must explain three things, in this order of
importance:

1. **What it does** — and ideally a one-glance example of the output or effect.
2. **How to wire it in** — the exact install/config steps, copy-pasteable. If it
   hooks into a Claude Code surface (status line, hooks, settings, slash
   commands), link the official docs for that surface and follow *their* field
   names rather than guessing.
3. **Why the defaults are what they are** — this is **load-bearing, not
   optional**. The reasoning is what lets the next person tune it safely. If you
   change a threshold or behavior later, update the rationale to match.

Add a **Smoke test** section: the gadget has no harness, so show how to exercise
it by feeding it its real input (pipe a sample JSON object, run the hook, etc.)
and what correct output looks like. See `statusline-context-gauge/README.md` for
the pattern.

## Checklist for a new gadget

- [ ] Lives in its own top-level directory with a `README.md`.
- [ ] README covers what / how / **why**, plus a Smoke test.
- [ ] Scripts are executable (`chmod +x`) and start with a shebang.
- [ ] Dependencies stated. Shell gadgets target **bash** (keep it 3.2-safe so
      stock macOS works — no `mapfile`, no bash-4-only syntax) and may rely on
      `jq`; say so.
- [ ] No hardcoded personal paths — derive from `$HOME`/`~` so anyone can paste
      the install steps verbatim.
- [ ] Added a row to the top-level `README.md` Contents, under the section it
      fits (`Status line`, `tmux gadgets`, …) — or start a new section.
- [ ] Nothing machine- or account-specific. Site-specific scrapers, private
      services, and personal config don't belong here; the test is "would this
      help a stranger?"

## Style

Match the voice of the existing gadgets: opinionated, terse, and honest about
trade-offs. Document the *why* inline where it's load-bearing. Prefer one small
script that does one thing over a framework.
