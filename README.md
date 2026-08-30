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

Installs the `tui2notes` CLI into `~/.local/bin` and a small menu-bar agent
into `/Applications`, started at login through a LaunchAgent. Nothing beyond
what ships with macOS is required at runtime (`python3`, `textutil`,
`osascript`); building the agent needs the Xcode Command Line Tools.

## Use

**Just copy and paste.** The agent watches the clipboard. When a copy looks
like a table it rewrites the clipboard in place, so ⌘C and ⌘V stay exactly
what they were:

- paste into **Notes, Pages, Mail** -> a native table
- paste into a **terminal or editor** -> the original text, untouched

Both flavours are on the clipboard at once, so nothing is lost either way.
Text that is not a table is left alone; so is anything copied out of a
rich-text app.

The menu-bar icon toggles the watcher off, converts the clipboard on demand,
and shows how many tables it has converted.

**From the terminal**, without the agent:

```sh
tui2notes                    # convert whatever is on the clipboard
tui2notes --newnote < r.md   # skip the clipboard: create a new Apple Note
tui2notes --html             # print the intermediate HTML
```

## Permissions

The agent needs **none**. It synthesises no keystrokes and scripts no apps —
it only reads and writes the pasteboard, which macOS does not gate.

Two optional extras do need permission, and neither is installed by default:

| Extra | Needs |
|---|---|
| `--newnote` | Automation (Notes) |
| `./install.sh --applet` — click to paste at the cursor | Accessibility |

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

- **A pasteboard can hold several flavours at once.** The agent writes
  `public.rtf` *and* `public.utf8-plain-text`, so the same ⌘C serves both a
  word processor and a terminal. The CLI, older and simpler, replaces the
  clipboard with RTF alone; its plain-text flavour is then the RTF source, so
  it refuses to convert a second time.

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

Parser only — no clipboard, no GUI, no permissions. Run the agent with
`TUI2NOTES_DEBUG=1` to trace what it decides about each copy.

## License

MIT
