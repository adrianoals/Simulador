CREATE OR REPLACE FUNCTION criar_simulacao_unificada(
    p_nome_cliente VARCHAR,
    p_email_cliente VARCHAR,
    p_telefone_cliente VARCHAR,
    p_nome_vendedor VARCHAR,
    p_email_vendedor VARCHAR,
    p_telefone_vendedor VARCHAR,
    p_bem_id INTEGER,
    p_plano_id INTEGER,
    p_valor_credito NUMERIC(10, 2),
    p_prazo INTEGER,
    p_vencimento_proposta DATE,
    p_lance_recurso_proprio NUMERIC(10, 2) DEFAULT 0,
    p_lance_terceiro NUMERIC(10, 2) DEFAULT 0,
    p_lance_embutido NUMERIC(10, 2) DEFAULT 0,
    p_mes_contemplacao INTEGER DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    -- IDs e parâmetros principais
    v_cliente_id INTEGER;
    v_vendedor_id INTEGER;
    v_simulacao_id INTEGER;
    v_taxa_id INTEGER;
    v_taxa_administracao NUMERIC(6, 5);
    v_fundo_reserva NUMERIC(6, 5);
    v_seguro_vida_parcela NUMERIC(6, 5);
    v_taxa_antecipacao NUMERIC(6, 5);
    v_descricao_plano VARCHAR;

    -- Variáveis de cálculo
    v_valor_credito_entregue NUMERIC(10, 2);
    v_total_lance NUMERIC(10, 2);
    v_percentual_lance NUMERIC(5, 2);
    v_parcela_com_seguro NUMERIC(10, 2);
    v_parcela_sem_seguro NUMERIC(10, 2);
    v_primeira_parcela_com_seguro NUMERIC(10, 2);
    v_primeira_parcela_sem_seguro NUMERIC(10, 2);
    v_valor_abatido_parcela NUMERIC(10, 2);
    v_parcela_atualizada_com_seguro NUMERIC(10, 2);
    v_parcela_atualizada_sem_seguro NUMERIC(10, 2);
    v_n_parcelas_abatidas_com_seguro INTEGER;
    v_n_parcelas_abatidas_sem_seguro INTEGER;
    v_prazo_atualizado_com_abatimento_com_seguro INTEGER;
    v_prazo_atualizado_com_abatimento_sem_seguro INTEGER;
    v_valor_seguro_mensal NUMERIC(10, 2);
    v_valor_seguro_total NUMERIC(10, 2);
    v_custo_efetivo_total NUMERIC(10, 2);
    v_taxa_efetivo_mensal NUMERIC(5, 2);
    v_constante NUMERIC(10, 2); -- Usado para planos reduzidos
    v_percentual_reducao NUMERIC(5, 2); -- Percentual de redução para planos reduzidos
BEGIN
    -- Inserir cliente
    INSERT INTO cliente (nome, email, telefone)
    VALUES (p_nome_cliente, p_email_cliente, p_telefone_cliente)
    RETURNING id INTO v_cliente_id;

    -- Inserir vendedor
    INSERT INTO vendedor (nome, email, telefone)
    VALUES (p_nome_vendedor, p_email_vendedor, p_telefone_vendedor)
    RETURNING id INTO v_vendedor_id;

    -- Obter detalhes do bem, plano e taxa
    SELECT
        b.fundo_reserva,
        b.seguro_vida_parcela,
        t.id,
        t.taxa_antecipacao,
        t.taxa_administracao,
        p.descricao
    INTO
        v_fundo_reserva,
        v_seguro_vida_parcela,
        v_taxa_id,
        v_taxa_antecipacao,
        v_taxa_administracao,
        v_descricao_plano
    FROM
        bem b
        JOIN plano p ON p.id = p_plano_id AND p.bem_id = b.id
        JOIN taxa t ON t.plano_id = p.id AND t.bem_id = b.id
    WHERE
        b.id = p_bem_id AND t.prazo = p_prazo
    LIMIT 1;

    -- Inserir simulação
    INSERT INTO simulacao (
        data_hora,
        cliente_id,
        vendedor_id,
        bem_id,
        plano_id,
        taxa_id,
        valor_credito,
        lance_recurso_proprio,
        lance_terceiro,
        lance_embutido,
        mes_contemplacao,
        vencimento_proposta
    )
    VALUES (
        CURRENT_TIMESTAMP,
        v_cliente_id,
        v_vendedor_id,
        p_bem_id,
        p_plano_id,
        v_taxa_id,
        p_valor_credito,
        p_lance_recurso_proprio,
        p_lance_terceiro,
        p_lance_embutido,
        p_mes_contemplacao,
        p_vencimento_proposta
    )
    RETURNING id INTO v_simulacao_id;

    -- Calcular valores comuns
    v_valor_credito_entregue := calc_credito_entregue(p_valor_credito, p_lance_terceiro, p_lance_embutido);
    v_total_lance := calc_total_lance(p_lance_recurso_proprio, p_lance_terceiro, p_lance_embutido);
    v_percentual_lance := calc_percentual_lance(v_total_lance, p_valor_credito);

    -- Determinar tipo de plano e cálculos correspondentes
    IF POSITION('%' IN v_descricao_plano) > 0 THEN
        -- Plano Reduzido
        v_percentual_reducao := CASE 
                                    WHEN POSITION('25%' IN v_descricao_plano) > 0 THEN 0.25
                                    WHEN POSITION('50%' IN v_descricao_plano) > 0 THEN 0.50
                                    ELSE 0.30 -- Default para outros percentuais reduzidos
                                END;
        v_constante := calc_constante(p_valor_credito, v_taxa_administracao, v_fundo_reserva, v_taxa_antecipacao, v_percentual_reducao);
        v_parcela_com_seguro := calc_parcela_reduzida_com_seguro(v_constante, p_prazo, v_valor_seguro_mensal);
        v_parcela_sem_seguro := calc_parcela_reduzida_sem_seguro(v_constante, p_prazo);

    ELSIF v_descricao_plano = 'Alpha' AND p_bem_id = 1 THEN
        -- Plano Alpha para imóveis
        v_parcela_com_seguro := calc_parcela_com_seguro_alpha(p_valor_credito, v_taxa_administracao, v_fundo_reserva, v_seguro_vida_parcela, v_taxa_antecipacao, p_prazo);
        v_parcela_sem_seguro := calc_parcela_sem_seguro_alpha(p_valor_credito, v_taxa_administracao, v_fundo_reserva, v_taxa_antecipacao, p_prazo);

    ELSE
        -- Plano Normal
        v_parcela_com_seguro := calc_parcela_com_seguro(p_valor_credito, v_taxa_administracao, v_fundo_reserva, v_seguro_vida_parcela, v_taxa_antecipacao, p_prazo);
        v_parcela_sem_seguro := calc_parcela_sem_seguro(p_valor_credito, v_taxa_administracao, v_fundo_reserva, 0, v_taxa_antecipacao, p_prazo);
    END IF;

    -- Calcular valores adicionais
    v_primeira_parcela_com_seguro := calc_parcela_antecipacao_com_seguro(v_taxa_antecipacao, p_valor_credito, v_parcela_com_seguro);
    v_primeira_parcela_sem_seguro := calc_parcela_antecipacao_sem_seguro(v_taxa_antecipacao, p_valor_credito, v_parcela_sem_seguro);

    -- Inserir resultados
    INSERT INTO resultado (
        simulacao_id,
        credito_entregue,
        total_lance,
        percentual_lance,
        parcela_com_seguro,
        parcela_sem_seguro,
        primeira_parcela_antecipacao_com_seguro,
        primeira_parcela_antecipacao_sem_seguro
    )
    VALUES (
        v_simulacao_id,
        v_valor_credito_entregue,
        v_total_lance,
        v_percentual_lance,
        v_parcela_com_seguro,
        v_parcela_sem_seguro,
        v_primeira_parcela_com_seguro,
        v_primeira_parcela_sem_seguro
    );

    -- Retornar JSON
    RETURN json_build_object(
        'simulacao_id', v_simulacao_id,
        'parcela_com_seguro', v_parcela_com_seguro,
        'parcela_sem_seguro', v_parcela_sem_seguro
    );
END;
$$ LANGUAGE plpgsql;
