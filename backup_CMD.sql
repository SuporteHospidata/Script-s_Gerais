
--Realizar o backup sempre, user primeiro e após o backup
@para Usuários:
*pg_dumpall -h XXX.XXX.X.XXX -p XXXX -U postgres -W -v -g > C:\BACKUP\Usuarios.sql ---Backup USER
@Para Base:
*pg_dump -h XXX.XXX.X.XXX -p XXXX  -U postgres -W -v -C bd0287 > C:\BACKUP\bd0287.sql -- Backup do sistema


