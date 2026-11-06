-- Parte 2, questão 2
-- Regra: uma fatura só pode ser marcada como paga se tiver ao menos uma linha.
-- Requer fatura_fluxo, criada em Scripts/Parte1/05_dte_fatura.sql.

CREATE OR REPLACE FUNCTION public.validar_fatura_com_itens_ao_pagar()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'paga'
       AND NOT EXISTS (
           SELECT 1 FROM public.invoice_line WHERE invoice_id = NEW.invoice_id
       ) THEN
        RAISE EXCEPTION 'A fatura % não pode ser paga sem itens', NEW.invoice_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_fatura_paga_com_itens ON public.fatura_fluxo;
CREATE TRIGGER trg_fatura_paga_com_itens
BEFORE INSERT OR UPDATE OF status ON public.fatura_fluxo
FOR EACH ROW EXECUTE FUNCTION public.validar_fatura_com_itens_ao_pagar();
