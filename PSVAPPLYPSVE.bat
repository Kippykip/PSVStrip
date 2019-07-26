@echo off
echo PSVStrip: Apply PSVE Restoration
set /p psvpath=Location of PSV file?: 
set /p psvepath=Location of PSVE file?: 
set /p psvexportpath=Export path of restored PSV file?: 
echo %psvpath%
echo The following command will execute:
echo psvstrip -applypsve "%psvpath%" "%psvexportpath%" "%psvepath%"
pause
cls
psvstrip -applypsve "%psvpath%" "%psvexportpath%" "%psvepath%"
pause