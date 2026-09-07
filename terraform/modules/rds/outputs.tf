# Mapa completo (endereço, usuário, senha sensível, nome do banco) por serviço
output "databases" {
  value = {
    for k, v in aws_db_instance.this : k => {
      address         = v.address
      db_name         = v.db_name
      master_username = v.username
      password        = random_password.this[k].result
    }
  }
  sensitive = true
}
