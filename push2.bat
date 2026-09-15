@echo off
chcp 65001 >nul
title 命令循环执行器
color 0A

echo 循环执行命令示例
echo ================================

REM 示例1：有限循环（执行50次）
set TOTAL_LOOPS=50
echo 开始有限循环，共执行 %TOTAL_LOOPS% 次


for /l %%i in (1,1,%TOTAL_LOOPS%) do (
    echo [%%i/%TOTAL_LOOPS%] 正在执行命令...
    REM 在此处替换为你需要执行的命令
    REM dir . | findstr "txt" >nul
    git push --set-upstream origin pulsar
    
    REM 检查上一个命令是否执行成功
    if !errorlevel! equ 0 (
        echo 状态：成功
    ) else (
        echo 状态：失败
    )
    
    REM 如果不是最后一次循环，则等待3秒
    if %%i lss %TOTAL_LOOPS% (
        echo 等待3秒后继续...
        timeout /t 3 /nobreak >nul
        echo.
    )
)

echo 有限循环执行完成！
echo.