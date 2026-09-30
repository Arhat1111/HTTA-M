@echo off
cd /d "%~dp0"
echo HTTA Supabase Login Test
echo Open http://localhost:8080 in your browser.
py -m http.server 8080
pause
