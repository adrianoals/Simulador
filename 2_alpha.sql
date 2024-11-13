CREATE TABLE resultado_alpha (
    id SERIAL PRIMARY KEY,
    simulacao_id INTEGER NOT NULL REFERENCES simulacao(id) ON DELETE CASCADE,
    
    -- Crédito Entregue
    credito_entregue NUMERIC(10, 2) NOT NULL DEFAULT 0,

    -- Lance
    total_lance NUMERIC(10, 2) NOT NULL DEFAULT 0,
    percentual_lance NUMERIC(5, 2) NOT NULL DEFAULT 0,

    -- Com Seguro
    parcela_com_seguro NUMERIC(10, 2) NOT NULL DEFAULT 0,
    primeira_parcela_antecipacao_com_seguro NUMERIC(10, 2) NOT NULL DEFAULT 0,

    -- Sem Seguro
    parcela_sem_seguro NUMERIC(10, 2) NOT NULL DEFAULT 0,
    primeira_parcela_antecipacao_sem_seguro NUMERIC(10, 2) NOT NULL DEFAULT 0,

    -- Opcao 1
    prazo_atualizado INTEGER NOT NULL DEFAULT 0,
    valor_abatido_parcela NUMERIC(10, 2) NOT NULL DEFAULT 0,
    parcela_atualizada_com_seguro NUMERIC(10, 2) NOT NULL DEFAULT 0,
    parcela_atualizada_sem_seguro NUMERIC(10, 2) NOT NULL DEFAULT 0,

    -- Opcao 2
    n_parcelas_abatidas_com_seguro INTEGER NOT NULL DEFAULT 0,
    n_parcelas_abatidas_sem_seguro INTEGER NOT NULL DEFAULT 0,
    prazo_atualizado_com_abatimento_com_seguro INTEGER NOT NULL DEFAULT 0,
    prazo_atualizado_com_abatimento_sem_seguro INTEGER NOT NULL DEFAULT 0,

    -- Taxas
    custo_efetivo_total NUMERIC(10, 2) NOT NULL DEFAULT 0,
    taxa_efetivo_mensal NUMERIC(5, 2) NOT NULL DEFAULT 0,
    valor_seguro_mensal NUMERIC(10, 2) NOT NULL DEFAULT 0,
    valor_seguro_total NUMERIC(10, 2) NOT NULL DEFAULT 0,
    
    -- Novo Campo
    valor_antecipacao NUMERIC(10, 2) NOT NULL DEFAULT 0
);