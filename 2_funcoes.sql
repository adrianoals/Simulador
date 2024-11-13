/* PARCELA COM SEGURO
parcela_com_seguro = ((valor_credito * (taxa_administracao + fundo_reserva) + valor_credito) * seguro_vida_parcela + (valor_credito * (taxa_administracao + fundo_reserva - taxa_antecipacao) + valor_credito) / prazo)
*/
CREATE OR REPLACE FUNCTION calculo_parcela_com_seguro(
    valor_credito NUMERIC(10, 2),
    taxa_administracao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5),
    seguro_vida_parcela NUMERIC(6, 5),
    taxa_antecipacao NUMERIC(6, 5),
    prazo INTEGER
) RETURNS NUMERIC AS $$
BEGIN
    RETURN ((valor_credito * (taxa_administracao + fundo_reserva) + valor_credito) * seguro_vida_parcela + (valor_credito * (taxa_administracao + fundo_reserva - taxa_antecipacao) + valor_credito) / prazo);
END;
$$ LANGUAGE plpgsql;




/* PRIMEIRA PARCELA ANTECIPAÇÃO COM SEGURO
primeira_parcela_antecipação_com_seguro = (taxa_antecipacao * valor_credito) + valor_parcela_com_seguro
*/
CREATE OR REPLACE FUNCTION calculo_primeira_parcela_antecipacao_com_seguro(
    taxa_antecipacao NUMERIC(6, 5), 
    valor_credito NUMERIC(10, 2), 
    parcela_com_seguro NUMERIC(10, 2)
) RETURNS NUMERIC(10, 2) AS $$
BEGIN
    RETURN (taxa_antecipacao * valor_credito) + parcela_com_seguro;
END;
$$ LANGUAGE plpgsql;




/* VALOR PARCELA SEM SEGURO
valor_parcela_sem_seguro = ((valor_credito * (taxa_administracao + fundo_reserva) + valor_credito) * 0 + (valor_credito * (taxa_administracao + fundo_reserva - taxa_antecipacao) + valor_credito) / prazo)
*/
CREATE OR REPLACE FUNCTION calculo_parcela_sem_seguro(
    valor_credito NUMERIC(10, 2),
    taxa_administracao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5),
    seguro_vida_parcela NUMERIC(6, 5),
    taxa_antecipacao NUMERIC(6, 5),
    prazo INTEGER
) RETURNS NUMERIC AS $$
BEGIN
    RETURN ((valor_credito * (taxa_administracao + fundo_reserva) + valor_credito) * 0 +  (valor_credito * (taxa_administracao + fundo_reserva - taxa_antecipacao) + valor_credito) / prazo);
END;
$$ LANGUAGE plpgsql;




/* VALOR PRIMEIRA PARCELA ANTECIPAÇÃO SEM SEGURO
primeira_parcela_antecipação_sem_seguro = (taxa_antecipacao * valor_credito) + parcela_sem_seguro
*/
CREATE OR REPLACE FUNCTION calculo_primeira_parcela_antecipacao_sem_seguro(
    taxa_antecipacao NUMERIC(6, 5),
    valor_credito NUMERIC(10, 2),
    valor_parcela_sem_seguro NUMERIC(10, 2)
) RETURNS NUMERIC(10, 2) AS $$
BEGIN
    RETURN (taxa_antecipacao * valor_credito) + valor_parcela_sem_seguro;
END;
$$ LANGUAGE plpgsql;




/* TOTAL LANCE
total_lance = lance_recurso_proprio + lance_terceiro + lance_embutido
*/
CREATE OR REPLACE FUNCTION calculo_total_lance(
    lance_recurso_proprio NUMERIC(10, 2), 
    lance_terceiro NUMERIC(10, 2), 
    lance_embutido NUMERIC(10, 2)
) RETURNS NUMERIC(10, 2) AS $$
BEGIN
    RETURN lance_recurso_proprio + lance_terceiro + lance_embutido;
END;
$$ LANGUAGE plpgsql;




