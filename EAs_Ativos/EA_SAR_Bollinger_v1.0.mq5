//+------------------------------------------------------------------+
//| Expert Advisor: SAR Parabólico + Bandas de Bollinger             |
//| Versão: 1.0 - ARQUIVO ÚNICO COMPILÁVEL                          |
//| Data: 01/07/2026                                                  |
//+------------------------------------------------------------------+

#property strict
#property version "1.0"
#property description "EA compilável para MT5 - SAR + Bollinger"
#property icon "🤖"

//═══════════════════════════════════════════════════════════════════════════════════
//                                 ESTRUTURAS
//═══════════════════════════════════════════════════════════════════════════════════

struct IndicatorData
{
    double sar_atual;              // SAR atual
    double sar_anterior;           // SAR anterior
    double bb_superior;            // Banda Superior
    double bb_media;               // Banda Média (SMA)
    double bb_inferior;            // Banda Inferior
    double bb_media_anterior;      // Banda Média anterior
    bool bb_media_subindo;         // BB está subindo?
    bool bb_media_descendo;        // BB está descendo?
    bool sar_subindo;              // SAR está subindo?
    bool sar_descendo;             // SAR está descendo?
    bool sar_inverteu;             // SAR inverteu?
};

//═══════════════════════════════════════════════════════════════════════════════════
//                                 INPUTS
//═══════════════════════════════════════════════════════════════════════════════════

input group "═══════════════════════════════════════════════════════════════"
input group "               CONFIGURAÇÃO GERAL DA EA                      "
input group "═══════════════════════════════════════════════════════════════"

input int    MAGIC_NUMBER = 20260701;
input string EA_VERSAO = "1.0";
input bool   EA_ATIVA = true;
input bool   DASHBOARD_ATIVO = true;
input bool   LOGGING_ATIVO = true;

input group "═══════════════════════════════════════════════════════════════"
input group "              CONFIGURAÇÃO DOS INDICADORES                    "
input group "═══════════════════════════════════════════════════════════════"

input int    BB_PERIODO = 20;
input double BB_DESVIO = 2.0;
input double SAR_ACELERACAO_INICIO = 0.02;
input double SAR_ACELERACAO_MAX = 0.20;
input double PERCENTUAL_INCLINACAO_MIN = 0.1;

input group "═══════════════════════════════════════════════════════════════"
input group "               CONFIGURAÇÃO DE ENTRADA                       "
input group "═══════════════════════════════════════════════════════════════"

enum TipoLote { LOTE_FIXO = 0, RISCO_PERCENTUAL = 1 };

input TipoLote  TIPO_LOTE = LOTE_FIXO;
input double    LOTE_FIXO_VALOR = 1.0;
input double    RISCO_PERCENTUAL_VALOR = 2.0;
input double    CAPITAL_INICIAL = 10000.0;
input int       MAX_OPERACOES_SIMULTANEAS = 1;

input group "═══════════════════════════════════════════════════════════════"
input group "            CONFIGURAÇÃO DE STOP LOSS E GAIN                 "
input group "═══════════════════════════════════════════════════════════════"

enum TipoSaida { FIXO_PONTOS = 0, SAR_REVERSAL = 1 };

input TipoSaida TIPO_SL = SAR_REVERSAL;
input double    SL_FIXO_PONTOS = 50.0;
input int       SAR_REVERSAIS_SL = 3;
input double    GANHO_ALVO_PONTOS = 100.0;
input bool      USAR_TRAILING = true;
input double    TRAILING_START_PONTOS = 50.0;
input double    TRAILING_DISTANCIA = 20.0;

input group "═══════════════════════════════════════════════════════════════"
input group "             CONFIGURAÇÃO DE METAS E HORÁRIOS                "
input group "═══════════════════════════════════════════════════════════════"

input double    META_GANHO_DIARIO = 200.0;
input double    STOP_LOSS_DIARIO = 200.0;
input bool      USAR_HORARIO_OPERACIONAL = true;
input string    HORARIO_INICIO = "09:30";
input string    HORARIO_FIM = "17:00";

//═══════════════════════════════════════════════════════════════════════════════════
//                               VARIÁVEIS GLOBAIS
//═══════════════════════════════════════════════════════════════════════════════════

int handle_bb = INVALID_HANDLE;
int handle_sar = INVALID_HANDLE;

IndicatorData dados_indicadores;
double sar_anterior_armazenado = 0;
double bb_media_anterior_armazenada = 0;

