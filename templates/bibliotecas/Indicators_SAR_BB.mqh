//+------------------------------------------------------------------+
//| Biblioteca de Indicadores: SAR Parabólico + Bandas de Bollinger |
//| Versão: 1.0                                                      |
//| Data: 01/07/2026                                                 |
//+------------------------------------------------------------------+

#ifndef __INDICATORS_SAR_BB_MQH__
#define __INDICATORS_SAR_BB_MQH__

//+------ ESTRUTURA PARA ARMAZENAR DADOS DOS INDICADORES ------+
struct IndicatorData
{
    double sar_atual;           // Valor atual do SAR
    double sar_anterior;        // Valor anterior do SAR
    double bb_superior;         // Banda de Bollinger Superior
    double bb_media;            // Banda de Bollinger Média (SMA 20)
    double bb_inferior;         // Banda de Bollinger Inferior
    double bb_media_anterior;   // BB Média da candle anterior
    bool bb_media_subindo;      // A banda média está subindo?
    bool bb_media_descendo;     // A banda média está descendo?
    bool sar_subindo;           // SAR está subindo?
    bool sar_descendo;          // SAR está descendo?
    bool sar_inverteu;          // SAR inverteu de direção?
};

//+------ CLASSE DE GERENCIAMENTO DOS INDICADORES ------+
class IndicadoresManager
{
private:
    int handle_bb;              // Handle das Bandas de Bollinger
    int handle_sar;             // Handle do SAR Parabólico
    
    double sar_anterior_armazenado;
    double bb_media_anterior_armazenada;
    
public:
    IndicadoresManager();
    ~IndicadoresManager();
    
    bool Inicializar(string symbol, ENUM_TIMEFRAMES timeframe, 
                    int bb_periodo, double bb_desvio, 
                    double sar_aceleracao_inicio, double sar_aceleracao_max);
    
    bool ObterDados(string symbol, IndicatorData &dados);
    
    bool VerificaSinalCompra(IndicatorData &dados, double percentual_inclinacao);
    bool VerificaSinalVenda(IndicatorData &dados, double percentual_inclinacao);
    
    void Liberar();
};

//+------ CONSTRUTOR ------+
IndicadoresManager::IndicadoresManager()
{
    handle_bb = INVALID_HANDLE;
    handle_sar = INVALID_HANDLE;
    sar_anterior_armazenado = 0;
    bb_media_anterior_armazenada = 0;
}

//+------ DESTRUTOR ------+
IndicadoresManager::~IndicadoresManager()
{
    Liberar();
}

//+------ INICIALIZAR INDICADORES ------+
bool IndicadoresManager::Inicializar(string symbol, ENUM_TIMEFRAMES timeframe,
                                     int bb_periodo, double bb_desvio,
                                     double sar_aceleracao_inicio, double sar_aceleracao_max)
{
    // Criar Bandas de Bollinger
    handle_bb = iBands(symbol, timeframe, bb_periodo, 0, bb_desvio, PRICE_CLOSE);
    if(handle_bb == INVALID_HANDLE)
    {
        Print("[ERRO] Falha ao criar Bandas de Bollinger");
        return false;
    }
    
    // Criar SAR Parabólico
    handle_sar = iSAR(symbol, timeframe, sar_aceleracao_inicio, sar_aceleracao_max);
    if(handle_sar == INVALID_HANDLE)
    {
        Print("[ERRO] Falha ao criar SAR Parabólico");
        return false;
    }
    
    Print("[OK] Indicadores inicializados com sucesso");
    return true;
}

