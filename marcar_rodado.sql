--marcar como rodado no pgadmim após rodar o script pego no gerente: 
insert into util.controles_scripts (codigo_script , versao_cliente_atualizacao) values ( XXXX, 5.74);


-- Validar se o script realmente está como rodado na tabela:

select * from Util.controles_scripts where codigo_script = (XXXX);