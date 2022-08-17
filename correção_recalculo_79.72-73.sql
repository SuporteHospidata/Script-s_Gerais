-- script para corrigir sql error 'column "v_valor_manual" does not exist at character 14' ao dar alta ou na conta do paciente


CREATE OR REPLACE FUNCTION sigh.f_recalcula_lancamento(v_cod_lanc integer, v_atualiza boolean, v_gera_coparticipacao_via_conta boolean)
 RETURNS util.dom_float
AS $BODY$
declare
	linha sigh.lancamentos;
	v_ignora_tudo boolean;
	v_excecao_preco util.dom_float;
	v_valor_final util.dom_float;
	v_valor_custo util.dom_float;
	v_tp_prod_conta varchar;
	v_tipo_proc varchar;
	v_cod_categoria integer;
	v_tipo_atend varchar;
	v_id_proc_preco integer;
	v_linha_proc_preco record;
	v_aplica_reducao boolean;
	v_data_ult_realizado date;
	v_mesmo_dia boolean;
	v_aplica_red_dias_dif boolean;
	v_total_aux util.dom_float;
	v_kit_aberto varchar;
	v_imposto_tabela varchar;
	v_preco_imposto util.dom_float;
	v_filme varchar;
	v_valor_ch util.dom_float;
	i integer;
	v_qtd_filme util.dom_float;
	v_vlr_filme util.dom_float;
	v_vlr_copart util.dom_float;
	v_percentual_lg_aplica_copart boolean;
	v_result_array_copart numeric[];
	v_id_lancamento_exame integer;
	v_percentual_lanc_var util.dom_float;
	v_preco_filme util.dom_float;
	v_percentual util.dom_float;
	v_valor_limite_fisico util.dom_float;
	v_convenio_ipe boolean;
	v_valor_gerando_coparticipacao util.dom_float;
	v_cod_fia integer;
	v_cod_convenio integer;
	v_cod_especialidade integer;
	v_cod_unidade_fia integer;
	v_urgente_eletivo character varying;
	v_preco_venda_unit_original util.dom_float;
	v_sTipoProd varchar;
	v_iTipoProd integer;
	v_bTipoProd boolean;
	v_bConsideraPercRegra boolean;
	v_preco_venda_sem_percentual util.dom_float;
	--Calculo de Porte
	v_cbhpm boolean;
	v_valor_porte_cirur util.dom_float;
	v_valor_porte_anest util.dom_float;
	v_valor_porte_cirur_total util.dom_float;
	v_valor_porte_anest_total util.dom_float;
	v_cod_porte_cirurgico integer;
	v_cod_porte_anestesico integer;
	v_valor_mult_cirur util.dom_float;
	v_valor_mult_anest util.dom_float;
	v_sTipoPorte varchar;
	v_codigo_tabela integer;
	v_valor_custo_oper util.dom_float;
	v_valor_uco util.dom_float;
	v_tipo_leito integer;
	--Validacoes de exames
	v_iMaiorExame integer;
	v_percentual_unico util.dom_float;
	v_iQtdeReducao integer;
	v_percentual_faixa util.dom_float;
	v_bRedutor_unico boolean;
	v_bRedutor_faixa boolean;
	v_iNumeroLinha integer;
	v_iCod_grupo_reduc integer;
	v_percentual_prox_faixa integer;
	v_iMaiorExameID integer;
	v_iMaiorFaixa integer;
	v_iMaiorQtdFinal integer;
	v_cod_medico_fia integer;
	v_icontador_exames integer;
	v_lanca_filme_param_categoria boolean;
	v_preco_excecao_original util.dom_float;
	v_valor_excecoes_regra util.dom_float;
	v_id_regra_cobranca util.dom_float;
	v_regra_cobranca_multiplica boolean;
	v_regra_cobranca_considera_perc boolean;
	v_percentual_f_acrescimo_horario_especial util.dom_float;
	v_percentual_debug util.dom_float;
	v_tipo_conta varchar(1);
	v_cod_servico_diferenca integer;
	v_tp_servico varchar(1);
	v_valor_unit_debug util.dom_float;
