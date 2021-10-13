do
$$
declare r record;
begin
    for r in
        with t as(
        select
            max(tsl.id_troca_sit_leito) as id_troca_sit_leito,
            tsl.cod_fia
        from
            sigh.troca_situacao_leito tsl
        where
            tsl.cod_fia in (
            select
                id_fia
            from
                sigh.ficha_amb_int
            where
                cod_leito is null
                and tipo_atend = 'INT'
                and data_alta is not null)
        group by
            tsl.cod_fia)
        select
            *
        from
            sigh.troca_situacao_leito tsl
        inner join t on
            t.id_troca_sit_leito = tsl.id_troca_sit_leito
    loop
        update sigh.ficha_amb_int
            set cod_leito = r.cod_leito
        where
            id_fia = r.cod_fia
        and
            cod_leito is null
        and
            tipo_atend = 'INT'; -- Atendimento 
    end loop;
end
$$;

-- Fias fechadas sem leitos // Bug que ocorria no sistema 