# Trabalho de Banco de Dados II

> Trabalho acadêmico de Banco de Dados II com PostgreSQL e o esquema Chinook. O projeto explora catálogos do SGBD, programação no banco, triggers, procedimentos armazenados, controle de permissões e regras de integridade.

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![SQL](https://img.shields.io/badge/SQL-PL%2FpgSQL-336791?style=flat-square)](https://www.postgresql.org/docs/current/plpgsql.html)

---

## Sobre o projeto

O trabalho está dividido em duas partes. A primeira consulta os metadados do Chinook, gera comandos DDL a partir do catálogo e demonstra uma solução configurável para validar transições de estado. A segunda implementa regras semânticas com triggers e procedimentos, incluindo o controle do total das faturas a partir de seus itens.

---

## Integrantes

- Amanda Souza Zírpolo
- Joao Vitor Carvalho Cecim
- Pedro Lucas Almeida dos Santos
- Victor Hugo Magalhaes de Oliveira

---

## Estrutura

```
Trabalho-de-Banco-de-Dados-II/
├── Database/
│   └── Chinook_PostgreSql.sql       # Esquema e dados de exemplo
├── Scripts/
│   ├── Parte1/                      # Catálogo, índices, DDL e DTE
│   └── Parte2/                      # Regras semânticas, triggers e procedures
├── Regras_semanticas.md             # Descrição das regras e cenários
└── README.md
```

---

## Tecnologias utilizadas

| Tecnologia | Uso |
|---|---|
| PostgreSQL | SGBD escolhido para o trabalho |
| SQL | Consultas, DDL e manipulação dos dados |
| PL/pgSQL | Procedures, funções e triggers |
| pgAdmin 4 | Administração do banco e execução dos scripts |

---

## Como executar

### 1. Clone o repositório

```bash
git clone https://github.com/Gurkan22/Trabalho-de-Banco-de-Dados-II.git
cd Trabalho-de-Banco-de-Dados-II
```

### 2. Crie o banco de exemplo

No pgAdmin, crie o banco `chinook` e execute `Database/Chinook_PostgreSql.sql` nele. Esse arquivo é o script PostgreSQL do projeto [lerocha/chinook-database](https://github.com/lerocha/chinook-database). Ao executar pelo Query Tool do pgAdmin, mantenha comentados os comandos `DROP DATABASE`, `CREATE DATABASE` e `\c`.

### 3. Execute os scripts do trabalho

Abra os arquivos no Query Tool conectado ao banco `chinook` e execute-os nesta ordem:

1. `Scripts/Parte1/01_consulta_indices.sql`
2. `Scripts/Parte1/02_remover_indices_tabela.sql`
3. `Scripts/Parte1/03_consulta_chaves_estrangeiras.sql`
4. `Scripts/Parte1/04_gerar_ddl_esquema.sql`
5. `Scripts/Parte1/05_dte_fatura.sql`
6. `Scripts/Parte2/01_manter_total_fatura.sql`
7. `Scripts/Parte2/02_trigger_regra_semantica.sql`
8. `Scripts/Parte2/03_procedimento_inserir_item.sql`
9. `Scripts/Parte2/04_cenarios_teste.sql`

Os cenários automatizados terminam com `ROLLBACK`. O script de índices apenas cria o procedimento; a chamada de remoção está comentada. Execute os scripts de criação como proprietário ou administrador do banco. Depois do passo 8, defina uma senha para a role `operador_faturas` no pgAdmin para testar seu acesso restrito.

As regras semânticas e os cenários estão detalhados em [Regras_semanticas.md](Regras_semanticas.md).

## Programação com banco de dados

O trabalho implementa lógica dentro do PostgreSQL com PL/pgSQL: procedures para remoção de índices e inserção controlada, função para gerar DDL, funções de trigger para validar estados e regras semânticas e triggers para manter os totais das faturas. As consultas de catálogo das questões 1 e 3 da Parte 1 são consultas SQL porque o enunciado pede explicitamente a leitura dos catálogos.

---

