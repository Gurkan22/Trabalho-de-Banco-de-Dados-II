-- Parte 1, questão 5: DTE genérico aplicado a um fluxo de faturas.
-- Não altera Invoice do Chinook; registra o estado numa tabela relacionada.

CREATE TABLE IF NOT EXISTS public.dte_estado_valido (
    entidade text NOT NULL,
    estado text NOT NULL,
    inicial boolean NOT NULL DEFAULT false,
    PRIMARY KEY (entidade, estado)
);

CREATE TABLE IF NOT EXISTS public.dte_transicao (
    entidade text NOT NULL,
    estado_origem text NOT NULL,
    estado_destino text NOT NULL,
    PRIMARY KEY (entidade, estado_origem, estado_destino),
    FOREIGN KEY (entidade, estado_origem) REFERENCES public.dte_estado_valido(entidade, estado),
    FOREIGN KEY (entidade, estado_destino) REFERENCES public.dte_estado_valido(entidade, estado)
);

CREATE TABLE IF NOT EXISTS public.fatura_fluxo (
    invoice_id integer PRIMARY KEY REFERENCES public.invoice(invoice_id),
    status text NOT NULL
);

CREATE OR REPLACE FUNCTION public.validar_transicao_dte()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_entidade text := TG_ARGV[0];
    v_coluna text := TG_ARGV[1];
    v_novo text := to_jsonb(NEW) ->> v_coluna;
    v_antigo text;
    v_inicial boolean;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        v_antigo := to_jsonb(OLD) ->> v_coluna;
        IF v_novo IS NOT DISTINCT FROM v_antigo THEN RETURN NEW; END IF;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.dte_estado_valido
                   WHERE entidade = v_entidade AND estado = v_novo) THEN
        RAISE EXCEPTION 'Estado % inválido para %', v_novo, v_entidade;
    END IF;

    IF TG_OP = 'INSERT' THEN
        SELECT inicial INTO v_inicial FROM public.dte_estado_valido
        WHERE entidade = v_entidade AND estado = v_novo;
        IF NOT COALESCE(v_inicial, false) THEN
            RAISE EXCEPTION 'O estado inicial de % deve ser criado como estado inicial', v_entidade;
        END IF;
    ELSIF NOT EXISTS (SELECT 1 FROM public.dte_transicao
                      WHERE entidade = v_entidade
                        AND estado_origem = v_antigo AND estado_destino = v_novo) THEN
        RAISE EXCEPTION 'Transição não permitida para %: % -> %', v_entidade, v_antigo, v_novo;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_dte_fatura_fluxo ON public.fatura_fluxo;
CREATE TRIGGER trg_dte_fatura_fluxo
BEFORE INSERT OR UPDATE OF status ON public.fatura_fluxo
FOR EACH ROW EXECUTE FUNCTION public.validar_transicao_dte('fatura', 'status');

INSERT INTO public.dte_estado_valido(entidade, estado, inicial) VALUES
    ('fatura', 'aberta', true), ('fatura', 'paga', false), ('fatura', 'cancelada', false)
ON CONFLICT (entidade, estado) DO UPDATE SET inicial = EXCLUDED.inicial;

INSERT INTO public.dte_transicao(entidade, estado_origem, estado_destino) VALUES
    ('fatura', 'aberta', 'paga'), ('fatura', 'aberta', 'cancelada')
ON CONFLICT DO NOTHING;

-- Cenário de teste: use invoice_id disponível. Transição válida e inválida são
-- demonstradas em transação revertida, sem deixar alterações nos dados do Chinook.
BEGIN;
DO $$
DECLARE
    v_invoice_id integer;
    v_customer_id integer;
BEGIN
    SELECT customer_id INTO v_customer_id FROM public.customer ORDER BY customer_id LIMIT 1;
    SELECT COALESCE(max(invoice_id), 0) + 1 INTO v_invoice_id FROM public.invoice;
    INSERT INTO public.invoice(invoice_id, customer_id, invoice_date, total)
    VALUES (v_invoice_id, v_customer_id, current_timestamp, 0);
    INSERT INTO public.fatura_fluxo(invoice_id, status) VALUES (v_invoice_id, 'aberta');
    UPDATE public.fatura_fluxo SET status = 'cancelada' WHERE invoice_id = v_invoice_id;
    BEGIN
        UPDATE public.fatura_fluxo SET status = 'aberta' WHERE invoice_id = v_invoice_id;
        RAISE EXCEPTION 'Falha no teste: transição cancelada -> aberta foi aceita';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'Falha no teste:%' THEN RAISE; END IF;
        RAISE NOTICE 'Teste aprovado: transição cancelada -> aberta rejeitada';
    END;
END $$;
ROLLBACK;
