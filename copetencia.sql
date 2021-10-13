-- alterar a data da última copetência SigTap



update conf.parametros_conf set ultima_competencia_sigtap = '202004'; -- ANO + MES juntos


-- se a copetencia estiver no mes 02/2021 colocar a data "202110" pois a data de hoje é 11/10/2021 e atualuizar o ultimo mês.