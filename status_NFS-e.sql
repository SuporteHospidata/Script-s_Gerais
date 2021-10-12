---Mudar status de NFS-e

--mudar sttaus no título de NFS-e 
begin

update sigh.ctas_receber_pagar 
   set status_rps_nfse = 'C' -- Setar a letra 
 where id_cta_receber_pagar = 65 

end
rollback

--consultar o status da NFSE no titulo

select status_rps_nfse, * from sigh.ctas_receber_pagar_itens where cod_cta_receber_pagar = 65 



--Case com as opções de status

CASE
            WHEN coalesce(
                            (SELECT TRUE
                             FROM sigh.ctas_receber_pagar_itens
                             WHERE cod_cta_receber_pagar = 65
                               AND coalesce(codigo_rps_nfse, '') <> ''
                             LIMIT 1), FALSE) = TRUE THEN 'Cons. Parcelas'
            ELSE cast(CASE
                          WHEN status_rps_nfse IS NULL THEN 'Não enviada'
                          WHEN status_rps_nfse = 'C' THEN 'NFSe Cancelada'
                          WHEN status_rps_nfse = 'A' THEN 'Não enviada'
                          WHEN status_rps_nfse = 'E' THEN 'NFSe Gerada'
                      END AS varchar(25))
        END AS status_nfse