//+------------------------------------------------------------------+
//| Expert Advisor: SAR Parabólico + Bandas de Bollinger             |
//| Estratégia: SAR indica direção, BB define entrada e saída         |
//| Versão: 1.0                                                       |
//| Data: 01/07/2026                                                  |
//+------------------------------------------------------------------+

#property strict
#property version "1.0"
#property description "EA profissional com SAR Parabólico e Bandas de Bollinger para B3 e Forex"
#property icon "🤖"

//+------ INCLUDES DAS BIBLIOTECAS ------+
#include "../templates/bibliotecas/Indicators_SAR_BB.mqh"
#include "../templates/bibliotecas/Logger_SAR_BB.mqh"
#include "../templates/bibliotecas/Dashboard_SAR_BB.mqh"

//═════════════════════════════════════════════════════════════════════════════════
//                           SEÇÃO DE INPUTS - CONTROLE GERAL
//═════════════════════════════════════════════════════════════════════════════════

input group "╔════════════════════════════════════════════════════╗"
input group "║         CONFIGURAÇÃO GERAL DA EA                  ║"
input group "╚════════════════════════════════════════════════════╝"

input int    MAGIC_NUMBER = 20260701;           // Magic Number Único
input string EA_VERSAO = "1.0";                 // Versão da EA
input bool   EA_ATIVA = true;                   // EA Ativada?
input bool   DASHBOARD_ATIVO = true;            // Mostrar Dashboard?
input bool   LOGGING_ATIVO = true;              // Ativar Logging?

//═════════════════════════════════════════════════════════════════════════════════
//                           SEÇÃO DE INPUTS - INDICADORES
//═════════════════════════════════════════════════════════════════════════════════

input group "╔════════════════════════════════════════════════════╗"
input group "║      CONFIGURAÇÃO DOS INDICADORES                 ║"
input group "╚════════════════════════════════════════════════════╝"

input int    BB_PERIODO = 20;                   // Período das Bandas de Bollinger
input double BB_DESVIO = 2.0;                   // Desvio Padrão das Bandas
input double SAR_ACELERACAO_INICIO = 0.02;      // Aceleração Inicial do SAR
input double SAR_ACELERACAO_MAX = 0.20;         // Aceleração Máxima do SAR
input double PERCENTUAL_INCLINACAO_MIN = 0.1;  // Inclinação Mínima da Banda (%)

//═════════════════════════════════════════════════════════════════════════════════
//                           SEÇÃO DE INPUTS - ENTRADA
//═════════════════════════════════════════════════════════════════════════════════

input group "╔════════════════════════════════════════════════════╗"
input group "║          CONFIGURAÇÃO DE ENTRADA                  ║"
input group "╚════════════════════════════════════════════════════╝"

enum TipoLote
{
    LOTE_FIXO = 0,              // Lote fixo em contratos
    RISCO_PERCENTUAL = 1        // % de risco sobre o capital
};

input TipoLote  TIPO_LOTE = LOTE_FIXO;          // Tipo de Lote
input double    LOTE_FIXO_VALOR = 1.0;         // Valor do Lote Fixo (contratos)
input double    RISCO_PERCENTUAL_VALOR = 2.0;  // % de Risco do Capital
input double    CAPITAL_INICIAL = 10000.0;      // Capital Inicial para Cálculo de Risco
input int       MAX_OPERACOES_SIMULTANEAS = 1;  // Máximo de Operações Simultâneas

//═════════════════════════════════════════════════════════════════════════════════
//                           SEÇÃO DE INPUTS - STOP LOSS E GAIN
//═════════════════════════════════════════════════════════════════════════════════

input group "╔════════════════════════════════════════════════════╗"
input group "║        CONFIGURAÇÃO DE STOP LOSS E GAIN            ║"
input group "╚════════════════════════════════════════════════════╝"

enum TipoSaida
{
    FIXO_PONTOS = 0,            // Stop Loss fixo em pontos
    SAR_REVERSAL = 1            // Stop Loss por reversão de SAR
};

