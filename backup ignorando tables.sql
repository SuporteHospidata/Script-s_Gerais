
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 29877, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30365, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30000, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30021, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30028, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30029, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30194, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30212, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30235, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30264, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30279, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30287, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30289, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30303, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30316, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30342, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30363, 5.74);
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( 30365, 5.74);

Clientes que possuem integração com Gerint:

--Backup ignorando algumas tabelas 

pg_dumpall -h XXX.XXX.X.XXX -p XXXX -U postgres -W -v -g > C:\BACKUP\Usuarios.sql ---Backup USER
pg_dump -h [ip] -p [porta] -U [usuario] --exclude-table-data=[tabela1] --exclude-table-data=[tabela2] -v -C [nome da base] > [local do backup]\bdXXXX.sql