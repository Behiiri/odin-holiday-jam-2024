@echo off
cd /D "%~dp0"

pushd bin
odin build ../src -out:game.exe
popd
