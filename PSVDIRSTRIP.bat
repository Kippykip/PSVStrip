@echo off
%~d0
cd "%~dp0"
md PSVExport
psvstrip -dirstrip "%1" PSVExport
pause