begin

	select into
		linha
		*
	from
		sigh.lancamentos
	where
		id_lancamento = v_cod_lanc;

	select into
		v_cod_categoria
		, v_tipo_conta
		c.cod_categoria
		, c.tipo_conta
	from
		sigh.contas c
	where
		c.id_conta = linha.cod_conta;

	v_convenio_ipe = coalesce(
		(
			select
				cod_convenio
			from
				sigh.categorias
			where
				id_categoria = v_cod_categoria
		) = (select cod_conv_ipe from sigh.params_faturamento where ativo limit 1)
	,false);

	select into
		v_tipo_atend,
		v_cod_fia,
		v_cod_convenio,
		v_cod_especialidade,
		v_cod_unidade_fia,
		v_urgente_eletivo,
		v_cod_medico_fia
		fia.tipo_atend,
		fia.id_fia,
		fia.cod_convenio,
		fia.cod_especialidade,
		fia.cod_unidade,
		fia.urgente_eletivo,
		fia.cod_medico
	from
		sigh.ficha_amb_int fia
	where
		fia.id_fia in (select c.cod_fia from sigh.contas c where c.id_conta = linha.cod_conta);

	--Verifica o tipo de produto
	select into
		v_iTipoProd
		, v_bTipoProd
		p.tipo_produto
		, p.prod_ortese_protese
	from
		sigh.produtos p
	where
		p.id_produto = linha.cod_prod;
	--Popula a variavel
	v_sTipoProd = '';
	if((v_iTipoProd = 1) and (v_bTipoProd = False))then
		v_sTipoProd = 'MED';
	end if;
	if((v_iTipoProd in (2, 3, 4)) and (v_bTipoProd = False))then
		v_sTipoProd = 'MAT';
	end if;
	if(v_bTipoProd = True)then
		v_sTipoProd = 'OPM';
	end if;

	/*Verifica os valores referente ao porte, caso exista*/
	/*Busca o nome da tabela utilizada*/
	if v_tipo_atend = 'INT' then
		select into
			v_codigo_tabela,
			v_cbhpm,
			v_valor_uco
			pp.cod_nome_tabela,
			nt.cbhpm,
			coalesce(cbg.valor_uco_int,vlr_custo_operacional) vlr_custo_operacional
		from
			sigh.categorias cat
			left	join(
							select	cb.id_categoria,
									p.id_procedimento,
									cb.id_nome_tabela,
									cb.valor_uco_amb,
									cb.valor_uco_int
							from    sigh.procedimentos_precos pp
							inner   join sigh.correl_proc_proc_precos cppp
							on      cppp.cod_proc_precos = pp.id_proc_precos
							inner   join sigh.procedimentos p
							on      p.id_procedimento = cppp.cod_procedimento
							left	join sigh.item_grupo_cbhpm itcb
							on		itcb.id_proc_precos = pp.id_proc_precos
							left	join sigh.grupo_cbhpm cb
							on		cb.id_grupo_cbhpm = itcb.id_grupo_cbhpm) cbg
			on		cbg.id_categoria	= cat.id_categoria
			and		cbg.id_procedimento = linha.cod_proc
			and		cat.habilitar_grupo_cbhpm
			left join sigh.nomes_tabelas nt on (nt.id_nome_tabela = coalesce(cbg.id_nome_tabela,cat.cod_tab_sadt_int))
			left join sigh.procedimentos_precos pp on (pp.cod_nome_tabela = nt.id_nome_tabela)
			left join sigh.correl_proc_proc_precos cppp on (cppp.cod_proc_precos = pp.id_proc_precos)
		where
			cat.id_categoria = v_cod_categoria
			and cppp.cod_procedimento = linha.cod_proc;
	else
		select into
			v_codigo_tabela,
			v_cbhpm,
			v_valor_uco
			pp.cod_nome_tabela,
			nt.cbhpm,
			coalesce(cbg.valor_uco_amb,vlr_custo_operacional) vlr_custo_operacional
		from
			sigh.categorias cat
			left	join(
							select	cb.id_categoria,
									p.id_procedimento,
									cb.id_nome_tabela,
									cb.valor_uco_amb,
									cb.valor_uco_int
							from    sigh.procedimentos_precos pp
							inner   join sigh.correl_proc_proc_precos cppp
							on      cppp.cod_proc_precos = pp.id_proc_precos
							inner   join sigh.procedimentos p
							on      p.id_procedimento = cppp.cod_procedimento
							left	join sigh.item_grupo_cbhpm itcb
							on		itcb.id_proc_precos = pp.id_proc_precos
							left	join sigh.grupo_cbhpm cb
							on		cb.id_grupo_cbhpm = itcb.id_grupo_cbhpm) cbg
			on		cbg.id_categoria	= cat.id_categoria
			and		cbg.id_procedimento = linha.cod_proc
			and		cat.habilitar_grupo_cbhpm
			left join sigh.nomes_tabelas nt on (nt.id_nome_tabela = coalesce(cbg.id_nome_tabela,cat.cod_tab_sadt_amb))
			left join sigh.procedimentos_precos pp on (pp.cod_nome_tabela = nt.id_nome_tabela)
			left join sigh.correl_proc_proc_precos cppp on (cppp.cod_proc_precos = pp.id_proc_precos)
		where
			cat.id_categoria = v_cod_categoria
			and cppp.cod_procedimento = linha.cod_proc;
	end if;
	/*Busca o porte*/
	select into
		v_cod_porte_cirurgico,
		v_valor_porte_cirur,
		v_valor_mult_cirur,
		v_cod_porte_anestesico,
		v_valor_porte_anest,
		v_valor_mult_anest,
		v_valor_custo_oper
		pp.cod_porte,
		pg.valor_porte as valor_cirurgico,
		coalesce(cbg.porte,pp.percentual_porte_geral) as multiplicador_cirurgico,
		pp.cod_porte_anestesico,
		pa.valor_porte as valor_anestesico,
		coalesce(cbg.porte,pp.percentual_porte_anestesico) as multiplicador_anestesico,
		pp.custo_operacional
	from
		sigh.correl_proc_proc_precos cppp
		left join sigh.procedimentos p on (p.id_procedimento = cppp.cod_procedimento)
		left join sigh.procedimentos_precos pp on (pp.id_proc_precos = cppp.cod_proc_precos)
		left join sigh.portes pg on (pg.id_porte = pp.cod_porte)
		left join sigh.portes pa on (pa.id_porte = pp.cod_porte_anestesico)
		left	join(
							select	p.id_procedimento,
									cb.id_nome_tabela,
									cb.id_categoria,
									cb.porte
							from    sigh.procedimentos_precos pp
							inner   join sigh.correl_proc_proc_precos cppp
							on      cppp.cod_proc_precos = pp.id_proc_precos
							inner   join sigh.procedimentos p
							on      p.id_procedimento = cppp.cod_procedimento
							left	join sigh.item_grupo_cbhpm itcb
							on		itcb.id_proc_precos = pp.id_proc_precos
							left	join sigh.grupo_cbhpm cb
							on		cb.id_grupo_cbhpm = itcb.id_grupo_cbhpm
							inner	join sigh.categorias cat
							on		cat.id_categoria = cb.id_categoria
							and		cat.habilitar_grupo_cbhpm) cbg
			on		cbg.id_procedimento = linha.cod_proc
			and		cbg.id_categoria = v_cod_categoria
	where
		p.id_procedimento = linha.cod_proc and
		pp.cod_nome_tabela = coalesce(cbg.id_nome_tabela,v_codigo_tabela) and
		pp.ativo = true;

	v_sTipoPorte = 'DES';
	v_valor_porte_cirur_total = 0;
	v_valor_porte_anest_total = 0;
	if(coalesce(v_cbhpm, false) = True)then
		if((coalesce(v_cod_porte_cirurgico, 0) > 0 and coalesce(v_valor_mult_cirur, 0) > 0) and linha.tipo_hon <> 6)then
			v_sTipoPorte = 'PCI';
			v_valor_porte_cirur_total = (v_valor_porte_cirur * v_valor_mult_cirur);
			--v_valor_porte_cirur_total = (v_valor_porte_cirur * v_valor_mult_cirur) + (v_valor_custo_oper * v_valor_uco);
		end if;
		if((coalesce(v_cod_porte_anestesico, 0) > 0 and coalesce(v_valor_mult_anest, 0) > 0) and linha.tipo_hon = 6)then
			v_sTipoPorte = 'PAN';
			v_valor_porte_anest_total = v_valor_porte_anest * v_valor_mult_anest;
		end if;
	end if;
	--Fim do calculo do porte

	--Nova validacao para Regra de Cobranca Tipo de Leito
	select into
		v_tipo_leito
		coalesce(tl.id_tp_leito, 0)
	from
		sigh.ficha_amb_int f
		left outer join sigh.troca_situacao_leito tsl on (tsl.cod_fia = f.id_fia)
		left outer join sigh.leitos l                 on (l.id_leito = tsl.cod_leito)
		left outer join sigh.quartos_enfermarias q    on (q.id_quarto_enf = l.cod_quarto_enf)
		left outer join sigh.pacientes p              on (p.id_paciente = f.cod_paciente)
		left outer join sigh.tipos_leitos tl          on (tl.id_tp_leito = q.cod_tp_leito)
	where
		f.id_fia = v_cod_fia
		and cast(tsl.data_inicio ||' '|| tsl.hora_inicio as timestamp) <= cast(linha.data ||' '|| linha.hora as timestamp)
		and cast(coalesce(tsl.data_fim, (select current_date)) ||' '|| coalesce(tsl.hora_fim, (select current_time)) as timestamp) >= cast(linha.data ||' '|| coalesce(linha.hora_fim, linha.hora) as timestamp)
	order by
		tsl.id_troca_sit_leito desc
	limit
		1;
	--Se nao possuir troca de leito, buscar da fia apenas
	if(coalesce(v_tipo_leito, 0) = 0)then
		select into
			v_tipo_leito
			coalesce(tl.id_tp_leito, 0)
		from
			sigh.ficha_amb_int f
			left outer join sigh.leitos l                 on (l.id_leito = f.cod_leito)
			left outer join sigh.quartos_enfermarias q    on (q.id_quarto_enf = l.cod_quarto_enf)
			left outer join sigh.tipos_leitos tl          on (tl.id_tp_leito = q.cod_tp_leito)
		where
			f.id_fia = v_cod_fia
		limit 1;
	end if;

	/*testa se o lancamento tem o flag "ignora tudo"*/
	select into v_ignora_tudo
		cast('IGNORA_TUDO' = any (linha.params) as boolean);

	/*se tiver o flag ignora tudo, cod_copia ou cod_copart cai fora*/
	if (v_ignora_tudo) or ((linha.cod_copia is not null) and (v_ignora_tudo)) or (linha.cod_copart is not null) then
		return linha.preco_venda_unit;
	end if;

	/* Excecao preco funcionar para Exames e Procedimentos*/
	v_excecao_preco = sigh.f_verifica_excecao_preco(linha,false);

    /*Preco original*/
	if linha.tipo_lanc = 1 then
		v_preco_venda_unit_original = sigh.f_retorna_preco_produto(linha.cod_prod, v_cod_categoria, v_tipo_atend, linha.data);
        end if;
	if linha.tipo_lanc = 2 then
		--v_preco_venda_unit_original = sigh.f_retorna_preco_servico(linha.cod_serv, v_cod_categoria, v_tipo_atend, linha.data, linha.hora, false, false);
		/* Inicio - (SIGH-20078) - (5123 - CH por ato não aplica para serviços) - (barbara.pereira) */
		v_preco_venda_unit_original = sigh.f_retorna_preco_servico(linha.cod_serv, v_cod_categoria, linha.cod_tp_ato, v_tipo_atend, linha.data, linha.hora, false, true);
		/* Fim - (SIGH-20078) - (5123 - CH por ato não aplica para serviços) - (barbara.pereira) */
	end if;
	if linha.tipo_lanc = 3 then
		--v_preco_venda_unit_original = sigh.f_retorna_preco_proc(linha.cod_proc, v_cod_categoria, v_tipo_atend, linha.data, linha.hora);
		v_preco_venda_unit_original = sigh.f_retorna_preco_proc(linha.cod_proc, v_cod_categoria, v_tipo_atend, linha.tipo_hon, linha.num_equipe,
							linha.bilateral, linha.mesma_via, null, linha.data, linha.hora, false, linha.diferentes_vias,
							linha.unica_via, v_urgente_eletivo, v_cod_fia, linha.cod_tp_ato, cast(linha.params as character varying[]), v_excecao_preco, false, true);

    end if;

	/*Nova validacao referente a quantidade de exames na conta*/
	if (linha.tipo_lanc = 3) then
		select into
			v_tipo_proc
			p.exame_proc
		from
			sigh.procedimentos p
		where
			p.id_procedimento = linha.cod_proc;

		if(v_tipo_proc = 'EXAME') then
			--Regra para reducao de exames
			select into
				v_icontador_exames
				count(*) as contador
			from
				sigh.grupos_reducao gr
				left outer join sigh.exames_filtrados e on e.cod_grupo = gr.id_grupos_reducao
			where
				gr.cod_convenio = v_cod_convenio
				and e.ativo = true
				and e.codigo_exame in (select proc.codigo_procedimento
										from sigh.procedimentos proc
										left join sigh.lancamentos l on l.cod_proc = proc.id_procedimento
										where l.cod_proc = linha.cod_proc);

			if (coalesce(v_icontador_exames, 0) > 0)then
				select distinct into
					v_bRedutor_unico
					, v_bRedutor_faixa
					, v_percentual_unico
					, v_iCod_grupo_reduc
					 coalesce(gr.redutor_unico, false)
					, coalesce(gr.redutor_faixa, false)
					, coalesce(gr.percentual_unico, 100)
					, gr.codigo_grupo
				from
					sigh.grupos_reducao gr
					left outer join sigh.exames_filtrados e on e.cod_grupo = gr.id_grupos_reducao
				where
					gr.cod_convenio = v_cod_convenio
					and e.ativo = true
					and e.codigo_exame in (select proc.codigo_procedimento
											from sigh.procedimentos proc
											left join sigh.lancamentos l on l.cod_proc = proc.id_procedimento
											where l.cod_conta = linha.cod_conta
											and l.id_lancamento = linha.id_lancamento
											and l.cod_prestador = linha.cod_prestador
										and l.data = linha.data)
				limit 1;

					--Exame com maior valor por determinado grupo ficara com percentual de 100%
					select into
						v_iMaiorExame
						, v_iMaiorExameID
						l.cod_proc
						, l.id_lancamento
						, l.preco_venda_unit as preco_base
					from
						sigh.lancamentos l
						left join sigh.contas c on (c.id_conta = l.cod_conta)
						left join sigh.categorias ca on (ca.id_categoria = c.cod_categoria)
						left join sigh.convenios cv on (cv.id_convenio = ca.cod_convenio)
						left join sigh.procedimentos proc on (proc.id_procedimento = l.cod_proc)
					where
						proc.codigo_procedimento in (select ee.codigo_exame from sigh.exames_filtrados ee where ee.cod_convenio = cv.id_convenio and ee.ativo)
						and cv.id_convenio = v_cod_convenio
						and l.cod_conta = linha.cod_conta
						and l.cod_prestador = linha.cod_prestador
						and l.data = linha.data
						and cast(proc.codigo_procedimento as varchar) like cast(v_iCod_grupo_reduc as varchar)||'%'
					order by
						--preco_base, l.id_lancamento desc
						l.preco_venda_unit desc, l.id_lancamento desc
					limit 1;
				--raise exception 'v_iMaiorExameID %', v_iMaiorExameID;
					--Verifica a linha dos exames para validar a faixa
					select into
						v_iNumeroLinha
						lanc.sequencia
					from
						(
							select
								l.cod_proc
								, proc.codigo_procedimento
								, l.preco_venda_unit
								, l.id_lancamento
								, row_number() over (order by l.id_lancamento desc) -1 as sequencia
								, l.preco_venda_unit as preco_base
							from
								sigh.lancamentos l
								left join sigh.contas c on (c.id_conta = l.cod_conta)
								left join sigh.categorias ca on (ca.id_categoria = c.cod_categoria)
								left join sigh.convenios cv on (cv.id_convenio = ca.cod_convenio)
								left join sigh.procedimentos proc on (proc.id_procedimento = l.cod_proc)
							where
								proc.codigo_procedimento in (select ee.codigo_exame from sigh.exames_filtrados ee where ee.cod_convenio = cv.id_convenio and ee.ativo)
								and cv.id_convenio = v_cod_convenio
								and l.cod_conta = linha.cod_conta
								and l.cod_prestador = linha.cod_prestador
								and l.data = linha.data
								and cast(proc.codigo_procedimento as varchar) like cast(v_iCod_grupo_reduc as varchar)||'%'
							order by
								--preco_base, l.id_lancamento desc
								l.preco_venda_unit desc, l.id_lancamento desc
						) as lanc
					where
						lanc.id_lancamento = linha.id_lancamento;

				if (v_bRedutor_faixa)then
					--POR FAIXA >>> Maior exame fica com 100
					--Validar a tabela de faixas de quantidade
					select distinct into
						v_percentual_faixa
						qt.percentual
					from
						sigh.quantidades_grupo_reducao qt
						left outer join sigh.grupos_reducao gr  on (gr.id_grupos_reducao = qt.cod_grupo_red)
						left outer join sigh.exames_filtrados e on (e.cod_grupo = gr.id_grupos_reducao and e.ativo)
					where
						gr.cod_convenio = v_cod_convenio
						and v_iNumeroLinha > 0
						and e.ativo = true
						and e.codigo_exame in (select proc.codigo_procedimento
												from sigh.procedimentos proc
												left join sigh.lancamentos l on l.cod_proc = proc.id_procedimento
												where l.cod_conta = linha.cod_conta
												and l.id_lancamento = linha.id_lancamento
												and l.cod_prestador = linha.cod_prestador
												and l.data = linha.data)
						and v_iNumeroLinha >= coalesce(qt.quantidade_inicial, qt.quantidade)
						and v_iNumeroLinha <= coalesce(qt.quantidade, 1)
					limit 1;

					--Valida o infinito
					select into
						v_iMaiorFaixa
						, v_iMaiorQtdFinal
						qt.percentual
						, qt.quantidade
					from
						sigh.quantidades_grupo_reducao qt
						left outer join sigh.grupos_reducao gr  on (gr.id_grupos_reducao = qt.cod_grupo_red)
					where
						gr.cod_convenio = v_cod_convenio
					order by id_quantidade_red desc
					limit 1;

					if(v_iNumeroLinha > v_iMaiorQtdFinal)then
						v_percentual_faixa = v_iMaiorFaixa;
					end if;

					if((linha.cod_proc = v_iMaiorExame) and (linha.id_lancamento = v_iMaiorExameID))then
						linha.percentual = 100;
					else
						--raise exception 'v_percentual_faixa %', v_percentual_faixa;
						linha.percentual = v_percentual_faixa;
					end if;
				else
					--POR UNICO >>> Maior exame fica com 100
					if((linha.cod_proc = v_iMaiorExame) and (linha.id_lancamento = v_iMaiorExameID))then
						linha.percentual = 100;
					elsif coalesce(v_percentual_unico, 0) > 0 then
						linha.percentual = v_percentual_unico;
					end if;
				end if;
			else
				linha.percentual = 100;
			end if;
		end if;
	end if;
	/* Fim da validacao de exames */

	/*se for produto*/
	if linha.tipo_lanc = 1 then
		select into
			v_filme
			produto_filme
		from
			sigh.produtos
		where
			id_produto = linha.cod_prod;

		v_valor_custo = sigh.f_retorna_preco_custo_produto(linha.cod_prod);
		v_valor_limite_fisico = sigh.f_verifica_limite_fisico(linha);

		/*se for filme lancado pelo raio-x, atualiza cfe. preco do convenio*/
		if ((v_filme = 'T') and (linha.cod_laudo is not null)) or ((v_filme = 'T') and (linha.preco_venda_unit is not null)) then
			select into v_valor_final
				cat.valor_filme
			from
				sigh.categorias cat
			where
				cat.id_categoria = v_cod_categoria;

			v_valor_final := coalesce(v_valor_final,0);
 		else
			if v_excecao_preco <> 0 then
				v_valor_final = v_excecao_preco;
			elsif v_valor_limite_fisico <> 0 then
				v_valor_final = v_valor_limite_fisico;
			else
				/*seleciona o preco do prod similar ou principal conforme configuracao do convenio*/
				select into
					v_tp_prod_conta
					conv.tipo_prod_conta
				from
					sigh.convenios conv
				where
					conv.id_convenio = (select cat.cod_convenio from sigh.categorias cat where cat.id_categoria = v_cod_categoria);

				/* select para ver se o id do lancamento esta como vinculado a um procedimento/exame  */
				if (v_filme = 'T') then
					select into
						v_id_lancamento_exame
						id_lancamento
					from
						sigh.lancamentos
					where
						cod_lancamentos_filmes_utilizados is not null
						and linha.id_lancamento = any (cod_lancamentos_filmes_utilizados);
					/*verifica se nao esta vinculado a um filme caso venha nulo nao esta vinculado a um exame*/
				else
					v_id_lancamento_exame = null;
				end if;

				if v_id_lancamento_exame is null then
					if coalesce(v_tp_prod_conta,'') = 'P' then
						v_valor_final = sigh.f_retorna_preco_produto(linha.cod_prod,v_cod_categoria,v_tipo_atend,linha.data);
					else
						if linha.cod_prod_sim is not null then
							v_valor_final = sigh.f_retorna_preco_prod_similar(linha.cod_prod_sim,v_cod_categoria,v_tipo_atend/*,linha.data*/);
						else
							v_valor_final = sigh.f_retorna_preco_produto(linha.cod_prod,v_cod_categoria,v_tipo_atend, linha.data);
						end if;
					end if;
					v_valor_gerando_coparticipacao = v_valor_final;
				else
					/*valor_final caso esteja vinculado a um filme*/
					v_percentual_lanc_var = coalesce(linha.percentual,100);
					if v_tp_atend = 'INT' then
						select into
							v_percentual
							cat.perc_tab_sadt_int
						from
							sigh.categorias cat
							left	join(
							select	cb.id_categoria,
									p.id_procedimento,
									cb.id_nome_tabela,
									cb.valor_uco_amb,
									cb.valor_uco_int,
									cb.porte
							from    sigh.procedimentos_precos pp
							inner   join sigh.correl_proc_proc_precos cppp
							on      cppp.cod_proc_precos = pp.id_proc_precos
							inner   join sigh.procedimentos p
							on      p.id_procedimento = cppp.cod_procedimento
							left	join sigh.item_grupo_cbhpm itcb
							on		itcb.id_proc_precos = pp.id_proc_precos
							left	join sigh.grupo_cbhpm cb
							on		cb.id_grupo_cbhpm = itcb.id_grupo_cbhpm) cbg
				on		cbg.id_categoria	= cat.id_categoria
				and		cbg.id_procedimento = linha.cod_proc
				and		cat.habilitar_grupo_cbhpm
							left join sigh.nomes_tabelas nt on nt.id_nome_tabela = coalesce(cbg.id_nome_tabela,cat.cod_tab_sadt_int)
							left join sigh.procedimentos_precos pp on pp.cod_nome_tabela = nt.id_nome_tabela
							left join sigh.correl_proc_proc_precos cppp on cppp.cod_proc_precos = pp.id_proc_precos
						where
							cat.id_categoria = v_cod_categoria
							and cppp.cod_procedimento = linha.cod_proc;
					else
						select into
							v_percentual
							cat.perc_tab_sadt_int
						from
							sigh.categorias cat
							left	join(
							select	cb.id_categoria,
									p.id_procedimento,
									cb.id_nome_tabela,
									cb.valor_uco_amb,
									cb.valor_uco_int,
									cb.porte
							from    sigh.procedimentos_precos pp
							inner   join sigh.correl_proc_proc_precos cppp
							on      cppp.cod_proc_precos = pp.id_proc_precos
							inner   join sigh.procedimentos p
							on      p.id_procedimento = cppp.cod_procedimento
							left	join sigh.item_grupo_cbhpm itcb
							on		itcb.id_proc_precos = pp.id_proc_precos
							left	join sigh.grupo_cbhpm cb
							on		cb.id_grupo_cbhpm = itcb.id_grupo_cbhpm) cbg
				on		cbg.id_categoria	= cat.id_categoria
				and		cbg.id_procedimento = linha.cod_proc
				and		cat.habilitar_grupo_cbhpm
							left join sigh.nomes_tabelas nt on nt.id_nome_tabela = coalesce(cbg.id_nome_tabela,cat.cod_tab_sadt_amb)
							left join sigh.procedimentos_precos pp on pp.cod_nome_tabela = nt.id_nome_tabela
							left join sigh.correl_proc_proc_precos cppp on cppp.cod_proc_precos = pp.id_proc_precos
						where
							cat.id_categoria = v_cod_categoria
							and cppp.cod_procedimento = linha.cod_proc;
					end if;

					/*pegando o valor do m2 o filme no cadastro de categoria*/
					select into
						v_preco_filme
						valor_filme
					from
						sigh.categorias cat
					where
						cat.id_categoria = v_cod_categoria;

					/*multiplica o preco do filme pelo percentual da tabela de exames em categorias*/
					v_preco_filme = (v_preco_filme * (v_percentual/100));
					/*multiplica o valor do filme pelo percentual enviado*/
					v_preco_filme = v_preco_filme * (v_percentual_lanc_var / 100);
					/* passando valor do filme para variavel v_valor_final seguindo logica da function */
					v_valor_final = v_preco_filme;
				end if;
			end if;
		end if;
	elsif linha.tipo_lanc = 2 then
		v_valor_custo = sigh.f_retorna_preco_custo_servico(linha.cod_serv);
		v_valor_limite_fisico = sigh.f_verifica_limite_fisico(linha);

		if v_excecao_preco <> 0 then
			v_valor_final = v_excecao_preco;
		elsif v_valor_limite_fisico <> 0 then
			v_valor_final = v_valor_limite_fisico;
		else
			--v_valor_final = sigh.f_retorna_preco_servico(linha.cod_serv,v_cod_categoria, v_tipo_atend, linha.data, linha.hora);		
			/* Inicio - (SIGH-20078) - (5123 - CH por ato não aplica para serviços) - (barbara.pereira) */
  			v_valor_final = sigh.f_retorna_preco_servico(linha.cod_serv, v_cod_categoria, linha.cod_tp_ato, v_tipo_atend, linha.data, linha.hora, false, true);
  			/* Fim - (SIGH-20078) - (5123 - CH por ato não aplica para serviços) - (barbara.pereira) */
		end if;
		v_valor_gerando_coparticipacao = v_valor_final;
	elsif linha.tipo_lanc = 3 then
		select into
			v_tipo_proc
			p.exame_proc
		from
			sigh.procedimentos p
		where
			p.id_procedimento = linha.cod_proc;

		v_valor_custo = sigh.f_retorna_preco_custo_proc(linha.cod_proc);
		v_valor_limite_fisico = sigh.f_verifica_limite_fisico(linha);

		if v_tipo_proc = 'EXAME' then
			if v_excecao_preco <> 0 then
				v_valor_final = v_excecao_preco;
			elsif v_valor_limite_fisico <> 0 then
				v_valor_final = v_valor_limite_fisico;
			else
				/*se possui regra por exames cai na validacao*/

				--Validacao valida apenas para os exames de menor valor valido
				--if (linha.cod_proc <> coalesce(v_iMaiorExame, 0)) then
					if(linha.id_lancamento <>  v_iMaiorExameID)then
						if (coalesce(v_bRedutor_unico, false) = true) then
							v_percentual_unico = coalesce(v_percentual_unico, 100);							
							--raise exception 'v_valor_final %', v_valor_final;

							--Calculo do filme para esta regra
							select
								into v_lanca_filme_param_categoria
								soma_filme_cp
							from
								sigh.categorias
							where
								id_categoria = v_cod_categoria;

							if (coalesce(v_lanca_filme_param_categoria, false))then
								v_id_proc_preco = sigh.f_registro_vigente((sigh.f_retorna_id_proc_preco(linha.cod_proc, v_cod_categoria, v_tipo_atend)), linha.data, 3);

								if v_id_proc_preco <> 0 then
									select into
										v_qtd_filme
										m2_filme
									from
										sigh.procedimentos_precos
									where
										id_proc_precos = v_id_proc_preco;

									/*guarda o valor do filme*/
									select into
										v_vlr_filme
										coalesce(va.valor_m2_filme,cat.valor_filme)
									from
										sigh.categorias cat
									left join sigh.valores_atos va on va.cod_categoria = cat.id_categoria and va.cod_tp_ato = linha.cod_tp_ato
									where
										cat.id_categoria = v_cod_categoria;

									--v_valor_final = v_valor_final + round((coalesce(v_vlr_filme,0)*coalesce(v_qtd_filme,0)*linha.quantidade),2);
									update sigh.lancamentos set
										params[2] = 'SOMA FILME='|| (coalesce(v_vlr_filme,0)*coalesce(v_qtd_filme,0)*linha.quantidade)
									where id_lancamento = linha.id_lancamento;
									linha.params[2] = 'SOMA FILME='|| (coalesce(v_vlr_filme,0)*coalesce(v_qtd_filme,0)*linha.quantidade);
								end if;
							end if;
							v_valor_final = sigh.f_retorna_preco_proc_reducao_exame(linha.cod_proc, v_cod_categoria, v_tipo_atend, linha.tipo_hon, linha.num_equipe, linha.bilateral, linha.mesma_via, false, linha.data, linha.hora, false, false, false, v_urgente_eletivo, v_cod_fia, v_percentual_unico, linha.cod_tp_ato, linha.params);
						elsif (coalesce(v_bRedutor_faixa, false) = true) then
							v_percentual_faixa = coalesce(v_percentual_faixa, 100);							
							--raise exception 'v_valor_final FAIXA ->>>>>>> %', v_valor_final;

							--Calculo do filme para esta regra
							select
								into v_lanca_filme_param_categoria
								soma_filme_cp
							from
								sigh.categorias
							where
								id_categoria = v_cod_categoria;

							if (coalesce(v_lanca_filme_param_categoria, false))then
								v_id_proc_preco = sigh.f_registro_vigente((sigh.f_retorna_id_proc_preco(linha.cod_proc, v_cod_categoria, v_tipo_atend)), linha.data, 3);

								if v_id_proc_preco <> 0 then
									select into
										v_qtd_filme
										m2_filme
									from
										sigh.procedimentos_precos
									where
										id_proc_precos = v_id_proc_preco;

									/*guarda o valor do filme*/
									select into
										v_vlr_filme
										coalesce(va.valor_m2_filme,cat.valor_filme)
									from
										sigh.categorias cat
									left join sigh.valores_atos va on va.cod_categoria = cat.id_categoria and va.cod_tp_ato = linha.cod_tp_ato
									where
										cat.id_categoria = v_cod_categoria;

									--v_valor_final = v_valor_final + round((coalesce(v_vlr_filme,0)*coalesce(v_qtd_filme,0)*linha.quantidade),2);
									update sigh.lancamentos set
										params[2] = 'SOMA FILME='|| (coalesce(v_vlr_filme,0)*coalesce(v_qtd_filme,0)*linha.quantidade)
									where id_lancamento = linha.id_lancamento;
									linha.params[2] = 'SOMA FILME='|| (coalesce(v_vlr_filme,0)*coalesce(v_qtd_filme,0)*linha.quantidade);
								end if;
							end if;
							v_valor_final = sigh.f_retorna_preco_proc_reducao_exame(linha.cod_proc, v_cod_categoria, v_tipo_atend, linha.tipo_hon, linha.num_equipe, linha.bilateral, linha.mesma_via, false, linha.data, linha.hora, false, false, false, v_urgente_eletivo, v_cod_fia, v_percentual_faixa, linha.cod_tp_ato, linha.params);
						end if;
					else						
						--Calculo do filme para esta regra
						select
							into v_lanca_filme_param_categoria
							soma_filme_cp
						from
							sigh.categorias
						where
							id_categoria = v_cod_categoria;

						if (coalesce(v_lanca_filme_param_categoria, false))then
							v_id_proc_preco = sigh.f_registro_vigente((sigh.f_retorna_id_proc_preco(linha.cod_proc, v_cod_categoria, v_tipo_atend)), linha.data, 3);

							if v_id_proc_preco <> 0 then
								select into
									v_qtd_filme
									m2_filme
								from
									sigh.procedimentos_precos
								where
									id_proc_precos = v_id_proc_preco;

								/*guarda o valor do filme*/
								select into
									v_vlr_filme
									coalesce(va.valor_m2_filme, cat.valor_filme)
								from
									sigh.categorias cat
								left join sigh.valores_atos va on va.cod_categoria = cat.id_categoria and va.cod_tp_ato = linha.cod_tp_ato
								where
									cat.id_categoria = v_cod_categoria;

								--v_valor_final = v_valor_final + round((coalesce(v_vlr_filme,0)*coalesce(v_qtd_filme,0)*linha.quantidade),2);
								update sigh.lancamentos set
									params[2] = 'SOMA FILME='|| (coalesce(v_vlr_filme,0)*coalesce(v_qtd_filme,0)*linha.quantidade)
								where id_lancamento = linha.id_lancamento;
								linha.params[2] = 'SOMA FILME='|| (coalesce(v_vlr_filme,0)*coalesce(v_qtd_filme,0)*linha.quantidade);
							end if;
						end if;
						v_valor_final = sigh.f_retorna_preco_proc(linha.cod_proc, v_cod_categoria, v_tipo_atend,linha.tipo_hon, linha.num_equipe, linha.bilateral, linha.mesma_via, v_mesmo_dia, linha.data, linha.hora, false, linha.diferentes_vias, linha.unica_via, v_urgente_eletivo, v_cod_fia, linha.cod_tp_ato, cast(linha.params as character varying[]), v_excecao_preco, false, true);
					end if;
				--else
					--Padrao
					--v_valor_final = sigh.f_retorna_preco_proc(linha.cod_proc, v_cod_categoria, v_tipo_atend, linha.data, linha.hora);
					--raise exception '1 %', linha.id_lancamento;
				--end if;
			end if;
		else
			if not v_convenio_ipe then
				v_id_proc_preco = sigh.f_registro_vigente((sigh.f_retorna_id_proc_preco(linha.cod_proc, v_cod_categoria, v_tipo_atend)), linha.data, 3);
			else
				v_id_proc_preco = sigh.f_registro_vigente((sigh.f_retorna_id_proc_preco_ipe(linha.cod_proc, v_cod_categoria, v_tipo_atend, linha.data)), linha.data, 3);
			end if;

			select into
				v_aplica_red_dias_dif
				aplica_red_dias_dif
			from
				sigh.categorias cat
				inner join sigh.convenios conv on (conv.id_convenio = cat.cod_convenio)
			where
				id_categoria = v_cod_categoria;

			select into
				v_linha_proc_preco
				*
			from
				sigh.procedimentos_precos
			where
				id_proc_precos = v_id_proc_preco;

			/*seleciona se tem algum procedimento executado no mesmo dia com num_equipe diferente*/
			select into
				v_data_ult_realizado
				max(data)
			from
				sigh.lancamentos
			where
				cod_conta = linha.cod_conta
				and num_equipe <> linha.num_equipe
				and data = linha.data;

			if v_data_ult_realizado is not null then
				v_mesmo_dia = true;
			else
				v_mesmo_dia = false;
				if not coalesce(v_aplica_red_dias_dif,false) then
					v_aplica_reducao = false;
				end if;
			end if;

			if coalesce(v_aplica_reducao,true)
			or (v_cbhpm and (v_tipo_proc = 'PROCEDIMENTO')) then

				if v_cbhpm and (v_tipo_proc = 'PROCEDIMENTO') then
					v_valor_final = sigh.f_retorna_preco_proc_reducao_exame(linha.cod_proc, v_cod_categoria, v_tipo_atend, linha.tipo_hon, linha.num_equipe, linha.bilateral, linha.mesma_via, v_mesmo_dia, linha.data, linha.hora, false, linha.diferentes_vias, linha.unica_via, v_urgente_eletivo, v_cod_fia, 0, linha.cod_tp_ato, linha.params);

				else
					/*se deve aplicar reducao, manda todas as variaveis normalmente para o procedimento*/
					v_valor_final = sigh.f_retorna_preco_proc(linha.cod_proc, v_cod_categoria, v_tipo_atend,linha.tipo_hon, linha.num_equipe, linha.bilateral, linha.mesma_via, v_mesmo_dia, linha.data, linha.hora, false, linha.diferentes_vias, linha.unica_via, v_urgente_eletivo, v_cod_fia, linha.cod_tp_ato, cast(linha.params as character varying[]), v_excecao_preco, false, true);
					if (coalesce(v_valor_final, 0) > 0) and (coalesce(v_preco_venda_unit_original, 0) > 0) then
						linha.percentual = ((v_valor_final/coalesce(v_preco_venda_unit_original, 1)) * 100);
					end if;
				end if;
			else
				/*caso no deva aplicar reducao, manda somente algumas variaveis, preenchendo o resto com null*/
				v_valor_final = sigh.f_retorna_preco_proc(linha.cod_proc, v_cod_categoria, v_tipo_atend, linha.tipo_hon, linha.num_equipe, null, null, null, linha.data, linha.hora, false, linha.diferentes_vias, linha.unica_via, v_urgente_eletivo, v_cod_fia, linha.cod_tp_ato, cast(linha.params as character varying[]), v_excecao_preco, false, true);
			end if;

			/*fazer verificacao se esta lancando auxiliar e descontar o valor do cirurgiao
			se houver. se for cirurgiao, diminuir o valor de auxiliares se já foram lançados*/
			/*recalculo: somente deduz os auxiliares do cirurgiao pois nao estao inserindo
			e sim, recalculando*/
			/*soh deduz se for conv. sus fo 8049*/

			if (linha.tipo_hon = 1) and ((select cat.cod_convenio from sigh.categorias cat where cat.id_categoria = v_cod_categoria) = (select pf.cod_conv_sus from sigh.params_faturamento pf limit 1)) then
				/*seleciona o valor total de aux. lancados para deduzir do cir. atual*/
				select into
					v_total_aux
					sum(preco_venda_unit)
				from
					sigh.lancamentos
				where
					cod_conta = linha.cod_conta
					and num_equipe = linha.num_equipe
					and tipo_hon in (2,3,4,5);

				v_total_aux = coalesce(v_total_aux,0);
				v_valor_final = v_valor_final - v_total_aux;
			end if;

			if v_excecao_preco <> 0 then
				v_valor_final = v_excecao_preco;
			elsif v_valor_limite_fisico <> 0 then
				v_valor_final = v_valor_limite_fisico;
			end if;
		end if;
		v_valor_gerando_coparticipacao = v_valor_final;

	elsif linha.tipo_lanc = 4 then
		select into
			v_kit_aberto
			, v_imposto_tabela
			, v_preco_imposto
			tipo_aberto_fechado
			, imposto_tabela
			, preco_imposto
		from
			sigh.kits
		where
			id_kit = linha.cod_kit;

		v_valor_custo = sigh.f_retorna_preco_custo_kit(linha.cod_kit);

		if v_kit_aberto = 'ABERTO' then
			v_valor_final = sigh.f_retorna_preco_kit(linha.cod_kit,v_cod_categoria,v_tipo_atend);
		else
			if v_imposto_tabela = 'I' then
				v_valor_final = v_preco_imposto;
			else
				v_valor_final = sigh.f_retorna_preco_kit(linha.cod_kit,v_cod_categoria,v_tipo_atend);
			end if;
		end if;
		v_valor_gerando_coparticipacao = v_valor_final;
	end if;

	/*nao multiplica valor de ch para filmes no rx e kits*/
	if ((v_filme = 'T') and (linha.cod_laudo is not null)) or (linha.tipo_lanc = 4) then
		--raise notice 'fazer nada....';
	else
		/*if (coalesce(v_excecao_preco, 0) = 0) then
			select into
				v_valor_ch
				vlr_sadt
			from
				sigh.valores_atos
			where
				cod_categoria = v_cod_categoria
				and cod_tp_ato = linha.cod_tp_ato;

			v_valor_ch = coalesce(v_valor_ch,1);*/

			/*multiplica pelo valor de ch*/
			/*v_valor_final = (v_valor_final * v_valor_ch);*/
			--raise exception 'v_valor_final filme %', v_valor_final;
		/*end if;*/

		/*Verifica as regras de cobrancas*/
		/* ## temporario */
		v_valor_excecoes_regra = sigh.f_excecoes_regras_cobrancas(v_valor_final,
									  linha.cod_proc,
									  v_cod_categoria,
									  linha.cod_prestador,
									  v_cod_convenio,
									  v_cod_especialidade,
									  v_tipo_proc,
									  v_cod_fia,
									  linha.data,
									  linha.hora,
									  linha.hora_fim,
									  linha.tipo_lanc,
									  linha.cod_tp_ato,
									  linha.cod_prod,
									  linha.cod_serv,
									  v_cod_unidade_fia,
									  v_urgente_eletivo,
									  linha.tipo_hon,
									  v_tipo_atend,
									  linha.cod_funcionario,
									  v_sTipoProd,
									  v_valor_porte_cirur_total,
									  v_valor_porte_anest_total,
									  v_sTipoPorte,
									  v_valor_custo_oper,
									  v_valor_uco,
									  v_tipo_leito);
		v_id_regra_cobranca = coalesce(sigh.f_excecoes_regras_cobrancas(v_valor_final,
									  linha.cod_proc,
									  v_cod_categoria,
									  linha.cod_prestador,
									  v_cod_convenio,
									  v_cod_especialidade,
									  v_tipo_proc,
									  v_cod_fia,
									  linha.data,
									  linha.hora,
									  linha.hora_fim,
									  linha.tipo_lanc,
									  linha.cod_tp_ato,
									  linha.cod_prod,
									  linha.cod_serv,
									  v_cod_unidade_fia,
									  v_urgente_eletivo,
									  linha.tipo_hon,
									  v_tipo_atend,
									  linha.cod_funcionario,
									  v_sTipoProd,
									  v_valor_porte_cirur_total,
									  v_valor_porte_anest_total,
									  v_sTipoPorte,
									  v_valor_custo_oper,
									  v_valor_uco,
									  v_tipo_leito,
									  true), 0.0);
		select into 
			v_regra_cobranca_multiplica,
			v_regra_cobranca_considera_perc
			regra_cobranca = 'M',
			considerar_percentual
		from 
			sigh.excecoes_regras_cobrancas
		where
			id_excecao_regra_cobranca = cast(v_id_regra_cobranca as integer);
			
		if v_id_regra_cobranca <> 0 then
			if (v_valor_final <> v_valor_excecoes_regra) and v_regra_cobranca_multiplica and v_regra_cobranca_considera_perc and (coalesce(v_valor_final, 0) > 0) then
				linha.percentual = (v_valor_excecoes_regra/v_valor_final)*100;
				v_valor_final = v_valor_excecoes_regra;
			elsif (v_valor_final <> v_valor_excecoes_regra) and ((not v_regra_cobranca_multiplica) or (not v_regra_cobranca_considera_perc)) then
				linha.percentual = 100;
				v_valor_final = v_valor_excecoes_regra;
			end if;
		elsif (v_valor_final = v_preco_venda_unit_original) then
			linha.percentual = 100;
		end if;
		/* ## */

		/* Inicio - (SIGH-20165) - (1961 - Valor errado para exames no IPE) - (barbara.pereira) */
		--Desabilitados Cálculos realizados abaixo (pois já estão sendo feitos na sigh.f_retorna_preco_proc)
		/*if (linha.tipo_lanc = 3) and (v_tipo_proc = 'EXAME') then
			/*soma valor do filme se assim indicar o array de params. formato de entrada SOMA FILME=X*/
			if linha.params is not null then
				for i in array_lower(linha.params,1)..array_upper(linha.params,1) loop
					if (strpos(linha.params[i], 'SOMA FILME') = 1) and (v_lanca_filme_param_categoria) then
						/*manda só a string soma filme se quiser que pegue o valor do filme no proc. preco*/
						if length(linha.params[i]) = length('SOMA FILME') then
							/*procura pelo valor do filme e soma*/
							--v_id_proc_preco = sigh.f_retorna_cod_proc_preco(v_cod_proc,v_cod_cat,v_tp_atend);
							v_id_proc_preco = sigh.f_registro_vigente((sigh.f_retorna_cod_proc_preco(v_cod_proc,v_cod_cat,v_tp_atend)), linha.data,3);

							if v_id_proc_preco <> 0 then
								select into
									v_qtd_filme
									m2_filme
								from
									sigh.procedimentos_precos
								where
									id_proc_precos = v_id_proc_preco;

								/*guarda o valor do filme*/
								select into
									v_vlr_filme
									coalesce(va.valor_m2_filme,cat.valor_filme)
								from
									sigh.categorias cat
								left join sigh.valores_atos va on va.cod_categoria = cat.id_categoria and va.cod_tp_ato = linha.cod_tp_ato
								where
									cat.id_categoria = v_cod_categoria;
					 
								v_valor_final = v_valor_final + (coalesce(v_vlr_filme,0)*coalesce(v_qtd_filme,0)*linha.quantidade);
							end if;
						else
							v_valor_final = v_valor_final + cast(trim(substr(linha.params[i], strpos(linha.params[i], '=')+1, length(linha.params[i]))) as util.dom_float);
						end if;

					elsif strpos(linha.params[i], 'SOMA CONTRASTE=') = 1 then
						v_valor_final = v_valor_final + cast(trim(substr(linha.params[i], strpos(linha.params[i], '=')+1, length(linha.params[i]))) as util.dom_float);
					
					end if;
				end loop;
			end if;
		end if; */
		/* Fim - (SIGH-20165) - (1961 - Valor errado para exames no IPE) - (barbara.pereira) */

		/*calcula copart. se conta principal*/
		if ((select tipo_conta from sigh.contas where id_conta = linha.cod_conta) = 'P') then
			/*para verificar se aplica percentual de reducao sobre copart*/
			select into
				v_percentual_lg_aplica_copart
				conv.percentual_lg_aplica_copart
			from
				sigh.convenios conv
			where
				conv.id_convenio = (select cat.cod_convenio from sigh.categorias cat where cat.id_categoria = v_cod_categoria);

			if linha.tipo_lanc = 1 then
				v_vlr_copart = sigh.f_retorna_valor_copart_produto(linha.cod_prod,v_cod_categoria,v_tipo_atend, linha.data);
				if v_vlr_copart <> 0 then
					/*multiplica o valor da copart pelo percentual tb*/
					if coalesce(v_percentual_lg_aplica_copart,false) then
						v_vlr_copart = coalesce(v_vlr_copart,0) * (linha.percentual/100);
					else
						v_vlr_copart = coalesce(v_vlr_copart,0);
					end if;
				end if;
			elsif linha.tipo_lanc = 2 then
				v_result_array_copart = sigh.f_retorna_valor_copart_servico(linha.cod_serv,v_cod_categoria,v_tipo_atend,linha.data);
				/*se o valor de copart eh <> 0*/
				if v_result_array_copart[2] <> 0 then
					if v_result_array_copart[1] = 1 then
						/*retornou em percentual*/
						v_vlr_copart = coalesce(v_valor_final,0) * (coalesce(v_result_array_copart[2],0) / 100);
						v_vlr_copart = coalesce(v_vlr_copart,0) * (coalesce(v_result_array_copart[3],0)/100);
					else
						/*retornou em valor*/
						v_vlr_copart = coalesce(v_result_array_copart[2],0);
						v_vlr_copart = coalesce(v_vlr_copart,0) * (coalesce(v_result_array_copart[3],0)/100);
					end if;
					/*multiplica o valor da copart pelo percentual tb*/
					if coalesce(v_percentual_lg_aplica_copart,false) then
						v_vlr_copart = coalesce(v_vlr_copart,0) * (linha.percentual/100);
					else
						v_vlr_copart = coalesce(v_vlr_copart,0);
					end if;
				end if;
			elsif linha.tipo_lanc = 3 then
																
				v_result_array_copart = sigh.f_retorna_valor_copart_proc(linha.cod_proc,v_cod_categoria,v_tipo_atend,linha.data);
				
				/*se o valor de copart eh <> 0*/
				if (v_result_array_copart[2] <> 0) or (coalesce(linha.cod_categoria_usuario, 0) <> 0) then
				
					/*multiplica o valor da copart pelo percentual tb*/
					--NAO CAIR NESTA REGRA QUANDO POSSUIR EXCECAO DE PRECO
					if (v_excecao_preco = 0) and (v_id_regra_cobranca = 0) then
						if coalesce(v_percentual_lg_aplica_copart,false) then
							--v_vlr_copart = coalesce(linha.preco_venda_unit,0) * (linha.percentual/100);
							--Utiliza o valor COM o % aplicado														
  						    v_vlr_copart = v_valor_final;							
						else
							--v_vlr_copart = coalesce(new.preco_venda_unit,0);							
 						    --v_vlr_copart = (coalesce(linha.preco_venda_unit,0) * (100/(coalesce(v_result_array_copart[3],0))));
							--Utiliza o valor SEM o % aplicado								
							v_preco_venda_sem_percentual := sigh.f_retorna_preco_proc(
								linha.cod_proc
								, v_cod_categoria
								, v_tipo_atend
								, linha.tipo_hon
								, linha.num_equipe
								, linha.bilateral
								, linha.mesma_via
								, null
								, linha.data
								, linha.hora
								, false
								, linha.diferentes_vias
								, linha.unica_via
								, v_urgente_eletivo
								, v_cod_fia
								, linha.cod_tp_ato
								, cast(linha.params as character varying[])
								, 0
								, false
								, false);							
 						    v_vlr_copart = v_preco_venda_sem_percentual; 							
						end if;
					else
						if coalesce(v_percentual_lg_aplica_copart,false) then
							v_vlr_copart = coalesce(v_excecao_preco,0) * (linha.percentual/100);
						else
							v_vlr_copart = coalesce(v_excecao_preco,0);
						end if;
					end if;
					
					if v_result_array_copart[1] = 1 then
						/*retornou em percentual*/						
						v_vlr_copart = coalesce(v_vlr_copart,0) * (coalesce(v_result_array_copart[2],0) / 100);
					else
						/*retornou em valor*/
						v_vlr_copart = coalesce(v_result_array_copart[2],0);												
					end if;
				
				end if;
			
			end if;
		
		end if;

		v_vlr_copart = coalesce(v_vlr_copart,0);

		/*multiplica o valor do preco final pelo percentual, deduzindo, depois, o valor de copart previamente reajustado pelo percentual*/
		--v_valor_final = (v_valor_final * (linha.percentual/100)) - v_vlr_copart;
		v_valor_final = (v_valor_final - v_vlr_copart);
	end if;

	if coalesce(v_gera_coparticipacao_via_conta, false) then
		v_valor_final = v_valor_gerando_coparticipacao;
	end if;

	--Nova validacao para regras de cobranca
	select into
		v_bConsideraPercRegra
		coalesce(rc.considerar_percentual, false)
	from
		sigh.excecoes_regras_cobrancas rc
	where
	    (
			case coalesce(v_Tipo_atend, '')
				when '' then (rc.permite_todos = true)
				when 'AMB' then (rc.permite_amb = true or rc.permite_todos = true)
				when 'EXT' then (rc.permite_ext = true or rc.permite_todos = true)
				when 'INT' then (rc.permite_int = true or rc.permite_todos = true)
			end
		) = true
		and to_char(rc.hora_inicio, 'HH24:MI') <= to_char(cast(linha.hora as time), 'HH24:MI')  --:hora_ini_lanc
		and to_char(rc.hora_fim, 'HH24:MI') >= to_char(cast(coalesce(linha.hora_fim, linha.hora) as time), 'HH24:MI')  --:hora_fim_lanc
		and
		(
		 case
			when rc.habilita_todos then
				true
			else
			Exists(select 1
					from sigh.excecoes_regras_cobrancas
					where extract(dow from cast(linha.data as date))
					in
					 (case rc.habilita_domingo when true then 0 end,
					  case rc.habilita_segunda when true then 1 end,
					  case rc.habilita_terca when true then 2 end,
					  case rc.habilita_quarta when true then 3 end,
					  case rc.habilita_quinta when true then 4 end,
					  case rc.habilita_sexta when true then 5 end,
					  case rc.habilita_sabado when true then 6 end))
		end
		or
			(
				case
					when rc.habilita_feriados then
						Exists(select f.data
								from util.feriados f
								where f."data" = cast(linha.data as date) --:data
							   )
				end
			)
		)
		and (
				case coalesce(v_urgente_eletivo, '')
					when ''  then rc.tipo_classificacao in ('ELETIVO', 'URGENTE', 'AMBOS')
					when 'ELETIVO' then rc.tipo_classificacao in ('ELETIVO', 'AMBOS')
					when 'URGENTE' then rc.tipo_classificacao in ('URGENTE', 'AMBOS')
				end
			)--:tipo_class
		and (
				case rc.tipo_lancamento
					when 'PRO' then 3
					when 'MAT' then 1
					when 'OPM' then 1
					when 'MED' then 1
					when 'TAX' then 2
				end
			) = linha.tipo_lanc --:tipo_lanc
		and
			case
				--when iCod_unidade is null then
				--	true
				when not exists(select u.cod_unidade from sigh.unidades_cobranca u where u.cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					v_cod_unidade_fia in (
										select u.cod_unidade
										from sigh.unidades_cobranca u
										where u.cod_regra_cob = rc.id_excecao_regra_cobranca
							   		  )
			end
		and
			case
				--when iCod_conv is null then
				--	true
				when not exists(select c.cod_convenio from sigh.convenios_cobranca c where c.selecionado = true and c.cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					v_cod_convenio in (
									select cc.cod_convenio
									from sigh.convenios_cobranca cc
									where cc.selecionado = true and cc.cod_regra_cob = rc.id_excecao_regra_cobranca
								 )
			end
		and
			case
				--when iCod_cat is null then
				--	true
				when not exists(select c.cod_categoria from sigh.categorias_cobranca c where c.selecionado = true and c.cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					v_cod_categoria in (
									select cc.cod_categoria
									from sigh.categorias_cobranca cc
									where cc.selecionado = true and cc.cod_regra_cob = rc.id_excecao_regra_cobranca
								)
			end
		and
			case
				--when iCod_esp is null then
				--	true
				when not exists(select cod_especialidade from sigh.especialidades_cobranca where cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					v_cod_especialidade in (
									select cod_especialidade
									from sigh.especialidades_cobranca
									where cod_regra_cob = rc.id_excecao_regra_cobranca
							   	)
			end
		and
			case
				--when iCod_prest is null then
				--	true
				when not exists(select cod_prestador from sigh.prestadores_cobranca where cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					linha.cod_prestador in (
									select cod_prestador
									from sigh.prestadores_cobranca
									where cod_regra_cob = rc.id_excecao_regra_cobranca
							   	)
			end
		and
			case
				--when iCod_func is null then
				--	true
				when not exists(select cod_funcionario from sigh.funcionarios_cobranca where cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					linha.cod_funcionario in (
									select cod_funcionario
									from sigh.funcionarios_cobranca
									where cod_regra_cob = rc.id_excecao_regra_cobranca
							   	)
			end
		and
			case
				--when iCod_ato is null then
				--	true
				when not exists(select cod_ato from sigh.atos_cobranca where cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					linha.cod_tp_ato in (
									select cod_ato
									from sigh.atos_cobranca
									where cod_regra_cob = rc.id_excecao_regra_cobranca
							   	)
			end
		and
			case
				--when iCod_proc is null then
				--	true
				when not exists(select cod_procedimento from sigh.procedimentos_cobranca where cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					linha.cod_proc in (
									select cod_procedimento
									from sigh.procedimentos_cobranca
									where cod_regra_cob = rc.id_excecao_regra_cobranca
							   	)
			end
		and
			case
				--when icod_item is null then
				--	true
				when not exists(select cod_produto from sigh.produtos_cobranca where cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					linha.cod_prod in (
									select cod_produto
									from sigh.produtos_cobranca
									where cod_regra_cob = rc.id_excecao_regra_cobranca
							   	)
			end
		and
			case
				--when iCod_serv is null then
				--	true
				when not exists(select cod_servico from sigh.servicos_cobranca where cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					linha.cod_serv in (
									select cod_servico
									from sigh.servicos_cobranca
									where cod_regra_cob = rc.id_excecao_regra_cobranca
							   	)
			end
		and
			case
				--when iCod_grau is null then
				--	true
				when not exists(select cod_grau from sigh.grau_cobranca where cod_regra_cob = rc.id_excecao_regra_cobranca) then
					true
				else
					linha.tipo_hon in (
									select cod_grau
									from sigh.grau_cobranca
									where cod_regra_cob = rc.id_excecao_regra_cobranca
							   	)
			end
		and rc.data_ini <= cast(linha.data as date)
		and rc.data_fim >= cast(linha.data as date)
		and ((rc.tipo_lancamento = v_sTipoProd) or (coalesce(v_sTipoProd, '') = ''))
	order by id_excecao_regra_cobranca desc
	limit 1;

	if v_preco_venda_unit_original = 0 then
		v_preco_venda_unit_original = 1;
	end if;

	--if(coalesce(v_bConsideraPercRegra, false) = False)then
	--	linha.percentual = 100;
	--end if;

	/* ## Ajuste temporario ## */
	/*
			v_valor_final := sigh.f_excecoes_regras_cobrancas(v_valor_final,
														  linha.cod_proc,
														  v_cod_categoria,
														  linha.cod_prestador,
														  v_cod_convenio,
														  v_cod_especialidade,
														  v_tipo_proc,
														  v_cod_fia,
														  linha.data,
														  linha.hora,
														  linha.hora_fim,
														  linha.tipo_lanc,
														  linha.cod_tp_ato,
														  linha.cod_prod,
														  linha.cod_serv,
														  v_cod_unidade_fia,
														  v_urgente_eletivo,
														  linha.tipo_hon,
														  v_tipo_atend,
														  linha.cod_funcionario,
														  v_sTipoProd,
														  v_valor_porte_cirur_total,
														  v_valor_porte_anest_total,
														  v_sTipoPorte,
														  v_valor_custo_oper,
														  v_valor_uco,
														  v_tipo_leito);
	*/
	/* ## Final ajuste temporario */

	-- FOI DESCOMENTADO ESSE IF PARA O TICKET SIGH-14220
	if ((coalesce(v_bConsideraPercRegra, false) = True) or ((v_excecao_preco <> 0) and (linha.percentual = 100))) and (coalesce(v_preco_venda_unit_original, 0) > 0) and (v_id_regra_cobranca = 0) then
		linha.percentual = ((v_valor_final/coalesce(v_preco_venda_unit_original, 1)) * 100);
	end if;

	--Se possuir excecao de preco, considerar o valor original da excecao
	if(coalesce(v_bConsideraPercRegra, false) = True)then
		if v_excecao_preco <> 0 then
			select into
				v_preco_excecao_original
				preco
			from
				sigh.excecoes_precos
			where
				cod_convenio = v_cod_convenio
				and (
					cod_produto = linha.cod_prod
					or cod_produto is null
				)
				and (
					cod_procedimento = linha.cod_proc
					or cod_procedimento is null
				)
				and (
					cod_servico = linha.cod_serv
					or cod_servico is null
				)
				and (
					trim(tp_atendimento) = v_tipo_atend
					or trim(tp_atendimento) = 'TOD'
				)
				and (
					(coalesce(cod_categoria,0) = 0)
					or (cod_categoria = v_cod_categoria)
				)
				and (
					linha.data between data_periodo_inicial and coalesce(data_periodo_final, CURRENT_DATE+1)
				);
			linha.percentual = ((v_valor_final/coalesce(v_preco_excecao_original, 1)) * 100);
		else
			if (v_preco_venda_unit_original <> 0) and (v_id_regra_cobranca = 0) then
				linha.percentual = ((v_valor_final/coalesce(v_preco_venda_unit_original, 1)) * 100);
			end if;
		end if;
	end if;
	
	--Inserida atualização do Percentual abaixo cfe já existente na sigh.f_insere_lancamentos 
	if (linha.percentual = 100) then
		if (linha.tipo_lanc = 3) then
			v_percentual_f_acrescimo_horario_especial = sigh.f_retorna_preco_proc(linha.cod_proc
																				  , v_cod_categoria
																				  , v_tipo_atend
																				  , linha.tipo_hon
																				  , linha.num_equipe
																				  , linha.bilateral
																				  , linha.mesma_via
																				  , v_mesmo_dia
																				  , linha.data
																				  , linha.hora
																				  , true
																				  , false
																				  , false
																				  , v_urgente_eletivo
																				  , null --id_fia
																				  , linha.cod_tp_ato --v_cod_tp_ato
																				  , cast(linha.params as character varying[])
																				  , 0
																				  , false
																				  , true -- v_aplica_percentual
																				  , false
																				  );			
			if (v_percentual_f_acrescimo_horario_especial <> 100 and v_percentual_f_acrescimo_horario_especial <> 0) then				
				linha.percentual = v_percentual_f_acrescimo_horario_especial;
				v_percentual_debug = linha.percentual;
			end if;
		end if;

		if (linha.tipo_lanc = 2) then
			v_percentual_f_acrescimo_horario_especial = sigh.f_retorna_preco_servico(linha.cod_serv
																					, v_cod_categoria
																					, linha.cod_tp_ato
																					, v_tipo_atend
																					, linha.data
																					, linha.hora
																					, true
	 																			    , true);																
			if (v_percentual_f_acrescimo_horario_especial <> 100 and v_percentual_f_acrescimo_horario_especial <> 0) then				
				linha.percentual = v_percentual_f_acrescimo_horario_especial;
				v_percentual_debug = linha.percentual;
			end if;
		end if;
	end if;

	if linha.percentual = 0 then
		linha.percentual = 100;
	end if;

	if ((not linha.valor_manual) and (linha.tipo_lanc = 2) and (v_tipo_conta = 'A')) then
		select into
			v_tp_servico
			tp_servico
		from
			sigh.servicos
		where
			id_servico = linha.cod_serv;
		
		select into
			v_cod_servico_diferenca
			, v_valor_unit_debug
			diaria_diferenca_pac
			, diaria_diferenca_pac_valor  
		from 
			sigh.ficha_amb_int 
		where id_fia = v_cod_fia;
		
		if ((linha.cod_serv = v_cod_servico_diferenca) and (v_tp_servico = 'D')) then
			v_valor_final = v_valor_unit_debug;
		end if;
	end if;

	if v_atualiza then
		update
			sigh.lancamentos
		set
			preco_venda_unit = v_valor_final
			, preco_custo_unit = v_valor_custo
			, percentual = linha.percentual
			, valor_manual = false
			, valor_original = v_preco_venda_unit_original
		where
			id_lancamento = v_cod_lanc;
	end if;

	return v_valor_final;

end;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION sigh.f_recalcula_lancamento(integer, boolean, boolean)  OWNER TO hd_backup;
GRANT EXECUTE ON FUNCTION sigh.f_recalcula_lancamento(integer, boolean, boolean) TO hd_backup;
GRANT EXECUTE ON FUNCTION sigh.f_recalcula_lancamento(integer, boolean, boolean) TO public;
GRANT EXECUTE ON FUNCTION sigh.f_recalcula_lancamento(integer, boolean, boolean) TO hd_suporte;
GRANT EXECUTE ON FUNCTION sigh.f_recalcula_lancamento(integer, boolean, boolean) TO hd;
GRANT EXECUTE ON FUNCTION sigh.f_recalcula_lancamento(integer, boolean, boolean) TO admin;
GRANT EXECUTE ON FUNCTION sigh.f_recalcula_lancamento(integer, boolean, boolean) TO consultas;
