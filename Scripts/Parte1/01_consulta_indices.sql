-- Parte 1, questão 1
-- Lista os índices das tabelas do esquema public do Chinook,
-- com suas colunas (na ordem definida no índice) e definição SQL.

SELECT
    ns.nspname AS esquema,
    tbl.relname AS tabela,
    idx.relname AS indice,
    i.indisprimary AS chave_primaria,
    i.indisunique AS unico,
    am.amname AS metodo,
    string_agg(
        COALESCE(att.attname, pg_get_indexdef(i.indexrelid, key_col.ord::integer, true)),
        ', ' ORDER BY key_col.ord
    ) AS colunas_indexadas,
    pg_get_indexdef(i.indexrelid) AS definicao
FROM pg_index AS i
JOIN pg_class AS tbl
    ON tbl.oid = i.indrelid
JOIN pg_namespace AS ns
    ON ns.oid = tbl.relnamespace
JOIN pg_class AS idx
    ON idx.oid = i.indexrelid
JOIN pg_am AS am
    ON am.oid = idx.relam
CROSS JOIN LATERAL unnest(i.indkey) WITH ORDINALITY AS key_col(attnum, ord)
LEFT JOIN pg_attribute AS att
    ON att.attrelid = tbl.oid
   AND att.attnum = key_col.attnum
WHERE ns.nspname = 'public'
  AND key_col.ord <= i.indnkeyatts
GROUP BY
    ns.nspname,
    tbl.relname,
    idx.relname,
    i.indisprimary,
    i.indisunique,
    am.amname,
    i.indexrelid
ORDER BY
    ns.nspname,
    tbl.relname,
    idx.relname;
