-- Parte 1, questão 3
-- Lista as chaves estrangeiras do esquema public e o mapeamento
-- entre as colunas locais e as colunas referenciadas.

SELECT
    src_ns.nspname AS esquema,
    src_tbl.relname AS tabela,
    con.conname AS chave_estrangeira,
    string_agg(
        format('%I -> %I', src_att.attname, dst_att.attname),
        ', ' ORDER BY src_col.ord
    ) AS colunas,
    dst_ns.nspname AS esquema_referenciado,
    dst_tbl.relname AS tabela_referenciada,
    pg_get_constraintdef(con.oid) AS definicao
FROM pg_constraint AS con
JOIN pg_class AS src_tbl
    ON src_tbl.oid = con.conrelid
JOIN pg_namespace AS src_ns
    ON src_ns.oid = src_tbl.relnamespace
JOIN pg_class AS dst_tbl
    ON dst_tbl.oid = con.confrelid
JOIN pg_namespace AS dst_ns
    ON dst_ns.oid = dst_tbl.relnamespace
CROSS JOIN LATERAL unnest(con.conkey) WITH ORDINALITY AS src_col(attnum, ord)
JOIN LATERAL unnest(con.confkey) WITH ORDINALITY AS dst_col(attnum, ord)
    ON dst_col.ord = src_col.ord
JOIN pg_attribute AS src_att
    ON src_att.attrelid = con.conrelid
   AND src_att.attnum = src_col.attnum
JOIN pg_attribute AS dst_att
    ON dst_att.attrelid = con.confrelid
   AND dst_att.attnum = dst_col.attnum
WHERE con.contype = 'f'
  AND src_ns.nspname = 'public'
GROUP BY
    src_ns.nspname,
    src_tbl.relname,
    con.conname,
    dst_ns.nspname,
    dst_tbl.relname,
    con.oid
ORDER BY
    src_ns.nspname,
    src_tbl.relname,
    con.conname;