input TipoSaida TIPO_SL = SAR_REVERSAL;         // Tipo de Stop Loss
input double    SL_FIXO_PONTOS = 50.0;          // Stop Loss Fixo (pontos)
input int       SAR_REVERSAIS_SL = 3;           // Número de Reversões do SAR para SL
input double    GANHO_ALVO_PONTOS = 100.0;      // Ganho Alvo ao Tocar a Banda (pontos)
input bool      USAR_TRAILING = true;           // Usar Trailing Stop?
input double    TRAILING_START_PONTOS = 50.0;   // Pontos para Ativar Trailing
input double    TRAILING_DISTANCIA = 20.0;      // Distância do Trailing em Pontos

//═════════════════════════════════════════════════════════════════════════════════
//                           SEÇÃO DE INPUTS - METAS E HORÁRIOS
//═════════════════════════════════════════════════════════════════════════════════

input group "╔════════════════════════════════════════════════════╗"
input group "║      CONFIGURAÇÃO DE METAS E HORÁRIOS             ║"
input group "╚════════════════════════════════════════════════════╝"

input double    META_GANHO_DIARIO = 200.0;      // Meta de Ganho Diário (R$)
input double    STOP_LOSS_DIARIO = 200.0;       // Stop Loss Diário (R$)
input bool      USAR_HORARIO_OPERACIONAL = true;// Usar Horários Específicos?
input string    HORARIO_INICIO = "09:30";       // Horário de Início (HH:MM)
input string    HORARIO_FIM = "17:00";          // Horário de Fim (HH:MM)

//═════════════════════════════════════════════════════════════════════════════════
//                              VARIÁVEIS GLOBAIS
//═════════════════════════════════════════════════════════════════════════════════

IndicadoresManager indicadores_mgr;             // Gerenciador de Indicadores
LoggerManager      logger_mgr;                  // Gerenciador de Logs
DashboardManager   dashboard_mgr;               // Gerenciador de Dashboard

IndicatorData      dados_indicadores;           // Dados dos Indicadores Atuais

// Variáveis de Controle
bool               ea_ligada = true;            // EA está ligada?
bool               bloqueio_operacoes = false;  // Bloqueio por meta/stop?
int                operacoes_ganhas = 0;        // Contador de ganhos
int                operacoes_perdidas = 0;      // Contador de perdas
double             resultado_dia = 0.0;         // Resultado acumulado do dia
int                sar_reversal_contador = 0;   // Contador de reversões do SAR
bool               tem_posicao_aberta = false;   // Tem posição aberta?
int                ticket_posicao_aberta = -1;  // Ticket da posição aberta
double             preco_entrada_posicao = 0;   // Preço de entrada da posição
string             tipo_posicao_aberta = "";   // Tipo da posição (BUY/SELL)
double             preco_max_posicao = 0;      // Preço máximo atingido (para trailing)
double             preco_min_posicao = 0;      // Preço mínimo atingido (para trailing)

//═════════════════════════════════════════════════════════════════════════════════
//                           FUNÇÃO PRINCIPAL: OnInit
//═════════════════════════════════════════════════════════════════════════════════

int OnInit()
{
    // Validar inputs
    if(!ValidarInputs())
    {
        Alert("[ERRO] Validação de inputs falhou. EA não iniciada.");
        return INIT_FAILED;
    }
    
    // Inicializar Indicadores
    if(!indicadores_mgr.Inicializar(Symbol(), Period(), BB_PERIODO, BB_DESVIO, SAR_ACELERACAO_INICIO, SAR_ACELERACAO_MAX))
    {
        Alert("[ERRO] Falha ao inicializar indicadores.");
        return INIT_FAILED;
    }
    
    // Inicializar Logger
    if(!logger_mgr.Inicializar(Symbol(), Period(), LOGGING_ATIVO))
    {
        Alert("[ERRO] Falha ao inicializar logger.");
        return INIT_FAILED;
    }
    
    // Inicializar Dashboard
    if(!dashboard_mgr.Inicializar(DASHBOARD_ATIVO))
    {
        Alert("[ERRO] Falha ao inicializar dashboard.");
        return INIT_FAILED;
    }
    
    // Reset de contadores
    operacoes_ganhas = 0;
    operacoes_perdidas = 0;
    resultado_dia = 0.0;
    sar_reversal_contador = 0;
    
    Print("╔════════════════════════════════════════════════╗");
    Print("║  EA SAR Parabólico + Bandas de Bollinger v" + EA_VERSAO + "  ║");
    Print("║  Magic: " + IntegerToString(MAGIC_NUMBER) + "  Ativo: " + Symbol() + "  TF: " + EnumToString(Period()) + "  ║");
    Print("╚════════════════════════════════════════════════╝");
    
    return INIT_SUCCEEDED;
}

