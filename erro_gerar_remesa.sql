--Corrigir erro ao gerar a remesa

update sigh.lancamentos
set preco_venda_unit = 0.0
where preco_venda_unit is null
and data_hora_criacao between '2021-10-01' and '2021-10-20'


ERRO:

--|' is not a valid floating point value