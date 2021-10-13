---liberar módulo--------
update
conf.tags
set
configuravel = true --Ficar configurável no conf
where
cod_objeto in (
select
t.cod_objeto
from
conf.tags t
, conf.objetos o
where
o.id_objeto = t.cod_objeto
and o.visualizar
and descricao ilike '%DIAGNOSE/TERAPIA%' -- Exemplo de um módulo
);






--Caso você queira liberar outro modulo basta alterar o caminho após o LIke '%[Caminho]%'