bool ea_ligada = true;
bool bloqueio_operacoes = false;
int operacoes_ganhas = 0;
int operacoes_perdidas = 0;
double resultado_dia = 0.0;
int sar_reversal_contador = 0;
bool tem_posicao_aberta = false;
ulong ticket_posicao_aberta = 0;
double preco_entrada_posicao = 0;
string tipo_posicao_aberta = "";
double preco_max_posicao = 0;
double preco_min_posicao = 0;
string arquivo_log = "";

//═══════════════════════════════════════════════════════════════════════════════════
//                             FUNÇÃO PRINCIPAL: OnInit
//═══════════════════════════════════════════════════════════════════════════════════

int OnInit()
{
    if(!ValidarInputs())
    {
        Alert("[ERRO] Validação de inputs falhou.");
        return INIT_FAILED;
    }
    
    // Criar Bandas de Bollinger
    handle_bb = iBands(Symbol(), Period(), BB_PERIODO, 0, BB_DESVIO, PRICE_CLOSE);
    if(handle_bb == INVALID_HANDLE)
    {
        Alert("[ERRO] Falha ao criar Bandas de Bollinger");
        return INIT_FAILED;
    }
    
    // Criar SAR
    handle_sar = iSAR(Symbol(), Period(), SAR_ACELERACAO_INICIO, SAR_ACELERACAO_MAX);
    if(handle_sar == INVALID_HANDLE)
    {
        Alert("[ERRO] Falha ao criar SAR");
        return INIT_FAILED;
    }
    
    // Inicializar Log
    if(LOGGING_ATIVO)
    {
        string data = TimeToString(TimeCurrent(), TIME_DATE);
        arquivo_log = "EA_SAR_BB_" + Symbol() + "_" + data + ".log";
    }
    
    operacoes_ganhas = 0;
    operacoes_perdidas = 0;
    resultado_dia = 0.0;
    
    Print("════════════════════════════════════════════════════");
    Print("EA SAR Parabólico + Bollinger v" + EA_VERSAO + " - INICIADA");
    Print("Ativo: " + Symbol() + " | TF: " + EnumToString(Period()));
    Print("════════════════════════════════════════════════════");
    
    return INIT_SUCCEEDED;
}

//═══════════════════════════════════════════════════════════════════════════════════
//                             FUNÇÃO PRINCIPAL: OnTick
//═══════════════════════════════════════════════════════════════════════════════════

void OnTick()
{
    if(!EA_ATIVA || !IsConnected())
        return;
    
    if(!DentroDoHorarioOperacional())
        return;
    
    if(!ObterDadosIndicadores())
        return;
    
    if(tem_posicao_aberta)
    {
        GerenciarPosicaoAberta();
    }
    else
    {
        ProcessarSinaisEntrada();
    }
    
    AtualizarDashboard();
}

//═══════════════════════════════════════════════════════════════════════════════════
//                             FUNÇÃO PRINCIPAL: OnDeinit
//═══════════════════════════════════════════════════════════════════════════════════

void OnDeinit(const int reason)
{
    if(handle_bb != INVALID_HANDLE) IndicatorRelease(handle_bb);
    if(handle_sar != INVALID_HANDLE) IndicatorRelease(handle_sar);
    
    for(int i = 0; i < 20; i++)
        ObjectDelete(0, "dash_" + IntegerToString(i));
    
    Print("[INFO] EA finalizada.");
}

//═══════════════════════════════════════════════════════════════════════════════════
//                              FUNÇÕES LÓGICA
//═══════════════════════════════════════════════════════════════════════════════════

