-- visualizar produto e estoque no banco
 
select * from sigh.produtos where nm_produto ilike '%DEXAMETASONA 4mg/ml 2,5ml%' -- seleciona id do produto
select * from sigh.estoques -- seleciona o estoque
select * from sigh.estoques_produtos where cod_produto = 1301 and cod_estoque = 81 -- filtra produto por estoque


-- update para mudar estoque 
begin;
update sigh.estoques_produtos set qtd_unid_consumo = 36.500000000000000 where cod_produto = 1301 and cod_estoque = 81 -- atualiza o estoque do produto
end;
commit;

