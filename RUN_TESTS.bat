@echo off
setlocal
where godot >nul 2>nul
if errorlevel 1 (
  echo Godot was not found in PATH.
  echo Install Godot 4.x or run these commands with the full path to Godot.exe:
  echo godot --headless --path . --script res://tests/headless_smoke.gd
  echo godot --headless --path . --script res://tests/game_flow_smoke.gd
  pause
  exit /b 1
)
echo Running data-layer smoke tests...
godot --headless --path . --script res://tests/headless_smoke.gd
if errorlevel 1 goto failed
echo Running gameplay integration smoke tests...
godot --headless --path . --script res://tests/game_flow_smoke.gd
if errorlevel 1 goto failed
echo All ECHOPOST smoke tests passed.
pause
exit /b 0
:failed
echo One or more ECHOPOST smoke tests failed. See output above.
pause
exit /b 1
