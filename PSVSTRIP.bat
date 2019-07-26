@echo off
%~d0
cd "%~dp0"
psvstrip -psvstrip "%1" "%~d1%~p1%~n1_strip.psv"
pause