//═════════════════════════════════════════════════════════════════════════════════
//                           FUNÇÃO PRINCIPAL: OnTick
//═════════════════════════════════════════════════════════════════════════════════

void OnTick()
{
    // Verificações Básicas
    if(!EA_ATIVA || !IsConnected())
        return;
    
    if(!DentroDoHorarioOperacional())
        return;
    
    // Obter dados dos indicadores
    if(!indicadores_mgr.ObterDados(Symbol(), dados_indicadores))
    {
        logger_mgr.LogarErro("Falha ao obter dados dos indicadores", "OnTick");
        return;
    }
    
    // Logar dados da candle
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(Symbol(), Period(), 0, 1, rates) == 1)
    {
        logger_mgr.LogarCandle(Symbol(), Period(), dados_indicadores,
                              rates[0].close, rates[0].open, rates[0].high, rates[0].low, rates[0].real_volume);
    }
    
    // Verificar se tem posição aberta
    if(tem_posicao_aberta)
    {
        GerenciarPosicaoAberta();
    }
    else
    {
        // Procurar novos sinais de entrada
        ProcessarSinaisEntrada();
    }
    
    // Atualizar Dashboard
    if(DASHBOARD_ATIVO)
    {
        double resultado_flutuante = CalcularResultadoFlutuante();
        string ultima_op = (tem_posicao_aberta) ? tipo_posicao_aberta + " @ " + DoubleToString(preco_entrada_posicao, Digits()) : "Sem posição";
        
        dashboard_mgr.AtualizarDashboard(Symbol(), Period(),
                                        resultado_dia, operacoes_ganhas, operacoes_perdidas,
                                        operacoes_ganhas + operacoes_perdidas, resultado_flutuante,
                                        META_GANHO_DIARIO, STOP_LOSS_DIARIO,
                                        EA_ATIVA, ultima_op,
                                        dados_indicadores, EA_VERSAO);
    }
}

//═════════════════════════════════════════════════════════════════════════════════
//                           FUNÇÃO PRINCIPAL: OnDeinit
//═════════════════════════════════════════════════════════════════════════════════

void OnDeinit(const int reason)
{
    indicadores_mgr.Liberar();
    dashboard_mgr.Limpar();
    Print("[INFO] EA finalizada. Motivo: " + IntegerToString(reason));
}

//═════════════════════════════════════════════════════════════════════════════════
//                           FUNÇÕES DE LÓGICA DA EA
//═════════════════════════════════════════════════════════════════════════════════

//+------ PROCESSAR SINAIS DE ENTRADA ------+
void ProcessarSinaisEntrada()
{
    // Verificar bloqueios
    if(bloqueio_operacoes)
        return;
    
    if(CountOpenOrders() >= MAX_OPERACOES_SIMULTANEAS)
        return;
    
    // Verificar sinal de COMPRA
    if(indicadores_mgr.VerificaSinalCompra(dados_indicadores, PERCENTUAL_INCLINACAO_MIN))
    {
        logger_mgr.LogarSinal("COMPRA", dados_indicadores);
        ExecutarCompra();
    }
    
    // Verificar sinal de VENDA
    if(indicadores_mgr.VerificaSinalVenda(dados_indicadores, PERCENTUAL_INCLINACAO_MIN))
    {
        logger_mgr.LogarSinal("VENDA", dados_indicadores);
        ExecutarVenda();
    }
}

