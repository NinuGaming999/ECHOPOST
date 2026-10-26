@echo off
setlocal
where godot >nul 2>nul
if errorlevel 1 (
  echo Godot was not found in PATH.
  echo Install Godot 4.x or run this command with the full path to Godot.exe:
  echo godot --headless --path . --script res://tests/headless_smoke.gd
  pause
  exit /b 1
)
godot --headless --path . --script res://tests/headless_smoke.gd
if errorlevel 1 (
  echo One or more ECHOPOST smoke tests failed. See output above.
  pause
  exit /b 1
)
echo ECHOPOST smoke tests passed.
pause