bool ObterDadosIndicadores()
{
    if(handle_bb == INVALID_HANDLE || handle_sar == INVALID_HANDLE)
        return false;
    
    double bb_upper[], bb_middle[], bb_lower[], sar_buffer[];
    ArraySetAsSeries(bb_upper, true);
    ArraySetAsSeries(bb_middle, true);
    ArraySetAsSeries(bb_lower, true);
    ArraySetAsSeries(sar_buffer, true);
    
    if(CopyBuffer(handle_bb, UPPER_BAND, 0, 2, bb_upper) < 2)
        return false;
    if(CopyBuffer(handle_bb, BASE_LINE, 0, 2, bb_middle) < 2)
        return false;
    if(CopyBuffer(handle_bb, LOWER_BAND, 0, 2, bb_lower) < 2)
        return false;
    if(CopyBuffer(handle_sar, 0, 0, 2, sar_buffer) < 2)
        return false;
    
    dados_indicadores.sar_anterior = sar_anterior_armazenado;
    dados_indicadores.sar_atual = sar_buffer[0];
    sar_anterior_armazenado = sar_buffer[0];
    
    dados_indicadores.bb_superior = bb_upper[0];
    dados_indicadores.bb_media = bb_middle[0];
    dados_indicadores.bb_inferior = bb_lower[0];
    dados_indicadores.bb_media_anterior = bb_media_anterior_armazenada;
    
    dados_indicadores.bb_media_subindo = (dados_indicadores.bb_media > dados_indicadores.bb_media_anterior);
    dados_indicadores.bb_media_descendo = (dados_indicadores.bb_media < dados_indicadores.bb_media_anterior);
    bb_media_anterior_armazenada = dados_indicadores.bb_media;
    
    double close = Close(Symbol(), Period(), 0);
    dados_indicadores.sar_subindo = (dados_indicadores.sar_atual < close);
    dados_indicadores.sar_descendo = (dados_indicadores.sar_atual > close);
    
    if(dados_indicadores.sar_anterior != 0)
    {
        bool sar_estava_subindo = (dados_indicadores.sar_anterior < close);
        dados_indicadores.sar_inverteu = (sar_estava_subindo != dados_indicadores.sar_subindo);
    }
    else
    {
        dados_indicadores.sar_inverteu = false;
    }
    
    return true;
}

void ProcessarSinaisEntrada()
{
    if(bloqueio_operacoes || CountOpenOrders() >= MAX_OPERACOES_SIMULTANEAS)
        return;
    
    // COMPRA
    if(dados_indicadores.sar_subindo && dados_indicadores.bb_media_subindo)
    {
        double mudanca = 0;
        if(dados_indicadores.bb_media_anterior > 0)
            mudanca = ((dados_indicadores.bb_media - dados_indicadores.bb_media_anterior) / dados_indicadores.bb_media_anterior) * 100;
        
        if(mudanca >= PERCENTUAL_INCLINACAO_MIN)
            ExecutarCompra();
    }
    
    // VENDA
    if(dados_indicadores.sar_descendo && dados_indicadores.bb_media_descendo)
    {
        double mudanca = 0;
        if(dados_indicadores.bb_media_anterior > 0)
            mudanca = ((dados_indicadores.bb_media_anterior - dados_indicadores.bb_media) / dados_indicadores.bb_media_anterior) * 100;
        
        if(mudanca >= PERCENTUAL_INCLINACAO_MIN)
            ExecutarVenda();
    }
}

void ExecutarCompra()
{
    double ask = Ask();
    double lote = CalcularLote(SL_FIXO_PONTOS);
    
    if(lote <= 0)
        return;
    
    double preco_entrada = ask;
    if(ask > dados_indicadores.bb_media)
        preco_entrada = dados_indicadores.bb_media;
    
    double sl = preco_entrada - (SL_FIXO_PONTOS * Point());
    double tp = preco_entrada + (GANHO_ALVO_PONTOS * Point());
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = lote;
    request.type = ORDER_TYPE_BUY;
    request.price = preco_entrada;
    request.sl = sl;
    request.tp = tp;
    request.magic = MAGIC_NUMBER;
    request.comment = "EA_SAR_BB";
    request.deviation = 30;
    
    if(OrderSend(request, result))
    {
        if(result.deal != 0)
        {
            tem_posicao_aberta = true;
            ticket_posicao_aberta = result.deal;
            preco_entrada_posicao = preco_entrada;
            tipo_posicao_aberta = "BUY";
            preco_max_posicao = preco_entrada;
            sar_reversal_contador = 0;
            
            Print("[COMPRA] Deal: " + IntegerToString(result.deal) + " | Entrada: " + DoubleToString(preco_entrada, Digits()));
        }
    }
}

void ExecutarVenda()
{
    double bid = Bid();
    double lote = CalcularLote(SL_FIXO_PONTOS);
    
    if(lote <= 0)
        return;
    
    double preco_entrada = bid;
    if(bid < dados_indicadores.bb_media)
        preco_entrada = dados_indicadores.bb_media;
    
    double sl = preco_entrada + (SL_FIXO_PONTOS * Point());
    double tp = preco_entrada - (GANHO_ALVO_PONTOS * Point());
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = lote;
    request.type = ORDER_TYPE_SELL;
    request.price = preco_entrada;
    request.sl = sl;
    request.tp = tp;
    request.magic = MAGIC_NUMBER;
    request.comment = "EA_SAR_BB";
    request.deviation = 30;
    
    if(OrderSend(request, result))
    {
        if(result.deal != 0)
        {
            tem_posicao_aberta = true;
            ticket_posicao_aberta = result.deal;
            preco_entrada_posicao = preco_entrada;
            tipo_posicao_aberta = "SELL";
            preco_min_posicao = preco_entrada;
            sar_reversal_contador = 0;
            
            Print("[VENDA] Deal: " + IntegerToString(result.deal) + " | Entrada: " + DoubleToString(preco_entrada, Digits()));
        }
    }
}

