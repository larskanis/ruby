ECHO ON
SETLOCAL ENABLEDELAYEDEXPANSION

SET BITS=%Platform:x86=32%
SET BITS=%BITS:x=%
SET OPENSSL_DIR=c:\OpenSSL-Win%BITS%
CALL SET vcvars=%%^VS%VS%COMNTOOLS^%%..\..\VC\vcvarsall.bat
SET vcvars
CALL "%vcvars%" %Platform:x64=amd64%
SET ruby_path=C:\Ruby%ruby_version:-x86=%
SET PATH=\usr\local\bin;%ruby_path%\bin;%ruby_path%\Devkit\mingw\bin;%PATH%;C:\msys64\usr\bin

GOTO %1

:install_script
chcp
ruby --version
'cl'
SET
echo> Makefile srcdir=.
echo>> Makefile MSC_VER=0
echo>> Makefile RT=none
echo>> Makefile RT_VER=0
echo>> Makefile BUILTIN_ENCOBJS=nul
type win32\Makefile.sub >> Makefile
nmake %mflags% touch-unicode-files || GOTO failure
nmake %mflags% up incs UNICODE_FILES=. || GOTO failure
del Makefile || GOTO failure
mkdir \usr\local\bin || GOTO failure
mkdir \usr\local\include || GOTO failure
mkdir \usr\local\lib || GOTO failure
appveyor DownloadFile https://downloads.sourceforge.net/project/libpng/zlib/%zlib_version%/zlib%zlib_version:.=%.zip || GOTO failure
7z x -o%APPVEYOR_BUILD_FOLDER%\ext\zlib zlib%zlib_version:.=%.zip || GOTO failure
for %%I in (%OPENSSL_DIR%\*.dll) do mklink /h \usr\local\bin\%%~nxI %%I
mkdir %Platform%-mswin_%vs% || GOTO failure
powershell -Command "Get-ChildItem 'win32' -Recurse | foreach {$_.Attributes = 'Readonly'}" || GOTO failure
powershell -Command "Get-Item $env:Platform'-mswin_'$env:vs | foreach {$_.Attributes = 'Normal'}" || GOTO failure
GOTO success


:build_script
cd %APPVEYOR_BUILD_FOLDER%\%Platform%-mswin_%vs%
CALL ..\win32\configure.bat --without-ext=+,dbm,gdbm,readline --with-opt-dir=/usr/local --with-openssl-dir=%OPENSSL_DIR:\=/% || GOTO failure
nmake -l || GOTO failure
nmake install-nodoc || GOTO failure
\usr\bin\ruby -v -e "p :locale => Encoding.find('locale'), :filesystem => Encoding.find('filesystem')" || GOTO failure
GOTO success


:test_script
cd %APPVEYOR_BUILD_FOLDER%\%Platform%-mswin_%vs%
SET /a JOBS=%NUMBER_OF_PROCESSORS%
nmake -l "TESTOPTS=-v -q" btest || GOTO failure
nmake -l "TESTOPTS=-v -q" test-basic || GOTO failure
nmake -l "TESTOPTS=-q -j%JOBS% --show-skip" test-all || GOTO failure
nmake -l "MSPECOPT=-j" test-spec || GOTO failure
GOTO success

:failure
EXIT /B 1

:success
EXIT /B 0
