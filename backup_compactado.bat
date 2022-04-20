set PGPASSWORD=fat0516fat
set HOST=XXX.XXX.XXX.XXX -- IP
set PORT=XXXX -- porta
set CLIENT=bdxxxx -- base
set DIR_OUT=xxxx -- local para salvar backup
rem ------------------------------------------------------------------------------------------------------------------------------------------


cd \Program Files\PostgreSQL\9.2\bin -- pra utilizar o pg_dump diretamente da pasta do postgres (caso estação possua o postgres instalado)
pg_dumpall.exe -h %HOST% -p %PORT% -U hd_faturamento -v -g > %DIR_OUT%\Usuarios.sql

pg_dump.exe -h %HOST% -p %PORT% -U hd_faturamento -v -C %CLIENT% > %DIR_OUT%\Backup%CLIENT%%date:~6,4%%date:~3,2%%date:~0,2%.sql

cd xxxxxx -- local onde está o 7zip para compactação 

7z.exe a %DIR_OUT%\Backup%CLIENT%%date:~6,4%%date:~3,2%%date:~0,2%.zip %DIR_OUT%\*.sql

del "%DIR_OUT%\*.sql"
pause
