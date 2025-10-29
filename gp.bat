@echo off

for %%i in (%random%) do git add --all && git commit -m %%i && git push origin master