-- Base demorando para abrir, realizando fechamento de FIAS -- Rodar somente em teste

update sigh.unidades set unidade_utiliza_fechamento_automatico = 'f';

update sigh.situacoes_atendimentos set situacao_fechamento = 'f';

-----------------------------------------------------------------------------------------------------------------------

--Fechar todas as fias Abertas com mais de 3 dias
update sigh.ficha_amb_int
set
data_alta = (data_atendimento + 3),--sistema puxa dt atendimento e fecha +1=24h +2=48h
hora_fim = hora_inicio,
cod_mot_alta = (
select
id_mot_alta
from
sigh.motivos_altas
where
descr_mot_alta = 'ALTA MELHORADO' and ativo limit 1 --defini motivo de alta como  "alta melhorado"
),
cod_situacao_atendimento = (
select  
id_situacao_atendimento
from
sigh.situacoes_atendimentos
where
tipo_situacao_atendimento = 'F' order by 1 limit 1 -- defini situação como fechado
)
where
data_atendimento <= (cast(now() as date) - 7) --defini a qtd de dias que quer manter as fias abertas
and
data_alta is null
and
(tipo_atend = 'AMB' or tipo_atend = 'EXT'); -- Tipos de atendimento

commit;