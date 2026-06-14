Option Explicit

Dim shell
Set shell = CreateObject("WScript.Shell")

shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\Users\13403\Documents\Obsidian Vault\.obsidian\scripts\push-to-icloud.ps1""", 0, False
