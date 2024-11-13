CREATE TABLE public.vendedor (
    vendedor_id SERIAL PRIMARY KEY,
    vendedor_uuid UUID UNIQUE NOT NULL REFERENCES auth.users(id),  -- Chave estrangeira que referencia auth.users.id
    nome_vendedor VARCHAR(100) NOT NULL,
    email_vendedor VARCHAR(255) NOT NULL,
    telefone_vendedor VARCHAR(15) NOT NULL,
    role VARCHAR(20) DEFAULT 'vendedor' CHECK (role IN ('vendedor', 'admin')),
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP  -- Data de criação do registro
);



CREATE TABLE public.cliente (
    cliente_id SERIAL PRIMARY KEY,
    nome_cliente VARCHAR(100) NOT NULL,
    email_cliente VARCHAR(255) NOT NULL,
    telefone_cliente VARCHAR(15) NOT NULL,
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.bem (
    bem_id SERIAL PRIMARY KEY,
    descricao_bem VARCHAR(100) NOT NULL,
    fundo_reserva NUMERIC(6, 5) NOT NULL,
    seguro_vida_parcela NUMERIC(6, 5) NOT NULL
);

CREATE TABLE public.plano (
    plano_id SERIAL PRIMARY KEY,
    descricao_plano VARCHAR(100) NOT NULL,
    bem_id INTEGER NOT NULL REFERENCES public.bem(bem_id) ON DELETE CASCADE
);

CREATE TABLE public.taxa (
    taxa_id SERIAL PRIMARY KEY,
    plano_id INTEGER NOT NULL REFERENCES public.plano(plano_id) ON DELETE CASCADE,
    bem_id INTEGER NOT NULL REFERENCES public.bem(bem_id) ON DELETE CASCADE,
    prazo INTEGER NOT NULL,
    taxa_antecipacao NUMERIC(6, 5) NOT NULL,
    taxa_administracao NUMERIC(6, 5) NOT NULL
);

CREATE TABLE public.simulacao (
    simulacao_id SERIAL PRIMARY KEY,
    data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cliente_id INTEGER NOT NULL REFERENCES public.cliente(cliente_id) ON DELETE CASCADE,
    vendedor_id INTEGER NOT NULL REFERENCES public.vendedor(vendedor_id) ON DELETE CASCADE,
    bem_id INTEGER NOT NULL REFERENCES public.bem(bem_id) ON DELETE CASCADE,
    plano_id INTEGER NOT NULL REFERENCES public.plano(plano_id) ON DELETE CASCADE,
    taxa_id INTEGER NOT NULL REFERENCES public.taxa(taxa_id),
    valor_credito NUMERIC(10, 2) NOT NULL,
    lance_recurso_proprio NUMERIC(10, 2),
    lance_terceiro NUMERIC(10, 2),
    lance_embutido NUMERIC(10, 2),
    mes_contemplacao INTEGER,
    vencimento_proposta DATE NOT NULL
);

CREATE TABLE public.resultado (
    resultado_id SERIAL PRIMARY KEY,
    simulacao_id INTEGER NOT NULL REFERENCES public.simulacao(simulacao_id) ON DELETE CASCADE,
    -- Crédito Entregue
    credito_entregue NUMERIC(10, 2) NOT NULL DEFAULT 0,

    -- Lance
    total_lance NUMERIC(10, 2) NOT NULL DEFAULT 0,
    percentual_lance NUMERIC(5, 2) NOT NULL DEFAULT 0,

    -- Com Seguro
    parcela_reduzida_com_seguro NUMERIC(10, 2) DEFAULT NULL,
    parcela_normal_com_seguro NUMERIC(10, 2) DEFAULT NULL,
    primeira_parcela_antecipacao_com_seguro NUMERIC(10, 2) DEFAULT NULL,

    -- Sem Seguro
    parcela_reduzida_sem_seguro NUMERIC(10, 2) DEFAULT NULL,
    parcela_normal_sem_seguro NUMERIC(10, 2) DEFAULT NULL,
    primeira_parcela_antecipacao_sem_seguro NUMERIC(10, 2) DEFAULT NULL,

    -- Opcao 1
    prazo_atualizado INTEGER DEFAULT NULL,
    valor_abatido_parcela NUMERIC(10, 2) DEFAULT NULL,
    parcela_atualizada_com_seguro NUMERIC(10, 2) DEFAULT NULL,
    parcela_atualizada_sem_seguro NUMERIC(10, 2) DEFAULT NULL,

    -- Opcao 2
    n_parcelas_abatidas_com_seguro INTEGER DEFAULT NULL,
    n_parcelas_abatidas_sem_seguro INTEGER DEFAULT NULL,
    prazo_atualizado_com_abatimento_com_seguro INTEGER DEFAULT NULL,
    prazo_atualizado_com_abatimento_sem_seguro INTEGER DEFAULT NULL,

    -- Taxas
    custo_efetivo_total NUMERIC(10, 2) DEFAULT NULL,
    taxa_efetivo_mensal NUMERIC(5, 2) DEFAULT NULL,
    valor_seguro_mensal NUMERIC(10, 2) DEFAULT NULL,
    valor_seguro_total NUMERIC(10, 2) DEFAULT NULL
);