//+------ EXECUTAR COMPRA ------+
void ExecutarCompra()
{
    double bid = Bid();
    double ask = Ask();
    double lote = CalcularLote(SL_FIXO_PONTOS);
    
    if(lote <= 0)
    {
        logger_mgr.LogarErro("Lote calculado inválido: " + DoubleToString(lote, 2), "ExecutarCompra");
        return;
    }
    
    double preco_entrada = ask;
    
    // Se preço está abaixo da banda média = compra a mercado
    // Se preço está acima da banda média = compra limite na banda média
    if(ask > dados_indicadores.bb_media)
    {
        preco_entrada = dados_indicadores.bb_media;
    }
    
    double sl = CalcularStopLoss(preco_entrada, true);  // true = compra
    double tp = preco_entrada + (GANHO_ALVO_PONTOS * Point());
    
    int ticket = OrderSend(Symbol(), OP_BUY, lote, preco_entrada, 30, sl, tp, 
                           "EA_SAR_BB_" + IntegerToString(MAGIC_NUMBER), MAGIC_NUMBER, 0, clrGreen);
    
    if(ticket > 0)
    {
        tem_posicao_aberta = true;
        ticket_posicao_aberta = ticket;
        preco_entrada_posicao = preco_entrada;
        tipo_posicao_aberta = "BUY";
        preco_max_posicao = preco_entrada;
        sar_reversal_contador = 0;
        
        Print("[COMPRA] Ticket: " + IntegerToString(ticket) + " | Entrada: " + DoubleToString(preco_entrada, Digits()) + " | SL: " + DoubleToString(sl, Digits()));
    }
    else
    {
        logger_mgr.LogarErro("Falha ao abrir ordem de COMPRA. Código: " + IntegerToString(GetLastError()), "ExecutarCompra");
    }
}

//+------ EXECUTAR VENDA ------+
void ExecutarVenda()
{
    double bid = Bid();
    double ask = Ask();
    double lote = CalcularLote(SL_FIXO_PONTOS);
    
    if(lote <= 0)
    {
        logger_mgr.LogarErro("Lote calculado inválido: " + DoubleToString(lote, 2), "ExecutarVenda");
        return;
    }
    
    double preco_entrada = bid;
    
    // Se preço está acima da banda média = venda a mercado
    // Se preço está abaixo da banda média = venda limite na banda média
    if(bid < dados_indicadores.bb_media)
    {
        preco_entrada = dados_indicadores.bb_media;
    }
    
    double sl = CalcularStopLoss(preco_entrada, false);  // false = venda
    double tp = preco_entrada - (GANHO_ALVO_PONTOS * Point());
    
    int ticket = OrderSend(Symbol(), OP_SELL, lote, preco_entrada, 30, sl, tp,
                           "EA_SAR_BB_" + IntegerToString(MAGIC_NUMBER), MAGIC_NUMBER, 0, clrRed);
    
    if(ticket > 0)
    {
        tem_posicao_aberta = true;
        ticket_posicao_aberta = ticket;
        preco_entrada_posicao = preco_entrada;
        tipo_posicao_aberta = "SELL";
        preco_min_posicao = preco_entrada;
        sar_reversal_contador = 0;
        
        Print("[VENDA] Ticket: " + IntegerToString(ticket) + " | Entrada: " + DoubleToString(preco_entrada, Digits()) + " | SL: " + DoubleToString(sl, Digits()));
    }
    else
    {
        logger_mgr.LogarErro("Falha ao abrir ordem de VENDA. Código: " + IntegerToString(GetLastError()), "ExecutarVenda");
    }
}