//+------ OBTER DADOS DOS INDICADORES ------+
bool IndicadoresManager::ObterDados(string symbol, IndicatorData &dados)
{
    // Verificar se os handles são válidos
    if(handle_bb == INVALID_HANDLE || handle_sar == INVALID_HANDLE)
    {
        Print("[ERRO] Handles dos indicadores inválidos");
        return false;
    }
    
    // Array para armazenar valores das Bandas
    double bb_upper[];
    double bb_middle[];
    double bb_lower[];
    
    // Copiar valores das Bandas de Bollinger (últimas 2 candles)
    ArraySetAsSeries(bb_upper, true);
    ArraySetAsSeries(bb_middle, true);
    ArraySetAsSeries(bb_lower, true);
    
    if(CopyBuffer(handle_bb, UPPER_BAND, 0, 2, bb_upper) < 2 ||
       CopyBuffer(handle_bb, BASE_LINE, 0, 2, bb_middle) < 2 ||
       CopyBuffer(handle_bb, LOWER_BAND, 0, 2, bb_lower) < 2)
    {
        Print("[ERRO] Falha ao copiar dados das Bandas de Bollinger");
        return false;
    }
    
    // Array para armazenar valores do SAR (últimas 2 candles)
    double sar_buffer[];
    ArraySetAsSeries(sar_buffer, true);
    
    if(CopyBuffer(handle_sar, 0, 0, 2, sar_buffer) < 2)
    {
        Print("[ERRO] Falha ao copiar dados do SAR");
        return false;
    }
    
    // Armazenar SAR anterior
    dados.sar_anterior = sar_anterior_armazenado;
    dados.sar_atual = sar_buffer[0];
    sar_anterior_armazenado = sar_buffer[0];
    
    // Armazenar Bandas de Bollinger
    dados.bb_superior = bb_upper[0];
    dados.bb_media = bb_middle[0];
    dados.bb_inferior = bb_lower[0];
    
    // Verificar se BB média está subindo ou descendo
    dados.bb_media_anterior = bb_media_anterior_armazenada;
    dados.bb_media_subindo = (dados.bb_media > dados.bb_media_anterior);
    dados.bb_media_descendo = (dados.bb_media < dados.bb_media_anterior);
    bb_media_anterior_armazenada = dados.bb_media;
    
    // Verificar se SAR está subindo ou descendo
    // SAR sobe quando está abaixo do preço, desce quando está acima
    double close = Close(symbol, PERIOD_CURRENT, 0);
    dados.sar_subindo = (dados.sar_atual < close);   // SAR abaixo = mercado em alta
    dados.sar_descendo = (dados.sar_atual > close);  // SAR acima = mercado em baixa
    
    // Verificar inversão de SAR
    if(dados.sar_anterior != 0)
    {
        bool sar_estava_subindo = (dados.sar_anterior < close);
        dados.sar_inverteu = (sar_estava_subindo != dados.sar_subindo);
    }
    else
    {
        dados.sar_inverteu = false;
    }
    
    return true;
}

//+------ VERIFICAR SINAL DE COMPRA ------+
bool IndicadoresManager::VerificaSinalCompra(IndicatorData &dados, double percentual_inclinacao)
{
    // Condições para COMPRA:
    // 1. SAR está subindo
    // 2. Banda Média está subindo (com % de inclinação mínima)
    
    if(!dados.sar_subindo)
        return false;
    
    // Verificar inclinação da banda média
    if(!dados.bb_media_subindo)
        return false;
    
    // Verificar % de inclinação da banda média
    // Calcula a mudança percentual da banda
    double mudanca_percentual = 0;
    if(dados.bb_media_anterior > 0)
    {
        mudanca_percentual = ((dados.bb_media - dados.bb_media_anterior) / dados.bb_media_anterior) * 100;
    }
    
    if(mudanca_percentual < percentual_inclinacao)
        return false;
    
    return true;
}

//+------ VERIFICAR SINAL DE VENDA ------+
bool IndicadoresManager::VerificaSinalVenda(IndicatorData &dados, double percentual_inclinacao)
{
    // Condições para VENDA:
    // 1. SAR está descendo
    // 2. Banda Média está descendo (com % de inclinação mínima)
    
    if(!dados.sar_descendo)
        return false;
    
    // Verificar inclinação da banda média
    if(!dados.bb_media_descendo)
        return false;
    
    // Verificar % de inclinação da banda média
    double mudanca_percentual = 0;
    if(dados.bb_media_anterior > 0)
    {
        mudanca_percentual = ((dados.bb_media_anterior - dados.bb_media) / dados.bb_media_anterior) * 100;
    }
    
    if(mudanca_percentual < percentual_inclinacao)
        return false;
    
    return true;
}

//+------ LIBERAR INDICADORES ------+
void IndicadoresManager::Liberar()
{
    if(handle_bb != INVALID_HANDLE)
        IndicatorRelease(handle_bb);
    
    if(handle_sar != INVALID_HANDLE)
        IndicatorRelease(handle_sar);
    
    handle_bb = INVALID_HANDLE;
    handle_sar = INVALID_HANDLE;
}

#endif
