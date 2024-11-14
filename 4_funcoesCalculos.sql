-- 1
CREATE OR REPLACE FUNCTION calc_parcela_com_seguro(
    valor_credito NUMERIC(10, 2),
    taxa_administracao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5),
    seguro_vida_parcela NUMERIC(6, 5),
    taxa_antecipacao NUMERIC(6, 5),
    prazo INTEGER,
    percentual_reducao NUMERIC(5, 2) DEFAULT NULL -- Para planos reduzidos
) RETURNS NUMERIC AS $$
DECLARE
    constante NUMERIC(10, 2);
BEGIN
    IF percentual_reducao IS NOT NULL THEN
        -- Plano Reduzido
        constante := valor_credito * (taxa_administracao + fundo_reserva) * percentual_reducao;
        RETURN (constante / prazo) + (constante * seguro_vida_parcela);
    ELSE
        -- Plano Normal
        RETURN ((valor_credito * (taxa_administracao + fundo_reserva) + valor_credito) * seguro_vida_parcela +
                (valor_credito * (taxa_administracao + fundo_reserva - taxa_antecipacao) + valor_credito) / prazo);
    END IF;
END;
$$ LANGUAGE plpgsql;


-- 2
CREATE OR REPLACE FUNCTION calc_parcela_sem_seguro(
    valor_credito NUMERIC(10, 2),
    taxa_administracao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5),
    taxa_antecipacao NUMERIC(6, 5),
    prazo INTEGER,
    percentual_reducao NUMERIC(5, 2) DEFAULT NULL -- Para planos reduzidos
) RETURNS NUMERIC AS $$
DECLARE
    constante NUMERIC(10, 2);
BEGIN
    IF percentual_reducao IS NOT NULL THEN
        -- Plano Reduzido
        constante := valor_credito * (taxa_administracao + fundo_reserva) * percentual_reducao;
        RETURN constante / prazo;
    ELSE
        -- Plano Normal
        RETURN (valor_credito * (taxa_administracao + fundo_reserva - taxa_antecipacao) + valor_credito) / prazo;
    END IF;
END;
$$ LANGUAGE plpgsql;


