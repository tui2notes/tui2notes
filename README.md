# tui2notes

Terminal tables paste badly. `tui2notes` fixes that on macOS.

A TUI (Claude Code, `gh`, `psql`, `docker`, …) draws a table as monospace box
art. That art only holds together in a fixed-width font, so pasting it into
Apple Notes, Pages or Mail — which use a proportional font — turns it into
crooked garbage. Worse, the TUI wraps long cells across several lines, so even
the sentences are broken up.

`tui2notes` re-parses the box art back into a table, re-joins the wrapped
cells, and puts **rich text** on the clipboard. A plain <kbd>⌘V</kbd> then
produces a **native table** in the target app.

```
┌──────────────┬─────────────────────────────┬────────┐        ┏━━━━━━━━━┳━━━━━━━━━━━━━━┳━━━━━━━┓
│   package    │           status            │  time  │        ┃ package ┃ status       ┃ time  ┃
├──────────────┼─────────────────────────────┼────────┤   ->   ┡━━━━━━━━━╇━━━━━━━━━━━━━━╇━━━━━━━┩
│ core         │ ok — 214 tests passed, and  │ 12.4 s │        │ core    │ ok — 214 …   │ 12.4s │
│              │ coverage held at 91%        │        │        └─────────┴──────────────┴───────┘
└──────────────┴─────────────────────────────┴────────┘         (a real table object, not text)
```

Markdown pipe tables work too, and so does the surrounding prose: headings,
bullets, `**bold**` and `` `code` `` all survive.

## Install

```sh
git clone https://github.com/thomaslwang/tui2notes
cd tui2notes && ./install.sh
```

That puts the `tui2notes` CLI in `~/.local/bin` and a clickable
`tui2notes.app` in `/Applications`. No dependencies beyond what ships with
macOS (`python3`, `textutil`, `pbpaste`, `osascript`).

## Use

**From the terminal** — copy the table, then:

```sh
tui2notes          # convert the clipboard; now just ⌘V in Notes
```

**From the Dock** — drag `tui2notes.app` there and click it after copying.
It converts the clipboard, brings Notes forward and pastes for you.

**Straight into a new note** — no clipboard round-trip:

```sh
tui2notes --newnote < report.md
```

Other flags: `--html` prints the intermediate HTML, `--help` explains itself.

## Permissions

| What you click | Needs | If denied |
|---|---|---|
| `tui2notes` in a terminal | nothing | — |
| `tui2notes.app` | Automation (Notes) | it reports the error |
| …to paste at the cursor | Accessibility | falls back to creating a new note |

The Accessibility requirement comes from synthesising ⌘V. Grant it under
**System Settings → Privacy & Security → Accessibility**, or just live with
the fallback — `--newnote` needs no such permission because it hands the HTML
to Notes directly.

## Notes on the implementation

Three things are less obvious than they look:

- **`pbcopy` cannot put rich text on the clipboard.** It files RTF as plain
  text, so the paste comes out as `{\rtf1\ansi…`. Setting the RTF flavour
  needs `osascript … as «class RTF »`.
- **Cells wrap, so a physical line is not a row.** Rows are delimited by the
  horizontal rules; every content line between two rules belongs to the same
  logical row and its fragments are re-joined per column.
- **Re-joining is language-sensitive.** `24.7` + `KiB/行（26.4` + `万行）`
  must become `24.7 KiB/行（26.4万行）`: a space between latin tokens, none
  between a digit and a CJK unit, none between two CJK characters.

Once converted, the clipboard holds RTF whose *plain-text* flavour is the RTF
source. Running the tool twice would therefore try to convert `{\rtf1…`, so it
detects that and stops.

## Optional: a Services entry

```sh
python3 services/build-services.py
```

Adds a Quick Action, mostly useful as a hook for a global shortcut in
**System Settings → Keyboard → Keyboard Shortcuts → Services**. Note that
Apple Notes does not show a Services submenu in its right-click menu, so this
will not give you a right-click item there.

## Tests

```sh
bash test/run-tests.sh
```

Parser only — no clipboard, no GUI, no permissions.

## License

MIT