void GerenciarPosicaoAberta()
{
    CPositionInfo posicao;
    
    if(!posicao.SelectByTicket(ticket_posicao_aberta))
    {
        tem_posicao_aberta = false;
        return;
    }
    
    double bid = Bid();
    double ask = Ask();
    double preco_atual = (tipo_posicao_aberta == "BUY") ? bid : ask;
    
    // Atualizar máximo/mínimo
    if(tipo_posicao_aberta == "BUY" && preco_atual > preco_max_posicao)
        preco_max_posicao = preco_atual;
    
    if(tipo_posicao_aberta == "SELL" && preco_atual < preco_min_posicao)
        preco_min_posicao = preco_atual;
    
    // Saída por Banda
    if(tipo_posicao_aberta == "BUY" && bid >= dados_indicadores.bb_superior)
    {
        FecharPosicao("Banda Superior");
        return;
    }
    
    if(tipo_posicao_aberta == "SELL" && ask <= dados_indicadores.bb_inferior)
    {
        FecharPosicao("Banda Inferior");
        return;
    }
    
    // Stop Loss SAR
    if(TIPO_SL == SAR_REVERSAL)
    {
        if(dados_indicadores.sar_inverteu)
        {
            if(tipo_posicao_aberta == "BUY" && dados_indicadores.sar_descendo)
            {
                sar_reversal_contador++;
                if(sar_reversal_contador >= SAR_REVERSAIS_SL)
                {
                    FecharPosicao("SAR Reversal SL");
                    return;
                }
            }
            else if(tipo_posicao_aberta == "SELL" && dados_indicadores.sar_subindo)
            {
                sar_reversal_contador++;
                if(sar_reversal_contador >= SAR_REVERSAIS_SL)
                {
                    FecharPosicao("SAR Reversal SL");
                    return;
                }
            }
            else if((tipo_posicao_aberta == "BUY" && dados_indicadores.sar_subindo) ||
                    (tipo_posicao_aberta == "SELL" && dados_indicadores.sar_descendo))
            {
                sar_reversal_contador = 0;
            }
        }
    }
    
    // Trailing Stop
    if(USAR_TRAILING)
    {
        CTrade trade;
        
        if(tipo_posicao_aberta == "BUY")
        {
            if((preco_max_posicao - preco_entrada_posicao) > (TRAILING_START_PONTOS * Point()))
            {
                double novo_sl = preco_max_posicao - (TRAILING_DISTANCIA * Point());
                if(novo_sl > posicao.StopLoss())
                    trade.PositionModify(ticket_posicao_aberta, novo_sl, posicao.TakeProfit());
            }
        }
        else if(tipo_posicao_aberta == "SELL")
        {
            if((preco_entrada_posicao - preco_min_posicao) > (TRAILING_START_PONTOS * Point()))
            {
                double novo_sl = preco_min_posicao + (TRAILING_DISTANCIA * Point());
                if(novo_sl < posicao.StopLoss())
                    trade.PositionModify(ticket_posicao_aberta, novo_sl, posicao.TakeProfit());
            }
        }
    }
}

void FecharPosicao(string motivo)
{
    CPositionInfo posicao;
    CTrade trade;
    
    if(!posicao.SelectByTicket(ticket_posicao_aberta))
        return;
    
    double preco_saida = (tipo_posicao_aberta == "BUY") ? Bid() : Ask();
    double resultado_pontos = (tipo_posicao_aberta == "BUY") ?
                              ((preco_saida - preco_entrada_posicao) / Point()) :
                              ((preco_entrada_posicao - preco_saida) / Point());
    
    double resultado_moeda = CalcularValorEmMoeda(resultado_pontos * Point());
    
    if(trade.PositionClose(ticket_posicao_aberta))
    {
        resultado_dia += resultado_moeda;
        
        if(resultado_moeda >= 0)
            operacoes_ganhas++;
        else
            operacoes_perdidas++;
        
        LogarOperacao(tipo_posicao_aberta, preco_entrada_posicao, posicao.Volume(),
                     preco_saida, resultado_pontos, resultado_moeda, motivo);
        
        Print("[FECHADO] " + motivo + " | R$ " + DoubleToString(resultado_moeda, 2));
        
        tem_posicao_aberta = false;
        ticket_posicao_aberta = 0;
        
        VerificarMetas();
    }
}

