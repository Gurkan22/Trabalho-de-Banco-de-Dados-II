-- Execute depois dos scripts 01, 02 e 03 da Parte 2 e da Parte1/05_dte_fatura.sql.
-- Os testes rodam em transação revertida e não deixam linhas de exemplo.

BEGIN;
DO $$
DECLARE
    v_invoice_id integer;
    v_track_id integer;
    v_customer_id integer;
    v_empty_invoice_id integer;
    v_total_antes numeric(10,2);
    v_total_depois numeric(10,2);
BEGIN
    SELECT invoice_id INTO v_invoice_id FROM public.invoice ORDER BY invoice_id LIMIT 1;
    SELECT track_id INTO v_track_id FROM public.track ORDER BY track_id LIMIT 1;
    SELECT total INTO v_total_antes FROM public.invoice WHERE invoice_id = v_invoice_id;

    CALL public.registrar_item_fatura(v_invoice_id, v_track_id, 1.25, 2);
    SELECT total INTO v_total_depois FROM public.invoice WHERE invoice_id = v_invoice_id;
    IF v_total_depois <> v_total_antes + 2.50 THEN
        RAISE EXCEPTION 'Falha: total da fatura não foi atualizado';
    END IF;
    RAISE NOTICE 'Teste aprovado: inclusão atualizou o total para %', v_total_depois;

    BEGIN
        CALL public.registrar_item_fatura(v_invoice_id, v_track_id, 1.25, 0);
        RAISE EXCEPTION 'Falha no teste: quantidade zero foi aceita';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'Falha no teste:%' THEN RAISE; END IF;
        RAISE NOTICE 'Teste aprovado: quantidade zero rejeitada';
    END;

    BEGIN
        UPDATE public.invoice SET total = total + 1 WHERE invoice_id = v_invoice_id;
        RAISE EXCEPTION 'Falha no teste: alteração direta de total foi aceita';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'Falha no teste:%' THEN RAISE; END IF;
        RAISE NOTICE 'Teste aprovado: alteração direta de total rejeitada';
    END;

    SELECT customer_id INTO v_customer_id FROM public.customer ORDER BY customer_id LIMIT 1;
    SELECT COALESCE(max(invoice_id), 0) + 1 INTO v_empty_invoice_id FROM public.invoice;
    INSERT INTO public.invoice(invoice_id, customer_id, invoice_date, total)
    VALUES (v_empty_invoice_id, v_customer_id, current_timestamp, 0);
    INSERT INTO public.fatura_fluxo(invoice_id, status) VALUES (v_empty_invoice_id, 'aberta');
    BEGIN
        UPDATE public.fatura_fluxo SET status = 'paga' WHERE invoice_id = v_empty_invoice_id;
        RAISE EXCEPTION 'Falha no teste: fatura sem itens foi marcada como paga';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'Falha no teste:%' THEN RAISE; END IF;
        RAISE NOTICE 'Teste aprovado: pagamento de fatura sem itens rejeitado';
    END;
END $$;
ROLLBACK;

-- Para validar privilégios, conecte como operador_faturas e execute:
-- CALL public.registrar_item_fatura(<invoice_id>, <track_id>, 1.25, 1);
-- INSERT INTO public.invoice_line (...) VALUES (...); -- esperado: permission denied