//+------ GERENCIAR POSIÇÃO ABERTA ------+
void GerenciarPosicaoAberta()
{
    if(!OrderSelect(ticket_posicao_aberta, SELECT_BY_TICKET))
    {
        tem_posicao_aberta = false;
        return;
    }
    
    double bid = Bid();
    double ask = Ask();
    double preco_atual = (tipo_posicao_aberta == "BUY") ? bid : ask;
    
    // Atualizar preço máximo/mínimo para trailing
    if(tipo_posicao_aberta == "BUY" && preco_atual > preco_max_posicao)
    {
        preco_max_posicao = preco_atual;
    }
    if(tipo_posicao_aberta == "SELL" && preco_atual < preco_min_posicao)
    {
        preco_min_posicao = preco_atual;
    }
    
    // VERIFICAR SAÍDA POR BANDA DE BOLLINGER
    // COMPRA: Tocar banda superior
    if(tipo_posicao_aberta == "BUY" && bid >= dados_indicadores.bb_superior)
    {
        FecharPosicao("Saída por Banda Superior");
        return;
    }
    
    // VENDA: Tocar banda inferior
    if(tipo_posicao_aberta == "SELL" && ask <= dados_indicadores.bb_inferior)
    {
        FecharPosicao("Saída por Banda Inferior");
        return;
    }
    
    // VERIFICAR STOP LOSS POR REVERSÃO DO SAR
    if(TIPO_SL == SAR_REVERSAL)
    {
        if(dados_indicadores.sar_inverteu)
        {
            // Se é COMPRA e SAR inverteu para BAIXO
            if(tipo_posicao_aberta == "BUY" && dados_indicadores.sar_descendo)
            {
                sar_reversal_contador++;
                if(sar_reversal_contador >= SAR_REVERSAIS_SL)
                {
                    FecharPosicao("Stop Loss por " + IntegerToString(SAR_REVERSAIS_SL) + " Reversões do SAR");
                    return;
                }
            }
            // Se é VENDA e SAR inverteu para CIMA
            else if(tipo_posicao_aberta == "SELL" && dados_indicadores.sar_subindo)
            {
                sar_reversal_contador++;
                if(sar_reversal_contador >= SAR_REVERSAIS_SL)
                {
                    FecharPosicao("Stop Loss por " + IntegerToString(SAR_REVERSAIS_SL) + " Reversões do SAR");
                    return;
                }
            }
            // Se SAR voltou para a direção correta = reset contador
            else if((tipo_posicao_aberta == "BUY" && dados_indicadores.sar_subindo) ||
                    (tipo_posicao_aberta == "SELL" && dados_indicadores.sar_descendo))
            {
                sar_reversal_contador = 0;
            }
        }
    }
    
    // VERIFICAR TRAILING STOP
    if(USAR_TRAILING)
    {
        if(tipo_posicao_aberta == "BUY")
        {
            // Se ganho > TRAILING_START, ativar trailing
            if((preco_max_posicao - preco_entrada_posicao) > (TRAILING_START_PONTOS * Point()))
            {
                double novo_sl = preco_max_posicao - (TRAILING_DISTANCIA * Point());
                if(novo_sl > OrderStopLoss())
                {
                    OrderModify(ticket_posicao_aberta, preco_entrada_posicao, novo_sl, OrderTakeProfit(), 0, clrGreen);
                }
            }
        }
        else if(tipo_posicao_aberta == "SELL")
        {
            // Se ganho > TRAILING_START, ativar trailing
            if((preco_entrada_posicao - preco_min_posicao) > (TRAILING_START_PONTOS * Point()))
            {
                double novo_sl = preco_min_posicao + (TRAILING_DISTANCIA * Point());
                if(novo_sl < OrderStopLoss())
                {
                    OrderModify(ticket_posicao_aberta, preco_entrada_posicao, novo_sl, OrderTakeProfit(), 0, clrRed);
                }
            }
        }
    }
}

//+------ FECHAR POSIÇÃO ------+
void FecharPosicao(string motivo)
{
    if(!OrderSelect(ticket_posicao_aberta, SELECT_BY_TICKET))
        return;
    
    double preco_saida = (tipo_posicao_aberta == "BUY") ? Bid() : Ask();
    double resultado_pontos = (tipo_posicao_aberta == "BUY") ? 
                              ((preco_saida - preco_entrada_posicao) / Point()) :
                              ((preco_entrada_posicao - preco_saida) / Point());
    
    double resultado_moeda = CalcularValorEmMoeda(resultado_pontos * Point());
    
    bool fechado = OrderClose(ticket_posicao_aberta, OrderTicket(), preco_saida, 30);
    
    if(fechado)
    {
        resultado_dia += resultado_moeda;
        
        if(resultado_moeda >= 0)
            operacoes_ganhas++;
        else
            operacoes_perdidas++;
        
        double balance = AccountBalance();
        double equity = AccountEquity();
        double drawdown = ((balance - equity) / balance) * 100;
        
        logger_mgr.LogarOperacao(tipo_posicao_aberta, preco_entrada_posicao, OrderTicket(),
                                preco_saida, resultado_pontos, resultado_moeda,
                                balance, equity, drawdown);
        
        Print("[FECHADO] " + motivo + " | Resultado: " + DoubleToString(resultado_moeda, 2) + " R$");
        
        tem_posicao_aberta = false;
        ticket_posicao_aberta = -1;
        
        // Verificar metas
        VerificarMetas();
    }
}

