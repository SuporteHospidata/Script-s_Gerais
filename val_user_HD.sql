-- Aumentar a data de validade do usuários HD usar o sistema:

UPDATE conf.usuarios set
expiration_date = '2030-10-10', --expira date 
max_days_innative = 9999, 
max_bad_logins = 9999,
time_out = 9999, 
tempo_modo_espera = 9998,
confirmasair = 't',
recebe_newsletter = 'f',
gravacao_automatica = 'f',
permite_voltar_esc_lookup = 't',
abrir_menu_flutuante = 'f',
nao_receber_permissoes_automaticas = 't'
WHERE id_usuario = (select id_usuario from conf.usuarios where username = 'HD_SUPORTE');  -- User

-----------------------------------------------------------------------------------------------------------------------------------

UPDATE conf.usuarios set expiration_date = '2030-10-10', --expira  date
 max_days_innative = 9999, max_bad_logins = 9999, time_out = 9999,  
 tempo_modo_espera = 9998, 
 confirmasair = 't', 
 recebe_newsletter = 'f', 
 gravacao_automatica = 'f', 
 permite_voltar_esc_lookup = 't', 
 abrir_menu_flutuante = 'f', 
 nao_receber_permissoes_automaticas = 't'
WHERE id_usuario = (select id_usuario from conf.usuarios where username = 'HD_SUPORTE'); --User 

--------------------------------------------------------------------------------------------------------------------------------------

UPDATE conf.usuarios set expiration_date = '2030-10-10', --expira date 
  max_days_innative = 9999, 
 max_bad_logins = 9999, 
 time_out = 9999,  
 tempo_modo_espera = 9998, confirmasair = 't', 
recebe_newsletter = 'f', gravacao_automatica = 'f', 
 permite_voltar_esc_lookup = 't', abrir_menu_flutuante = 'f', 
 nao_receber_permissoes_automaticas = 't' WHERE id_usuario = (select id_usuario from conf.usuarios where username = 'HD_FATURAMENTO'); --User
 
 -----------------------------------------------------------------------------------------------------------------------------------------
