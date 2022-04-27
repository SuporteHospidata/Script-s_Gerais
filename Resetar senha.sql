-- altera para solicitar nova senha no proximo login, exceto usuarios que sejam hd_% (faturamento, suporte, etc...)

update conf.usuarios set muda_password = 'T' where not username ilike '%HD_%'; 