//═════════════════════════════════════════════════════════════════════════════════
//                           FUNÇÕES AUXILIARES
//═════════════════════════════════════════════════════════════════════════════════

//+------ CALCULAR LOTE ------+
double CalcularLote(double stop_loss_pontos)
{
    if(TIPO_LOTE == LOTE_FIXO)
    {
        return LOTE_FIXO_VALOR;
    }
    else if(TIPO_LOTE == RISCO_PERCENTUAL)
    {
        double risco_moeda = CAPITAL_INICIAL * (RISCO_PERCENTUAL_VALOR / 100.0);
        double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
        double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
        double contract_size = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
        
        double lote = risco_moeda / ((stop_loss_pontos / tick_size) * tick_value * contract_size);
        return NormalizeDouble(lote, 2);
    }
    
    return 0;
}

//+------ CALCULAR STOP LOSS ------+
double CalcularStopLoss(double preco_entrada, bool eh_compra)
{
    if(TIPO_SL == FIXO_PONTOS)
    {
        if(eh_compra)
            return preco_entrada - (SL_FIXO_PONTOS * Point());
        else
            return preco_entrada + (SL_FIXO_PONTOS * Point());
    }
    
    return 0;  // SAR Reversal não tem SL fixo
}

//+------ CALCULAR VALOR EM MOEDA ------+
double CalcularValorEmMoeda(double pontos_valor)
{
    double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    double contract_size = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
    
    return (pontos_valor / tick_size) * tick_value * contract_size;
}

//+------ CALCULAR RESULTADO FLUTUANTE ------+
double CalcularResultadoFlutuante()
{
    if(!tem_posicao_aberta)
        return 0.0;
    
    if(!OrderSelect(ticket_posicao_aberta, SELECT_BY_TICKET))
        return 0.0;
    
    double bid = Bid();
    double ask = Ask();
    
    if(tipo_posicao_aberta == "BUY")
    {
        return (bid - preco_entrada_posicao) * OrderTicket();
    }
    else
    {
        return (preco_entrada_posicao - ask) * OrderTicket();
    }
}

//+------ DENTRO DO HORÁRIO OPERACIONAL ------+
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

//+------ VERIFICAR METAS ------+
void VerificarMetas()
{
    if(resultado_dia >= META_GANHO_DIARIO)
    {
        bloqueio_operacoes = true;
        Alert("✓ META DE GANHO ATINGIDA: R$ " + DoubleToString(resultado_dia, 2));
    }
    
    if(resultado_dia <= -STOP_LOSS_DIARIO)
    {
        bloqueio_operacoes = true;
        Alert("✗ STOP LOSS DIÁRIO ATINGIDO: R$ " + DoubleToString(resultado_dia, 2));
    }
}

//+------ CONTAR ORDENS ABERTAS ------+
int CountOpenOrders()
{
    int count = 0;
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS))
        {
            if(OrderMagicNumber() == MAGIC_NUMBER && OrderSymbol() == Symbol())
                count++;
        }
    }
    return count;
}

//+------ VALIDAR INPUTS ------+
bool ValidarInputs()
{
    if(LOTE_FIXO_VALOR <= 0 && TIPO_LOTE == LOTE_FIXO)
    {
        Alert("[ERRO] Lote Fixo deve ser maior que 0");
        return false;
    }
    
    if(RISCO_PERCENTUAL_VALOR <= 0 || RISCO_PERCENTUAL_VALOR > 100)
    {
        Alert("[ERRO] Risco Percentual deve estar entre 0 e 100");
        return false;
    }
    
    if(SL_FIXO_PONTOS <= 0)
    {
        Alert("[ERRO] Stop Loss em Pontos deve ser maior que 0");
        return false;
    }
    
    if(SAR_REVERSAIS_SL <= 0)
    {
        Alert("[ERRO] Número de Reversões do SAR deve ser maior que 0");
        return false;
    }
    
    return true;
}
