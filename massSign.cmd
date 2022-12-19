@echo off
@REM if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
SETLOCAL
set PASSWORD=
set IB=C:\Users\user\Documents\MassSign\InputBox.exe
set PROGRAM_FOLDER=C:\Program Files\JSignPdf
set DESTINATION=%~dp1
IF %DESTINATION:~-1%==\ SET DESTINATION=%DESTINATION:~0,-1%
set PDF_FILES=
set CERT=7b491149-215b-489f-8e57-de904b32ec1b

@REM Κάνε έλεγχο για τα προγράμματα
if exist "%IB%" goto :checkjava
echo InputBox.exe not found
goto :error

:checkjava
if exist "%PROGRAM_FOLDER%\jre\bin\java.exe" goto :allprogok
echo "java.exe not found"
goto :error

:allprogok
for /F %%I in ('@%IB% /P /S "Enter PIN:" "Mass sign pdf"') do @set "PASSWORD=%%I"
if defined PASSWORD goto :step2
echo Password is not defined
goto :end

:step2
@REM Δοκίμασε να διαβάσεις το κλειδί και σταμάτησε αν αποτύχεις. Για να αποφύγουμε να σπαταλήσουμε όλες τις δοκιμές pin στην περίπτωση λάθος κωδικού
"%PROGRAM_FOLDER%\jre\bin\java.exe" -Duser.language=en -jar "%PROGRAM_FOLDER%\JSignPdf.jar" -kst JSIGNPKCS11 -ksp %PASSWORD% -lk
if %errorlevel% NEQ 0 goto :error

:loop
if "%~1" == "" goto :exitloop

for /f "delims=" %%i in ("%~1") do set MYPATH="%%~fi"
pushd %MYPATH% 2>nul
if errorlevel 1 goto notdir
goto isdir

:notdir
set PDF_FILES=%PDF_FILES% "%~1"
goto :next

:isdir
popd
set FOLDER=%~1
set FOLDER_FILES="%~1\*.pdf"
@REM Υπέγραψε τα αρχεία μέσα στους φακέλους
"%PROGRAM_FOLDER%\jre\bin\java.exe" -Duser.language=en -jar "%PROGRAM_FOLDER%\JSignPdf.jar" -lp -kst JSIGNPKCS11 -ksp %PASSWORD% -kp %PASSWORD% -d "%FOLDER%" %FOLDER_FILES%
if %errorlevel% NEQ 0 goto :error
goto :next

:next
shift
goto :loop

:exitloop
if defined PDF_FILES goto :step3
goto :end

:step3
@REM Τέλος υπέγραψε τα αρχεία που δεν βρίσκονται σε φάκελο
"%PROGRAM_FOLDER%\jre\bin\java.exe" -Duser.language=en -jar "%PROGRAM_FOLDER%\JSignPdf.jar" -lp -kst JSIGNPKCS11 -ksp %PASSWORD% -kp %PASSWORD% -d "%DESTINATION%" %PDF_FILES%
if %errorlevel% NEQ 0 goto :error
goto :end

:error
echo An error occured! - %errorlevel%
pause

:end
ENDLOCAL