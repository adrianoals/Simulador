CREATE OR REPLACE FUNCTION calc_constante(
    valor_credito NUMERIC(10, 2),
    taxa_administracao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5),
    taxa_antecipacao NUMERIC(6, 5),
    percentual_reducao NUMERIC(5, 2) -- Percentual de redução (ex: 0.25 para 25%)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN ((valor_credito * (1 + taxa_administracao + fundo_reserva)) * (1 - percentual_reducao)) - (valor_credito * taxa_antecipacao);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_parcela_reduzida_com_seguro(
    constante NUMERIC,
    prazo INTEGER,
    valor_seguro_mensal NUMERIC
) RETURNS NUMERIC AS $$
BEGIN
    RETURN (constante / prazo) + valor_seguro_mensal;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_parcela_reduzida_sem_seguro(
    constante NUMERIC,
    prazo INTEGER
) RETURNS NUMERIC AS $$
BEGIN
    RETURN constante / prazo;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_parcela_normal_com_seguro(
    mes_contemplacao INTEGER,
    parcela_reduzida_sem_seguro NUMERIC(10, 2),
    valor_credito NUMERIC(10, 2),
    fundo_reserva NUMERIC(6, 5),
    taxa_administracao NUMERIC(6, 5),
    seguro_vida_parcela NUMERIC(6, 5),
    taxa_antecipacao NUMERIC(6, 5),
    prazo INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    prazo_restante INTEGER;
    credito_taxas NUMERIC(10, 2);
    parcelas_pagas NUMERIC(10, 2);
    valor_seguro_mensal NUMERIC(10, 2);
BEGIN
    prazo_restante := prazo - mes_contemplacao;
    credito_taxas := valor_credito * (1 + fundo_reserva + taxa_administracao);
    parcelas_pagas := (mes_contemplacao * parcela_reduzida_sem_seguro) + (valor_credito * taxa_antecipacao);
    valor_seguro_mensal := (valor_credito * (1 + fundo_reserva + taxa_administracao)) * seguro_vida_parcela;
    RETURN ((credito_taxas - parcelas_pagas) / prazo_restante) + valor_seguro_mensal;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_parcela_normal_sem_seguro(
    mes_contemplacao INTEGER,
    parcela_reduzida_sem_seguro NUMERIC(10, 2),
    valor_credito NUMERIC(10, 2),
    fundo_reserva NUMERIC(6, 5),
    taxa_administracao NUMERIC(6, 5),
    taxa_antecipacao NUMERIC(6, 5),
    prazo INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    prazo_restante INTEGER;
    credito_taxas NUMERIC(10, 2);
    parcelas_pagas NUMERIC(10, 2);
BEGIN
    prazo_restante := prazo - mes_contemplacao;
    credito_taxas := valor_credito * (1 + fundo_reserva + taxa_administracao);
    parcelas_pagas := (mes_contemplacao * parcela_reduzida_sem_seguro) + (valor_credito * taxa_antecipacao);
    RETURN (credito_taxas - parcelas_pagas) / prazo_restante;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_parcela_antecipacao_com_seguro(
    taxa_antecipacao NUMERIC(6, 5),
    valor_credito NUMERIC(10, 2),
    parcela_reduzida_com_seguro NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN (taxa_antecipacao * valor_credito) + parcela_reduzida_com_seguro;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_parcela_antecipacao_sem_seguro(
    taxa_antecipacao NUMERIC(6, 5),
    valor_credito NUMERIC(10, 2),
    parcela_reduzida_sem_seguro NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN (taxa_antecipacao * valor_credito) + parcela_reduzida_sem_seguro;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_parcela_atualizada_com_seguro(
    parcela_normal_com_seguro NUMERIC(10, 2),
    valor_abatido_parcela NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN parcela_normal_com_seguro - valor_abatido_parcela;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_parcela_atualizada_sem_seguro(
    parcela_normal_sem_seguro NUMERIC(10, 2),
    valor_abatido_parcela NUMERIC(10, 2)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN parcela_normal_sem_seguro - valor_abatido_parcela;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_n_parcelas_abatidas_com_seguro(
    total_lance NUMERIC(10, 2),
    parcela_normal_com_seguro NUMERIC(10, 2)
) RETURNS INTEGER AS $$
BEGIN
    RETURN total_lance / parcela_normal_com_seguro;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_n_parcelas_abatidas_sem_seguro(
    total_lance NUMERIC(10, 2),
    parcela_normal_sem_seguro NUMERIC(10, 2)
) RETURNS INTEGER AS $$
BEGIN
    RETURN total_lance / parcela_normal_sem_seguro;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_prazo_atualizado_com_abatimento_com_seguro(
    prazo INTEGER,
    mes_contemplacao INTEGER,
    n_parcelas_abatidas_com_seguro INTEGER
) RETURNS INTEGER AS $$
BEGIN
    RETURN prazo - COALESCE(mes_contemplacao, 0) - n_parcelas_abatidas_com_seguro;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calc_prazo_atualizado_com_abatimento_sem_seguro(
    prazo INTEGER,
    mes_contemplacao INTEGER,
    n_parcelas_abatidas_sem_seguro INTEGER
) RETURNS INTEGER AS $$
BEGIN
    RETURN prazo - COALESCE(mes_contemplacao, 0) - n_parcelas_abatidas_sem_seguro;
END;
$$ LANGUAGE plpgsql;
