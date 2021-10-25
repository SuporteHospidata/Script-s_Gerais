---Mudar status de NFS-e

--mudar sttaus no título de NFS-e 
begin

update sigh.ctas_receber_pagar 
   set status_rps_nfse = 'C' -- Setar o status 
 where id_cta_receber_pagar = 65 

end
rollback

--consultar o status da NFSE no titulo

select status_rps_nfse, * from sigh.ctas_receber_pagar_itens where cod_cta_receber_pagar = XXX



--Case com as opções de status --só usar as opções C, A e E.

CASE
            
            ELSE cast(CASE
                          WHEN status_rps_nfse IS NULL THEN 'Não enviada'
                          WHEN status_rps_nfse = 'C' THEN 'NFSe Cancelada'
                          WHEN status_rps_nfse = 'A' THEN 'Não enviada'
                          WHEN status_rps_nfse = 'E' THEN 'NFSe Gerada'
                      END AS varchar(25))
        END AS status_nfse
