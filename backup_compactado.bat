--Backup e compactação do mesmo é necessário ter os executaveis 7z e 7zFM que estão localizados nesta pasta : \\HDSERVER13\público\willian\backup bat

set PGPASSWORD=s@tt30hd2013
set HOST=192.168.0.100
set PORT=5432
set CLIENT=bd0282
set DIR_OUT=Y:\backups
rem ------------------------------------------------------------------------------------------------------------------------------------------

rem ------Backup com Util---------------------
rem C:\SistemasHD\util.exe -B C:\bkp

rem -----------backup direto pg_dump --------
rem -- 

pg_dumpall.exe -h %HOST% -p %PORT% -U hd_suporte -v -g > %DIR_OUT%\Usuarios.sql
pause
pg_dump.exe -h %HOST% -p %PORT% -U hd_suporte -v -C %CLIENT% > %DIR_OUT%\Backup%CLIENT%%date:~6,4%%date:~3,2%%date:~0,2%.sql
pause
7z.exe a %DIR_OUT%\Backup%CLIENT%%date:~6,4%%date:~3,2%%date:~0,2%.zip %DIR_OUT%\*.sql
pause
del "%DIR_OUT%\*.sql"
pause
