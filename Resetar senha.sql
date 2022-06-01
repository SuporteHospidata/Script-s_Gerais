-- altera para solicitar nova senha no proximo login
update conf.usuarios set muda_password = 't' where not username ilike 'HD_%'
