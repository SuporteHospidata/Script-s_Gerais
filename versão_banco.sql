--verificar a versão do banco de dados

select versao, releases from conf.parametros_conf;

--normalmente usando quando vai abrir aplicação e aparece a mensagem "Sistemas incompativel com a versão do banco de dados"

--Alterar a versão no banco

update conf.parametros_conf
set releases = XX --setar a versão, ultimo 2 numeros
where id_parametros_conf = 5;
