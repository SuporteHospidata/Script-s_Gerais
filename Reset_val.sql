-- resetar o reset do sistema

 --Selecionar aplicação que deseja aplicar e rodar via banco de dados, após aparecera a mensagem de reset.

  update sigh.hospitais set lib_atualizacao =
'71b6a64ad43af28b5596ce173a9ed3cb'; -- SIGH

update ipe.hospitais set lib_atualizacao =
'71b6a64ad43af28b5596ce173a9ed3cb'; -- IPE

update aihu.hospitais set lib_atualizacao =
'71b6a64ad43af28b5596ce173a9ed3cb'; -- AIHU

update ambsusu.hospitais set lib_atualizacao =
'71b6a64ad43af28b5596ce173a9ed3cb'; -- AMBSUS

update apac.hospitais set lib_atualizacao =
'71b6a64ad43af28b5596ce173a9ed3cb'; -- APAC

update cihu.hospital set lib_atualizacao =
'71b6a64ad43af28b5596ce173a9ed3cb'; -- CIHU

update sighfat.hospitais set lib_atualizacao =
'71b6a64ad43af28b5596ce173a9ed3cb'; -- SIGFAT

update custo.hospitais set lib_atualizacao =
'71b6a64ad43af28b5596ce173a9ed3cb'; -- CUSTO