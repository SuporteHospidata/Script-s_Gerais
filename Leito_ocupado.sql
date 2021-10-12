-- sistema com o leito ocupado, porém sem paciente.


begin;

update sigh.leitos

set cod_sit_leito = 1

where nm_leito ilike 'B' -- Setar o Leito
and cod_quarto_enf in

(select id_quarto_enf from sigh.quartos_enfermarias

where nm_quarto ilike '12') -- Setar o Quarto

and cod_sit_leito = 2; --2 = passar para livre 1 =passar para ocpuado 

end;