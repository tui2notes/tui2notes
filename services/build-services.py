#!/usr/bin/env python3
"""Build the optional macOS Quick Action (Services menu) for tui2notes."""
import os, plistlib, subprocess, sys, shutil

HOME = os.path.expanduser("~")
SERVICES = os.path.join(HOME, "Library", "Services")


def uu():
    return subprocess.run(["uuidgen"], capture_output=True, text=True).stdout.strip()


def build(bundle, menu_name, command, send_text):
    path = os.path.join(SERVICES, bundle + ".workflow")
    if os.path.exists(path):
        shutil.rmtree(path)
    os.makedirs(os.path.join(path, "Contents"))

    svc = {
        "NSMenuItem": {"default": menu_name},
        "NSMessage": "runWorkflowAsService",
        "NSSendFileTypes": [],
        "NSSendTypes": ["NSStringPboardType"] if send_text else [],
    }
    with open(os.path.join(path, "Contents", "Info.plist"), "wb") as f:
        plistlib.dump({"NSServices": [svc]}, f)

    action = {
        "action": {
            "AMAccepts": {
                "Container": "List",
                "Optional": True,
                "Types": ["com.apple.cocoa.string"],
            },
            "AMActionVersion": "2.0.3",
            "AMApplication": ["Automator"],
            "AMParameterProperties": {
                "COMMAND_STRING": {},
                "CheckedForUserDefaultShell": {},
                "inputMethod": {},
                "shell": {},
                "source": {},
            },
            "AMProvides": {"Container": "List", "Types": ["com.apple.cocoa.string"]},
            "ActionBundlePath": "/System/Library/Automator/Run Shell Script.action",
            "ActionName": "Run Shell Script",
            "ActionParameters": {
                "COMMAND_STRING": command,
                "CheckedForUserDefaultShell": True,
                "inputMethod": 0,          # 0 = 作为 stdin 传入
                "shell": "/bin/zsh",
                "source": "",
            },
            "BundleIdentifier": "com.apple.Automator.RunShellScript",
            "CFBundleVersion": "2.0.3",
            "CanShowSelectedItemsWhenRun": False,
            "CanShowWhenRun": True,
            "Category": ["AMCategoryUtilities"],
            "Class Name": "RunShellScriptAction",
            "InputUUID": uu(),
            "Keywords": ["Shell", "Script", "Command", "Run", "Unix"],
            "OutputUUID": uu(),
            "UUID": uu(),
            "UnlocalizedApplications": ["Automator"],
            "arguments": {},
            "isViewVisible": 1,
            "location": "309.000000:253.000000",
            "nibPath": "/System/Library/Automator/Run Shell Script.action/"
                       "Contents/Resources/Base.lproj/main.nib",
        },
        "isViewVisible": 1,
    }

    wflow = {
        "AMApplicationBuild": "521",
        "AMApplicationVersion": "2.10",
        "AMDocumentVersion": "2",
        "actions": [action],
        "connectors": {},
        "workflowMetaData": {
            "serviceInputTypeIdentifier": "com.apple.Automator.text"
            if send_text
            else "com.apple.Automator.nothing",
            "serviceOutputTypeIdentifier": "com.apple.Automator.nothing",
            "serviceProcessesInput": 0,
            "workflowTypeIdentifier": "com.apple.Automator.servicesMenu",
        },
    }
    with open(os.path.join(path, "Contents", "document.wflow"), "wb") as f:
        plistlib.dump(wflow, f)
    print("built", path)


# Optional: a Services (right-click) entry, mainly useful as a hook for a
# global keyboard shortcut in System Settings > Keyboard > Keyboard Shortcuts.
# Note: Apple Notes does NOT show a Services submenu in its context menu.
if __name__ == "__main__":
    bin_path = sys.argv[1] if len(sys.argv) > 1 else \
        os.path.join(HOME, ".local", "bin", "tui2notes")
    build("tui2notes", "tui2notes",
          '"%s"\n/usr/bin/osascript -e \'tell application "System Events" '
          'to keystroke "v" using command down\'' % bin_path,
          send_text=True)
    subprocess.run(["/System/Library/CoreServices/pbs", "-flush"])
    print("Installed. Enable it in System Settings > Keyboard > "
          "Keyboard Shortcuts > Services.")