/* PERCENTUAL LANCE
percentual_lance = (total_lance / valor_crédito) * 100
*/
CREATE OR REPLACE FUNCTION calculo_percentual_lance(
    total_lance NUMERIC(10, 2), 
    valor_credito NUMERIC(10, 2)
) RETURNS NUMERIC(5, 2) AS $$
BEGIN
    RETURN (total_lance / valor_credito) * 100;
END;
$$ LANGUAGE plpgsql;




/* CRÉDITO ENTREGUE
crédito_entregue = valor_credito - lance_terceiro - lance_embutido
*/
CREATE OR REPLACE FUNCTION calculo_credito_entregue(
    valor_credito NUMERIC(10, 2), 
    lance_terceiro NUMERIC(10, 2), 
    lance_embutido NUMERIC(10, 2)
) RETURNS NUMERIC(10, 2) AS $$
BEGIN
    RETURN valor_credito - lance_terceiro - lance_embutido;
END;
$$ LANGUAGE plpgsql;





/* OPÇÃO 1: Abatimento do lance no valor das parcelas restantes

prazo_atualizado = prazo - COALESCE(mes_contemplacao, 0)
*/
CREATE OR REPLACE FUNCTION calculo_prazo_atualizado(
    prazo INTEGER, 
    mes_contemplacao INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
BEGIN
    RETURN prazo - COALESCE(mes_contemplacao, 0);
END;
$$ LANGUAGE plpgsql;




/* VALOR ABATIDO PARCELA
valor_abatido_parcela = total_lance / prazo_atualizado
*/
CREATE OR REPLACE FUNCTION calculo_valor_abatido_parcela(
    total_lance NUMERIC(10, 2), 
    prazo_atualizado INTEGER
) RETURNS NUMERIC(10, 2) AS $$
BEGIN
    RETURN total_lance / prazo_atualizado;
END;
$$ LANGUAGE plpgsql;




/* PARCELA ATUALIZADA COM SEGURO
parcela_atualizada_com_seguro = valor_parcela_com_seguro - valor_abatido_parcela
*/
CREATE OR REPLACE FUNCTION calculo_parcela_atualizada_com_seguro(
    parcela_com_seguro NUMERIC(10, 2), 
    valor_abatido_parcela NUMERIC(10, 2)
) RETURNS NUMERIC(10, 2) AS $$
BEGIN
    RETURN parcela_com_seguro - valor_abatido_parcela;
END;
$$ LANGUAGE plpgsql;




/* PARCELA ATUALIZADA SEM SEGURO
parcela_atualizada_sem_seguro = valor_parcela_sem_seguro - valor_abatido_parcela
*/
CREATE OR REPLACE FUNCTION calculo_parcela_atualizada_sem_seguro(
    parcela_sem_seguro NUMERIC(10, 2), 
    valor_abatido_parcela NUMERIC(10, 2)
) RETURNS NUMERIC(10, 2) AS $$
BEGIN
    RETURN parcela_sem_seguro - valor_abatido_parcela;
END;
$$ LANGUAGE plpgsql;




/* OPÇÃO 2: Abatimento do lance no prazo restante
NUMERO DE PARCELAS ABATIDAS NO PRAZO (COM SEGURO)
n_parcelas_abatidas_com_seguro = total_lance / parcela_com_seguro
*/
CREATE OR REPLACE FUNCTION calculo_n_parcelas_abatidas_com_seguro(
    total_lance NUMERIC(10, 2), 
    parcela_com_seguro NUMERIC(10, 2)
) RETURNS INTEGER AS $$
BEGIN
    RETURN total_lance / parcela_com_seguro;
END;
$$ LANGUAGE plpgsql;




/* NUMERO DE PARCELAS ABATIDAS NO PRAZO (SEM SEGURO)
n_parcelas_abatidas_sem_seguro = total_lance / parcela_sem_seguro
*/
CREATE OR REPLACE FUNCTION calculo_n_parcelas_abatidas_sem_seguro(
    total_lance NUMERIC(10, 2), 
    parcela_sem_seguro NUMERIC(10, 2)
) RETURNS INTEGER AS $$
BEGIN
    RETURN total_lance / parcela_sem_seguro;
END;
$$ LANGUAGE plpgsql;




/* PRAZO ATUALIZADO COM ABATIMENTO (COM SEGURO)
prazo_atualizado_com_abatimento_com_seguro = prazo - COALESCE(mes_contemplacao, 0) - n_parcelas_abatidas_com_seguro
*/
CREATE OR REPLACE FUNCTION calculo_prazo_atualizado_com_abatimento_com_seguro(
    prazo INTEGER, 
    mes_contemplacao INTEGER, 
    n_parcelas_abatidas_com_seguro INTEGER
) RETURNS INTEGER AS $$
BEGIN
    RETURN prazo - COALESCE(mes_contemplacao, 0) - n_parcelas_abatidas_com_seguro;
END;
$$ LANGUAGE plpgsql;




/* PRAZO ATUALIZADO COM ABATIMENTO (SEM SEGURO)
prazo_atualizado_com_abatimento_sem_seguro = prazo - COALESCE(mes_contemplacao, 0) - n_parcelas_abatidas_sem_seguro
*/
CREATE OR REPLACE FUNCTION calculo_prazo_atualizado_com_abatimento_sem_seguro(
    prazo INTEGER, 
    mes_contemplacao INTEGER, 
    n_parcelas_abatidas_sem_seguro INTEGER
) RETURNS INTEGER AS $$
BEGIN
    RETURN prazo - COALESCE(mes_contemplacao, 0) - n_parcelas_abatidas_sem_seguro;
END;
$$ LANGUAGE plpgsql;




-- TAXAS

-- CUSTO EFETIVO TOTAL
-- custo_efetivo_total = valor_credito * (1 + (taxa_administracao + fundo_reserva))
CREATE OR REPLACE FUNCTION calculo_custo_efetivo_total(
    valor_credito NUMERIC(10, 2), 
    taxa_administracao NUMERIC(6, 5), 
    fundo_reserva NUMERIC(6, 5)
) RETURNS NUMERIC(10, 2) AS $$
BEGIN
    RETURN valor_credito * (1 + (taxa_administracao + fundo_reserva));
END;
$$ LANGUAGE plpgsql;


-- TAXA EFETIVO MENSAL
-- Taxa efetiva mensal = ((taxa adm total - taxa adm antecipada + fundo de reserva) / dividido pelo prazo)*100
CREATE OR REPLACE FUNCTION calculo_taxa_efetivo_mensal(
    taxa_administracao NUMERIC(6, 5), 
    taxa_antecipacao NUMERIC(6, 5), 
    fundo_reserva NUMERIC(6, 5), 
    prazo INTEGER
) RETURNS NUMERIC(5, 2) AS $$
BEGIN
    RETURN ((taxa_administracao - taxa_antecipacao + fundo_reserva) / prazo) * 100;
END;
$$ LANGUAGE plpgsql;



-- seguro_mensal = (valor_credito * (1 + taxa_administracao + fundo_reserva )) * seguro_vida_parcela
CREATE OR REPLACE FUNCTION calculo_valor_seguro_mensal(
    valor_credito NUMERIC(10, 2),
    taxa_administracao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5),
    seguro_vida_parcela NUMERIC(6, 5)
) RETURNS NUMERIC AS $$
BEGIN
    RETURN (valor_credito * (1 + taxa_administracao + fundo_reserva)) * seguro_vida_parcela;
END;
$$ LANGUAGE plpgsql;



/* VALOR SEGURO TOTAL
valor_seguro_total = valor_seguro_mensal * prazo
*/
CREATE OR REPLACE FUNCTION calculo_valor_seguro_total(
    valor_credito NUMERIC(10, 2),
    taxa_administracao NUMERIC(6, 5),
    fundo_reserva NUMERIC(6, 5),
    seguro_vida_parcela NUMERIC(6, 5), 
    prazo INTEGER
) RETURNS NUMERIC(10, 2) AS $$
BEGIN
    RETURN calculo_valor_seguro_mensal(valor_credito, taxa_administracao, fundo_reserva, seguro_vida_parcela) * prazo;
END;
$$ LANGUAGE plpgsql;