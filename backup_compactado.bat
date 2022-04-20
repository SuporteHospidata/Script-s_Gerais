

set PGPASSWORD=s@tt30hd2013
set HOST=XXX.XXX.X.XXX --IP
set PORT=XXXX --PORTA
set CLIENT=bdXXXX --BASE
set DIR_OUT=XXXXXX --DIR onde backp sera armazenados
rem ------------------------------------------------------------------------------------------------------------------------------------------


rem -----------backup direto pg_dump --------
rem -- 

cd C:\sistemashd
pg_dumpall.exe -h %HOST% -p %PORT% -U hd_suporte -v -g > %DIR_OUT%\Usuarios.sql

pg_dump.exe -h %HOST% -p %PORT% -U hd_suporte -v -C %CLIENT% > %DIR_OUT%\Backup%CLIENT%%date:~6,4%%date:~3,2%%date:~0,2%.sql

7z.exe a %DIR_OUT%\Backup%CLIENT%%date:~6,4%%date:~3,2%%date:~0,2%.zip %DIR_OUT%\*.sql
del "%DIR_OUT%\*.sql"
pause
