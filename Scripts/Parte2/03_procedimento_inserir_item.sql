-- Parte 2, questões 1 e 3
-- Regra semântica: uma linha de fatura deve ter quantidade e preço positivos.
-- A conta de aplicação insere linhas somente por este procedimento.

CREATE SEQUENCE IF NOT EXISTS public.invoice_line_id_seq;
SELECT setval('public.invoice_line_id_seq',
              COALESCE((SELECT max(invoice_line_id) FROM public.invoice_line), 0) + 1,
              false);

CREATE OR REPLACE PROCEDURE public.registrar_item_fatura(
    p_invoice_id integer,
    p_track_id integer,
    p_unit_price numeric,
    p_quantity integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'A quantidade deve ser maior que zero';
    END IF;
    IF p_unit_price IS NULL OR p_unit_price <= 0 THEN
        RAISE EXCEPTION 'O preço unitário deve ser maior que zero';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.invoice WHERE invoice_id = p_invoice_id) THEN
        RAISE EXCEPTION 'Fatura % não encontrada', p_invoice_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.track WHERE track_id = p_track_id) THEN
        RAISE EXCEPTION 'Faixa % não encontrada', p_track_id;
    END IF;

    INSERT INTO public.invoice_line(invoice_line_id, invoice_id, track_id, unit_price, quantity)
    VALUES (nextval('public.invoice_line_id_seq'), p_invoice_id, p_track_id,
            p_unit_price, p_quantity);
END;
$$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'operador_faturas') THEN
        EXECUTE 'CREATE ROLE operador_faturas LOGIN';
    END IF;
END $$;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.invoice_line FROM operador_faturas;
REVOKE ALL ON SEQUENCE public.invoice_line_id_seq FROM operador_faturas;
REVOKE EXECUTE ON PROCEDURE public.registrar_item_fatura(integer, integer, numeric, integer) FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO operador_faturas;
GRANT EXECUTE ON PROCEDURE public.registrar_item_fatura(integer, integer, numeric, integer)
    TO operador_faturas;

-- Defina uma senha para o login operador_faturas no pgAdmin antes de conectá-lo.
-- O usuário pode CALL public.registrar_item_fatura(fatura, faixa, preço, quantidade),
-- mas não possui INSERT/UPDATE/DELETE direto em invoice_line.