//═══════════════════════════════════════════════════════════════════════════════════
//                             FUNÇÕES AUXILIARES
//═══════════════════════════════════════════════════════════════════════════════════

double CalcularLote(double stop_loss_pontos)
{
    if(TIPO_LOTE == LOTE_FIXO)
        return LOTE_FIXO_VALOR;
    
    double risco_moeda = CAPITAL_INICIAL * (RISCO_PERCENTUAL_VALOR / 100.0);
    double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    
    if(tick_size == 0) return 0;
    
    double lote = risco_moeda / ((stop_loss_pontos / tick_size) * tick_value);
    return NormalizeDouble(lote, 2);
}

double CalcularValorEmMoeda(double pontos_valor)
{
    double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    
    if(tick_size == 0) return 0;
    return (pontos_valor / tick_size) * tick_value;
}

bool DentroDoHorarioOperacional()
{
    if(!USAR_HORARIO_OPERACIONAL)
        return true;
    
    int hora_agora = Hour();
    int minuto_agora = Minute();
    
    int hora_inicio = StringToInteger(StringSubstr(HORARIO_INICIO, 0, 2));
    int minuto_inicio = StringToInteger(StringSubstr(HORARIO_INICIO, 3, 2));
    
    int hora_fim = StringToInteger(StringSubstr(HORARIO_FIM, 0, 2));
    int minuto_fim = StringToInteger(StringSubstr(HORARIO_FIM, 3, 2));
    
    int tempo_agora = hora_agora * 60 + minuto_agora;
    int tempo_inicio = hora_inicio * 60 + minuto_inicio;
    int tempo_fim = hora_fim * 60 + minuto_fim;
    
    return (tempo_agora >= tempo_inicio && tempo_agora <= tempo_fim);
}

void VerificarMetas()
{
    if(resultado_dia >= META_GANHO_DIARIO)
    {
        bloqueio_operacoes = true;
        Alert("✓ META ATINGIDA: R$ " + DoubleToString(resultado_dia, 2));
    }
    
    if(resultado_dia <= -STOP_LOSS_DIARIO)
    {
        bloqueio_operacoes = true;
        Alert("✗ STOP LOSS DIÁRIO: R$ " + DoubleToString(resultado_dia, 2));
    }
}

int CountOpenOrders()
{
    int count = 0;
    int total = PositionsTotal();
    
    for(int i = total - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetInteger(POSITION_MAGIC) == MAGIC_NUMBER &&
               PositionGetString(POSITION_SYMBOL) == Symbol())
            {
                count++;
            }
        }
    }
    
    return count;
}

bool ValidarInputs()
{
    if(LOTE_FIXO_VALOR <= 0 && TIPO_LOTE == LOTE_FIXO)
    {
        Alert("[ERRO] Lote deve ser > 0");
        return false;
    }
    
    if(SL_FIXO_PONTOS <= 0)
    {
        Alert("[ERRO] SL em Pontos deve ser > 0");
        return false;
    }
    
    return true;
}

void LogarOperacao(string tipo, double entrada, double volume, double saida,
                   double pts, double moeda, string motivo)
{
    if(!LOGGING_ATIVO || arquivo_log == "")
        return;
    
    int h = FileOpen(arquivo_log, FILE_READ|FILE_WRITE|FILE_TXT);
    if(h != INVALID_HANDLE)
    {
        FileSeek(h, 0, SEEK_END);
        FileWrite(h, "[" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "] " +
                 tipo + " | Entrada: " + DoubleToString(entrada, Digits()) +
                 " | Saída: " + DoubleToString(saida, Digits()) +
                 " | Pts: " + DoubleToString(pts, 0) +
                 " | R$: " + DoubleToString(moeda, 2) +
                 " | " + motivo);
        FileClose(h);
    }
}

void AtualizarDashboard()
{
    if(!DASHBOARD_ATIVO)
        return;
    
    string status = ea_ligada ? "ON" : "OFF";
    string info = "SAR+BB | " + status + " | R$ " + DoubleToString(resultado_dia, 2) +
                  " | W: " + IntegerToString(operacoes_ganhas) + " L: " + IntegerToString(operacoes_perdidas);
    
    ObjectCreate(0, "dash_titulo", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "dash_titulo", OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, "dash_titulo", OBJPROP_YDISTANCE, 30);
    ObjectSetString(0, "dash_titulo", OBJPROP_TEXT, info);
    ObjectSetInteger(0, "dash_titulo", OBJPROP_COLOR, clrWhiteSmoke);
}
