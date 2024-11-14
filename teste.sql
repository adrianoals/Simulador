SELECT criar_simulacao_unificada(
    'Cliente Teste',                 -- Nome do cliente
    'cliente@email.com',             -- Email do cliente
    '11999999999',                   -- Telefone do cliente
    'Vendedor Teste',                -- Nome do vendedor
    'vendedor@email.com',            -- Email do vendedor
    '11988888888',                   -- Telefone do vendedor
    1,                               -- ID do bem (existente na tabela `bem`)
    1,                               -- ID do plano (existente na tabela `plano`)
    100000,                          -- Valor do crédito
    60,                              -- Prazo (deve ser válido na tabela `taxa`)
    CURRENT_DATE + 30,               -- Vencimento da proposta
    5000,                            -- Lance recurso próprio
    3000,                            -- Lance terceiro
    2000,                            -- Lance embutido
    10                               -- Mês de contemplação (opcional)
);

