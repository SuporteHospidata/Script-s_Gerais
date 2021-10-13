select * from sigh.ctas_receber_pagar  limit 1; -- procurar a coluna do nome do devedor 

select * from sigh.ctas_receber_pagar  where nm_devedor ilike '%XXXXXXXXXXX%' -- coluna "nm_devedor" já incluído

begin;
DELETE FROM sigh.ctas_receber_pagar WHERE id_cta_receber_pagar = 'XXXXXXXX' --setar o id_cta_conta_receber_pagar
END;


--localizando o título, deve coletar os dados do "id_cta_receber_pagar" e após fazer o delete.