--3
CREATE OR REPLACE FUNCTION calc_primeira_parcela_antecipacao_com_seguro(
    taxa_antecipacao NUMERIC(6, 5),
    valor_credito NUMERIC(10, 2),
    parcela_com_seguro NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN (taxa_antecipacao * valor_credito) + parcela_com_seguro;
END;
$$ LANGUAGE plpgsql;

--4
CREATE OR REPLACE FUNCTION calc_primeira_parcela_antecipacao_sem_seguro(
    taxa_antecipacao NUMERIC(6, 5),
    valor_credito NUMERIC(10, 2),
    parcela_sem_seguro NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN (taxa_antecipacao * valor_credito) + parcela_sem_seguro;
END;
$$ LANGUAGE plpgsql;

--5
CREATE OR REPLACE FUNCTION calc_total_lance(
    lance_recurso_proprio NUMERIC(10, 2),
    lance_terceiro NUMERIC(10, 2),
    lance_embutido NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN lance_recurso_proprio + lance_terceiro + lance_embutido;
END;
$$ LANGUAGE plpgsql;

--6
CREATE OR REPLACE FUNCTION calc_percentual_lance(
    total_lance NUMERIC(10, 2),
    valor_credito NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN (total_lance / valor_credito) * 100;
END;
$$ LANGUAGE plpgsql;

--7 
CREATE OR REPLACE FUNCTION calc_credito_entregue(
    valor_credito NUMERIC(10, 2),
    lance_terceiro NUMERIC(10, 2),
    lance_embutido NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN valor_credito - lance_terceiro - lance_embutido;
END;
$$ LANGUAGE plpgsql;

--8
CREATE OR REPLACE FUNCTION calc_prazo_atualizado(
    prazo INTEGER,
    mes_contemplacao INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
BEGIN
    RETURN prazo - COALESCE(mes_contemplacao, 0);
END;
$$ LANGUAGE plpgsql;

--9 
CREATE OR REPLACE FUNCTION calc_valor_abatido_parcela(
    total_lance NUMERIC(10, 2),
    prazo_atualizado INTEGER
) RETURNS NUMERIC AS $$
BEGIN
    RETURN total_lance / prazo_atualizado;
END;
$$ LANGUAGE plpgsql;

--10
CREATE OR REPLACE FUNCTION calc_parcela_atualizada_com_seguro(
    parcela_com_seguro NUMERIC(10, 2),
    valor_abatido_parcela NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN parcela_com_seguro - valor_abatido_parcela;
END;
$$ LANGUAGE plpgsql;

--11
CREATE OR REPLACE FUNCTION calc_parcela_atualizada_sem_seguro(
    parcela_sem_seguro NUMERIC(10, 2),
    valor_abatido_parcela NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN parcela_sem_seguro - valor_abatido_parcela;
END;
$$ LANGUAGE plpgsql;

--12
CREATE OR REPLACE FUNCTION calc_n_parcelas_abatidas_com_seguro(
    total_lance NUMERIC(10, 2),
    parcela_com_seguro NUMERIC(10, 2)
) RETURNS INTEGER AS $$
BEGIN
    RETURN total_lance / parcela_com_seguro;
END;
$$ LANGUAGE plpgsql;

--13
CREATE OR REPLACE FUNCTION calc_n_parcelas_abatidas_sem_seguro(
    total_lance NUMERIC(10, 2),
    parcela_sem_seguro NUMERIC(10, 2)
) RETURNS INTEGER AS $$
BEGIN
    RETURN total_lance / parcela_sem_seguro;
END;
$$ LANGUAGE plpgsql;

--14
CREATE OR REPLACE FUNCTION calc_prazo_atualizado_com_abatimento_com_seguro(
    prazo INTEGER,
    mes_contemplacao INTEGER,
    n_parcelas_abatidas_com_seguro INTEGER
) RETURNS INTEGER AS $$
BEGIN
    RETURN prazo - COALESCE(mes_contemplacao, 0) - n_parcelas_abatidas_com_seguro;
END;
$$ LANGUAGE plpgsql;

--15
CREATE OR REPLACE FUNCTION calc_prazo_atualizado_com_abatimento_sem_seguro(
    prazo INTEGER,
    mes_contemplacao INTEGER,
    n_parcelas_abatidas_sem_seguro INTEGER
) RETURNS INTEGER AS $$
BEGIN
    RETURN prazo - COALESCE(mes_contemplacao, 0) - n_parcelas_abatidas_sem_seguro;
END;
$$ LANGUAGE plpgsql;

--16
CREATE OR REPLACE FUNCTION calc_custo_efetivo_total(
    valor_credito NUMERIC(10, 2),
    taxa_administracao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN valor_credito * (1 + (taxa_administracao + fundo_reserva));
END;
$$ LANGUAGE plpgsql;

--17
CREATE OR REPLACE FUNCTION calc_taxa_efetiva_mensal(
    taxa_administracao NUMERIC(6, 5),
    taxa_antecipacao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5),
    prazo INTEGER
) RETURNS NUMERIC AS $$
BEGIN
    RETURN ((taxa_administracao - taxa_antecipacao + fundo_reserva) / prazo) * 100;
END;
$$ LANGUAGE plpgsql;

--18
CREATE OR REPLACE FUNCTION calc_valor_seguro_mensal(
    valor_credito NUMERIC(10, 2),
    taxa_administracao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5),
    seguro_vida_parcela NUMERIC(6, 5)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN (valor_credito * (1 + taxa_administracao + fundo_reserva)) * seguro_vida_parcela;
END;
$$ LANGUAGE plpgsql;

--19
CREATE OR REPLACE FUNCTION calc_valor_seguro_total(
    valor_credito NUMERIC(10, 2),
    taxa_administracao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5),
    seguro_vida_parcela NUMERIC(6, 5),
    prazo INTEGER
) RETURNS NUMERIC AS $$
BEGIN
    RETURN calc_valor_seguro_mensal(valor_credito, taxa_administracao, fundo_reserva, seguro_vida_parcela) * prazo;
END;
$$ LANGUAGE plpgsql;
