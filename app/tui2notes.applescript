-- tui2notes.app — click it (from the Dock) after copying a table.
--
-- Preferred path: convert the clipboard, then synthesise Cmd-V so the table
-- lands at the cursor. That needs Accessibility permission.
-- Fallback: if the keystroke is refused, create a new note instead, which
-- needs only Automation permission.
set tui2notes to quoted form of "__TUI2NOTES_BIN__"
set orig to (the clipboard as text)

try
	do shell script tui2notes
on error errMsg
	display notification errMsg with title "tui2notes failed"
	return
end try

tell application id "com.apple.Notes" to activate
delay 0.3
try
	tell application "System Events" to keystroke "v" using command down
on error
	try
		do shell script "printf '%s' " & quoted form of orig & " | " & tui2notes & " --newnote"
		display notification "No Accessibility permission — created a new note instead" with title "tui2notes"
	on error errMsg2
		display notification errMsg2 with title "tui2notes failed"
	end try
end try
