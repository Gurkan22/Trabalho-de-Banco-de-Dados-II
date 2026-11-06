# Regras semânticas

## Parte 1: estados de fatura

O estado operacional de uma fatura é armazenado em `fatura_fluxo`, sem modificar a tabela original do Chinook. Estados válidos: `aberta`, `paga` e `cancelada`. Uma fatura começa `aberta`; a partir dela pode ser paga ou cancelada. Estados finais não podem ser reabertos nem alternados. A tabela de estados e transições torna a regra configurável e reutilizável.

## Parte 2: linhas de fatura

1. Uma fatura só pode passar para o estado `paga` se tiver ao menos uma linha em `invoice_line`. O trigger `validar_fatura_com_itens_ao_pagar` verifica dados de outra tabela antes da transição.
2. Cada linha de fatura deve ter quantidade e preço unitário maiores que zero. O procedimento `registrar_item_fatura` valida a regra antes da inserção. A role `operador_faturas` recebe execução do procedimento, sem DML direto sobre `invoice_line`.
3. Para cada fatura, `invoice.total` deve ser igual à soma de `invoice_line.unit_price * invoice_line.quantity`. Triggers recalculam o total por incrementos a cada inclusão, alteração ou remoção de linha; outros comandos não podem alterar esse total diretamente, e novas faturas começam com total zero. O script sincroniza os totais existentes na instalação inicial.

## Cenários de demonstração

- Parte 1: inserir uma fatura no fluxo como `aberta`; transicionar para `cancelada`; tentar `cancelada -> aberta` e confirmar a rejeição. O script de demonstração reverte a transação ao final.
- Parte 2: tentar pagar uma fatura sem linhas; chamar o procedimento com valores válidos e conferir o total; testar quantidade zero; tentar DML direto com `operador_faturas` e confirmar falta de privilégio.
