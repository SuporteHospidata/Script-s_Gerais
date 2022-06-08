-- função que verifica leitos ocupados sem paciente e faz a liberação

CREATE or replace function sigh.libera_leitos_ocupados_sem_pacientes()
returns integer
LANGUAGE plpgsql
as $f$


declare
total integer DEFAULT 0;
id integer;
leito record;
cur_leito cursor for
SELECT * from sigh.leitos WHERE cod_sit_leito=2;
BEGIN
/* CAP 23/03/2022
* Procura por leitos ocupados e que não tem paciente, libera leito (cot_sit_leito=2)
* Retorna o número de leitos ocupados que foram liberados
* */
open cur_leito ;
loop
fetch cur_leito into leito;
exit when not found;


select id_fia into id from sigh.ficha_amb_int where data_alta is null and cod_leito=leito.id_leito limit 1;
if (id is null)
THEN
update sigh.leitos a
set cod_sit_leito = 1
where a.id_leito = leito.id_leito;


total := total + 1;
RAISE NOTICE 'ACHOU id_leito : % id_fia: %', leito.id_leito, id ;
end if;


--RAISE NOTICE 'id_leito : % id_fia: %', leito.id_leito, id ;
END LOOP;


close cur_leito ;
RETURN total;
exception
when others then
close cur_leito ;
--- GET STACKED DIAGNOSTICS err_context = PG_EXCEPTION_CONTEXT;
RAISE INFO 'Error Name:%',SQLERRM;
RAISE INFO 'Error State:%', SQLSTATE;
return -1;


end; $f$;
