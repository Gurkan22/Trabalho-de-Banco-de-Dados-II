-- Parte 2, questão 4
-- Mantém invoice.total por alterações em invoice_line usando incrementos
-- atômicos na linha da fatura, inclusive quando uma linha muda de fatura.

CREATE OR REPLACE FUNCTION public.atualizar_total_fatura_por_item()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_delta numeric(12,2);
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_delta := round(NEW.unit_price * NEW.quantity, 2);
        UPDATE public.invoice SET total = total + v_delta WHERE invoice_id = NEW.invoice_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        v_delta := round(OLD.unit_price * OLD.quantity, 2);
        UPDATE public.invoice SET total = total - v_delta WHERE invoice_id = OLD.invoice_id;
        RETURN OLD;
    ELSE
        v_delta := round(OLD.unit_price * OLD.quantity, 2);
        UPDATE public.invoice SET total = total - v_delta WHERE invoice_id = OLD.invoice_id;
        v_delta := round(NEW.unit_price * NEW.quantity, 2);
        UPDATE public.invoice SET total = total + v_delta WHERE invoice_id = NEW.invoice_id;
        RETURN NEW;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.proteger_total_fatura()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.total <> 0 THEN
            RAISE EXCEPTION 'Crie a fatura com total zero e inclua os itens em seguida';
        END IF;
    ELSIF pg_trigger_depth() <= 1 THEN
        RAISE EXCEPTION 'invoice.total é mantido pelos itens da fatura';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_proteger_total_fatura_insert ON public.invoice;
DROP TRIGGER IF EXISTS trg_proteger_total_fatura_update ON public.invoice;

DROP TRIGGER IF EXISTS trg_invoice_line_total_insert ON public.invoice_line;
DROP TRIGGER IF EXISTS trg_invoice_line_total_update ON public.invoice_line;
DROP TRIGGER IF EXISTS trg_invoice_line_total_delete ON public.invoice_line;

CREATE TRIGGER trg_invoice_line_total_insert
AFTER INSERT ON public.invoice_line
FOR EACH ROW EXECUTE FUNCTION public.atualizar_total_fatura_por_item();

CREATE TRIGGER trg_invoice_line_total_update
AFTER UPDATE OF invoice_id, unit_price, quantity ON public.invoice_line
FOR EACH ROW EXECUTE FUNCTION public.atualizar_total_fatura_por_item();

CREATE TRIGGER trg_invoice_line_total_delete
AFTER DELETE ON public.invoice_line
FOR EACH ROW EXECUTE FUNCTION public.atualizar_total_fatura_por_item();

-- Corrige eventuais totais preexistentes antes de ativar o trabalho sobre os dados.
UPDATE public.invoice AS i
SET total = COALESCE((
    SELECT round(sum(il.unit_price * il.quantity), 2)
    FROM public.invoice_line AS il
    WHERE il.invoice_id = i.invoice_id
), 0);

CREATE TRIGGER trg_proteger_total_fatura_insert
BEFORE INSERT ON public.invoice
FOR EACH ROW EXECUTE FUNCTION public.proteger_total_fatura();

CREATE TRIGGER trg_proteger_total_fatura_update
BEFORE UPDATE OF total ON public.invoice
FOR EACH ROW EXECUTE FUNCTION public.proteger_total_fatura();
