--Exclusão de FIAS - Caso não haja relacionamento entre tabelas:

 select * from sigh.pacientes where nm_paciente ilike 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' --Localizar a fia 


select data_alta, hora_fim, * from sigh.ficha_amb_int where cod_paciente = 'XXX' and numero_atendimento = 'NN'  -- coletar ID_FIA


begin;
delete sigh.ficha_amb_int  where id_fia = 'XXXXXX' --Exclusão da fia
end;


--------------------------------------------------------------------------------------------------------------------------------------
-- Alter date e time da fia 

 select * from sigh.pacientes where nm_paciente ilike 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' --Localizar a fia 


select data_alta, hora_fim, * from sigh.ficha_amb_int where cod_paciente = 'XXX' and numero_atendimento = 'NN'  -- coletar

begin;
update sigh.ficha_amb_int set data_atendimento = 'AAAA-MM-DD'  where id_fia = 'XXXXXX' -- Alterar a data 
END;

begin;
update sigh.ficha_amb_int set hora_inicio = 'Hora:Min:SEG'  where id_fia = 'XXXX' -- Alterar o horário da FIA
END;


