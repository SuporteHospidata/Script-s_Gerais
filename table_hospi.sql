select * from sigh.hospitais limit 1;  -- Coletar o Id_hospital e setar no update

begin;
update sigh.hospitais
set 
nome = 'nome da instituicao',
cgc_cnpj = 'CNPJ DA INSTITUICAO',
codigo_hosp = 'CODIGO DO CLIENTE'
where id_hospital = 'ID DA TABELA ';
commit;

--Normalemnte usado na liberacao de aplicacao, exemplo (AIH, IPE e afins)

--Lembrando que deve ser setado ID da tabela para que a mesma possa identificar onde sera realizado os ajustes.

-- Caso seja multi-empresa, tirar 'limit 1' do select--