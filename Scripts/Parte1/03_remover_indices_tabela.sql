-- Parte 1, questão 2
-- Remove índices independentes de uma tabela. Índices que sustentam
-- PRIMARY KEY/UNIQUE/EXCLUDE são preservados (não podem ser removidos isoladamente).

CREATE OR REPLACE PROCEDURE public.remover_indices_tabela(
    p_tabela text,
    p_esquema text DEFAULT 'public'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_indice record;
BEGIN
    IF to_regclass(format('%I.%I', p_esquema, p_tabela)) IS NULL THEN
        RAISE EXCEPTION 'Tabela %.% não encontrada', p_esquema, p_tabela;
    END IF;

    FOR v_indice IN
        SELECT idx.relname AS nome
        FROM pg_index AS i
        JOIN pg_class AS tbl ON tbl.oid = i.indrelid
        JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
        JOIN pg_class AS idx ON idx.oid = i.indexrelid
        WHERE ns.nspname = p_esquema
          AND tbl.relname = p_tabela
          AND NOT EXISTS (
              SELECT 1
              FROM pg_constraint AS con
              WHERE con.conindid = i.indexrelid
          )
    LOOP
        EXECUTE format('DROP INDEX %I.%I', p_esquema, v_indice.nome);
    END LOOP;
END;
$$;

-- Exemplo: CALL public.remover_indices_tabela('invoice_line');
