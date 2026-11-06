-- Parte 1, questão 4
-- Gera DDL para tabelas comuns, colunas, nulabilidade, chaves primárias e FKs.
-- O resultado é texto SQL; revise e execute-o no banco/schema de destino.

CREATE OR REPLACE FUNCTION public.gerar_ddl_esquema(p_esquema text DEFAULT 'public')
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_tabela record;
    v_colunas text;
    v_pk text;
    v_ddl text := '';
    v_fk record;
BEGIN
    FOR v_tabela IN
        SELECT c.oid, c.relname
        FROM pg_class AS c
        JOIN pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = p_esquema AND c.relkind IN ('r', 'p')
        ORDER BY c.relname
    LOOP
        SELECT string_agg(
            format('    %I %s%s%s', a.attname, format_type(a.atttypid, a.atttypmod),
                   CASE WHEN a.attnotnull THEN ' NOT NULL' ELSE '' END,
                   CASE WHEN d.adbin IS NOT NULL THEN ' DEFAULT ' || pg_get_expr(d.adbin, d.adrelid) ELSE '' END),
            E',\n' ORDER BY a.attnum)
        INTO v_colunas
        FROM pg_attribute AS a
        LEFT JOIN pg_attrdef AS d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
        WHERE a.attrelid = v_tabela.oid AND a.attnum > 0 AND NOT a.attisdropped;

        SELECT pg_get_constraintdef(con.oid)
        INTO v_pk
        FROM pg_constraint AS con
        WHERE con.conrelid = v_tabela.oid AND con.contype = 'p';

        v_ddl := v_ddl || format('CREATE TABLE %I.%I (', p_esquema, v_tabela.relname)
            || E'\n' || v_colunas
            || CASE WHEN v_pk IS NOT NULL THEN E',\n    ' || v_pk ELSE '' END
            || E'\n);\n\n';
    END LOOP;

    -- FKs são adicionadas depois das tabelas para suportar dependências cíclicas.
    FOR v_fk IN
        SELECT con.conname, src.relname AS tabela,
               pg_get_constraintdef(con.oid) AS definicao
        FROM pg_constraint AS con
        JOIN pg_class AS src ON src.oid = con.conrelid
        JOIN pg_namespace AS n ON n.oid = src.relnamespace
        WHERE n.nspname = p_esquema AND con.contype = 'f'
        ORDER BY src.relname, con.conname
    LOOP
        v_ddl := v_ddl || format('ALTER TABLE %I.%I ADD CONSTRAINT %I %s;\n',
                                p_esquema, v_fk.tabela, v_fk.conname, v_fk.definicao);
    END LOOP;
    RETURN v_ddl;
END;
$$;

SELECT public.gerar_ddl_esquema('public') AS ddl_gerado;
