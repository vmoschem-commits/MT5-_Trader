# Padrões Obrigatórios para Desenvolvimento de EAs MT5

## 📋 Resumo Executivo

Este documento estabelece os **padrões OBRIGATÓRIOS** que toda EA desenvolvida neste repositório deve atender. O não cumprimento destes requisitos resulta em rejeição da implementação.

---

## 🎯 REQUISITOS CORE (Obrigatórios)

### 1. CÁLCULO DE TICKS E VALORES - B3 E FOREX

#### Especificações por Ativo

| Ativo | Exchange | Point | Tick Size | Tick Value | Digits | Contract Size |
|-------|----------|-------|-----------|------------|--------|---------------|
| WIN | B3 | 0.1 | 5 | R$ 5 | 1 | 1 |
| WDO | B3 | 0.0001 | 0.0001 | R$ 1 | 4 | 100 |
| XAUUSD | Forex | 0.01 | 0.01 | USD variável | 2 | 100 |

#### Fórmulas Obrigatórias

```c
// Conversão de pontos para moeda
double pontosParaValor(double pontos, string symbol)
{
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // Valor em moeda = (Pontos / TickSize) * TickValue
    return (pontos / tickSize) * tickValue * SymbolInfoInteger(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
}

// Cálculo de lote baseado em risco
double calcularLote(double capital, double risco_percentual, double stopLoss_pontos, string symbol)
{
    double valor_risco = capital * (risco_percentual / 100);
    double valor_tick = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double contract_size = SymbolInfoInteger(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    
    // Lote = (Risco em moeda) / ((StopLoss em pontos / TickSize) * TickValue)
    double lote = valor_risco / ((stopLoss_pontos / tick_size) * valor_tick * contract_size);
    
    return NormalizeDouble(lote, 2);
}
```

#### Validações Obrigatórias

- ✓ Verificar se `SymbolInfoDouble()` retorna valores válidos
- ✓ Respeitar lote mínimo e máximo do broker
- ✓ Nunca usar ponto fixo (0.1) em cálculos - sempre usar `SymbolInfoDouble(symbol, SYMBOL_POINT)`
- ✓ Considerar o `SYMBOL_TRADE_CONTRACT_SIZE` em todos os cálculos

---

### 2. LOGGING COMPLETO (Candle a Candle ou Tick)

#### Estrutura do Log

```
DATA | HORA | TIMEFRAME | OPEN | HIGH | LOW | CLOSE | VOLUME | INDICADOR1 | INDICADOR2 | SINAL | ORDEM | RESULTADO | GAIN/LOSS_PTS | GAIN/LOSS_BRL | BALANCE | EQUITY | DRAWDOWN
```

#### Registro de Cada Candle

```c
void logarCandle()
{
    string arquivo = "MT5_EA_" + Symbol() + "_" + IntegerToString(Period()) + "_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log";
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    CopyRates(Symbol(), Period(), 0, 1, rates);
    
    double open = rates[0].open;
    double high = rates[0].high;
    double low = rates[0].low;
    double close = rates[0].close;
    long volume = rates[0].real_volume;
    
    string log = TimeToString(rates[0].time, TIME_DATE|TIME_SECONDS) + " | " +
                 DoubleToString(open, Digits()) + " | " +
                 DoubleToString(high, Digits()) + " | " +
                 DoubleToString(low, Digits()) + " | " +
                 DoubleToString(close, Digits()) + " | " +
                 IntegerToString(volume) + " | ";
    
    // Adicionar valores de indicadores, sinais, resultado operacional
    
    // Salvar em arquivo
    int handle = FileOpen(arquivo, FILE_READ|FILE_WRITE|FILE_TXT);
    if(handle != INVALID_HANDLE)
    {
        FileSeek(handle, 0, SEEK_END);
        FileWriteString(handle, log + "\n");
        FileClose(handle);
    }
}
```

#### Informações Obrigatórias no Log

1. **Dados da Candle**
   - Data e hora
   - Abertura, fechamento, alta, baixa
   - Volume
   - Timeframe

2. **Indicadores** (quando utilizados)
   - Valor de cada indicador
   - Se ativado ou desativado

3. **Sinais**
   - Tipo de sinal (COMPRA/VENDA/NENHUM)
   - Força do sinal (0-100%)
   - Condições atendidas

4. **Operações**
   - Ticket da ordem
   - Tipo (BUY/SELL)
   - Volume
   - Preço de entrada
   - Preço de saída
   - Resultado (GANHO/PERDA)

5. **Resultado Financeiro**
   - Ganho/perda em pontos
   - Ganho/perda em moeda (BRL/USD)
   - Comissão cobrada
   - Balance após operação
   - Equity (patrimônio)
   - Drawdown (%)

6. **Erros**
   - Código de erro
   - Descrição
   - Contexto da operação

---

### 3. DASHBOARD VISUAL OBRIGATÓRIO

#### Elementos Obrigatórios

```
╔══════════════════════════════════════════════════════╗
║           EA TRADER - PAINEL DE CONTROLE            ║
╠══════════════════════════════════════════════════════╣
║ Status: [LIGADA]  Versão: 1.0  Ativo: WIN  TF: H1  ║
║ Horário Servidor: 15:45:30  Magic: 12345           ║
╠══════════════════════════════════════════════════════╣
║                    CONTROLES                         ║
║  [LIGAR/DESLIGAR]  [ZERAR]  [BREAKEVEN]  [FECHAR]  ║
╠══════════════════════════════════════════════════════╣
║                   RESULTADO DO DIA                   ║
║  Resultado Fechado:  +R$ 450,00                      ║
║  Resultado Flutuante: -R$ 125,50                     ║
║  ─────────────────────────────                       ║
║  Total do Dia:       +R$ 324,50                      ║
╠══════════════════════════════════════════════════════╣
║                    ESTATÍSTICAS                      ║
║  Operações: 12  │  Ganhos: 8  │  Perdas: 4          ║
║  Win Rate: 66.67%  │  Lucro Médio: +R$ 56,25        ║
║  Perda Média: -R$ 78,13                             ║
╠══════════════════════════════════════════════════════╣
║                  METAS DO DIA                        ║
║  Meta de Ganho: +R$ 1.000,00  ████████░░ 32%        ║
║  Stop Loss: -R$ 500,00        ████░░░░░░ 26%        ║
╠══════════════════════════════════════════════════════╣
║              ÚLTIMA OPERAÇÃO                         ║
║  Tipo: COMPRA  │  Horário: 14:32:15  │  Resultado:  ║
║  Entrada: 98.450  │  Saída: 98.520  │  Ganho: +70p  ║
╠══════════════════════════════════════════════════════╣
║            INDICADORES (quando ativo)               ║
║  RSI(14): 65.32  │  MACD: 0.0125  │  Stoch: 78.5    ║
╚══════════════════════════════════════════════════════╝
```

#### Informações Mínimas Exibidas

| Informação | Atualização | Localização |
|-----------|------------|------------|
| Status (Ligada/Desligada) | A cada tick | Canto superior |
| Resultado Fechado (dia) | Após cada fechamento | Centro |
| Resultado Flutuante | A cada tick | Centro |
| Total do Dia | Contínuo | Centro |
| Número de Ganhos | Após cada fechamento | Direita |
| Número de Perdas | Após cada fechamento | Direita |
| Total de Operações | Após cada fechamento | Direita |
| Meta de Ganho Diário | Configurável | Inferior |
| Stop Loss Diário | Configurável | Inferior |
| Status da Meta (barra de progresso) | Contínuo | Inferior |
| Horário do Servidor | A cada segundo | Canto superior |
| Última operação | Após cada fechamento | Inferior |
| Indicadores (se ativos) | A cada tick | Inferior |

#### Cores Padrão

- **Verde**: Ganho, Compra, Ativo
- **Vermelho**: Perda, Venda, Inativo
- **Amarelo**: Alerta, Atenção
- **Cinza**: Informações neutras

---

### 4. GESTÃO FINANCEIRA DIÁRIA

#### Meta de Ganho Diário

```c
input double META_GANHO_DIARIO = 1000.0;  // Em BRL ou USD
input double STOP_LOSS_DIARIO = 500.0;    // Em BRL ou USD
input bool RESET_AUTOMATICO = true;       // Reset ao novo dia
input string HORARIO_RESET = "09:30";     // HH:MM

bool verificarMetas()
{
    double resultadoDia = CalcularResultadoDia();
    
    if(resultadoDia >= META_GANHO_DIARIO)
    {
        // Bloqueio de novas operações
        bloquearOperacoes = true;
        SomarEvento("Meta de Ganho Atingida");
        Alert("✓ Meta de Ganho Diária Atingida: " + DoubleToString(resultadoDia, 2));
        return true;
    }
    
    if(resultadoDia <= -STOP_LOSS_DIARIO)
    {
        // Bloqueio de novas operações
        bloquiarOperacoes = true;
        SomarEvento("Stop Loss Diário Atingido");
        Alert("✗ Stop Loss Diário Atingido: " + DoubleToString(resultadoDia, 2));
        return true;
    }
    
    return false;
}
```

#### Reset Automático

```c
bool verificarResetDiario()
{
    static datetime ultimoReset = 0;
    datetime agora = TimeCurrent();
    
    MqlDateTime estruturaAgora;
    TimeToStruct(agora, estruturaAgora);
    
    // Verificar se mudou de dia
    if(estruturaAgora.day != TimeToStruct(ultimoReset, estruturaAgora).day)
    {
        // Verificar horário configurado
        if(Hour() == horaReset && Minute() >= minutoReset)
        {
            ResetarEstatisticas();
            bloquiarOperacoes = false;
            ultimoReset = agora;
            return true;
        }
    }
    
    return false;
}
```

---

### 5. GESTÃO POR OPERAÇÃO

#### Tipos de Stop Loss

```c
enum TipoStopLoss
{
    FIXO_PONTOS,      // Ex: 50 pontos
    FIXO_MOEDA,       // Ex: R$ 100
    BREAKEVEN,        // Move para entrada + X pontos
    TRAILING_STOP,    // Trailing com distância
    PARCIAL           // Fechar % em X pontos
};

input TipoStopLoss TIPO_SL = FIXO_PONTOS;
input double VALOR_SL = 50.0;
input double GAIN_ALVO = 100.0;
input bool USAR_BREAKEVEN = true;
input double PONTOS_BREAKEVEN = 30.0;
input bool USAR_TRAILING = true;
input double TRAILING_START = 50.0;
input double TRAILING_DISTANCIA = 20.0;
input bool USAR_PARCIAL = true;
input double PARCIAL_PERCENTUAL = 50.0;
input double PARCIAL_LUCRO = 75.0;
```

#### Cálculo do Stop Loss

```c
double calcularStopLoss(double preco_entrada, double tipo_operacao)
{
    if(TIPO_SL == FIXO_PONTOS)
    {
        return (tipo_operacao == OP_BUY) ? 
               preco_entrada - (VALOR_SL * Point()) :
               preco_entrada + (VALOR_SL * Point());
    }
    else if(TIPO_SL == FIXO_MOEDA)
    {
        double pontos_equivalentes = pontosParaValor(VALOR_SL, Symbol());
        return (tipo_operacao == OP_BUY) ?
               preco_entrada - pontos_equivalentes :
               preco_entrada + pontos_equivalentes;
    }
    
    return 0;
}
```

---

## 🔧 REQUISITOS COMPLEMENTARES ESSENCIAIS

### Magic Number e Comment

```c
input int MAGIC_NUMBER = 12345;  // Único por EA
string EA_COMMENT = "EA_WIN_SCALPER_v1.0";

// Ao abrir ordem:
string comment = EA_COMMENT + " | " + TimeToString(TimeCurrent(), TIME_SECONDS);
OrderSend(Symbol(), cmd, lote, preco, slippage, sl, tp, comment, MAGIC_NUMBER, 0, clrGreen);
```

### Controle de Horário de Operação

```c
input bool USAR_HORARIO = true;
input string HORARIO_INICIO = "09:30";   // HH:MM
input string HORARIO_FIM = "17:00";     // HH:MM

bool dentroDoHorarioOperacional()
{
    if(!USAR_HORARIO) return true;
    
    int horaAgora = Hour();
    int minutoAgora = Minute();
    
    int horaInicio = StringToInteger(StringSubstr(HORARIO_INICIO, 0, 2));
    int minutoInicio = StringToInteger(StringSubstr(HORARIO_INICIO, 3, 2));
    
    int horaFim = StringToInteger(StringSubstr(HORARIO_FIM, 0, 2));
    int minutoFim = StringToInteger(StringSubstr(HORARIO_FIM, 3, 2));
    
    int tempoAgora = horaAgora * 100 + minutoAgora;
    int tempoInicio = horaInicio * 100 + minutoInicio;
    int tempoFim = horaFim * 100 + minutoFim;
    
    return (tempoAgora >= tempoInicio && tempoAgora <= tempoFim);
}
```

### Tratamento de Erros

```c
bool verificarConexao()
{
    if(!IsConnected())
    {
        Alert("⚠ Sem conexão com servidor");
        return false;
    }
    return true;
}

int enviarOrdemComRetry(int cmd, double lote, double preco, int slip, double sl, double tp, string comment, int magic)
{
    int tentativas = 3;
    int delay = 1000;  // ms
    
    for(int i = 0; i < tentativas; i++)
    {
        if(!IsConnected())
        {
            Sleep(delay);
            continue;
        }
        
        int ticket = OrderSend(Symbol(), cmd, lote, preco, slip, sl, tp, comment, magic, 0, clrGreen);
        
        if(ticket > 0)
            return ticket;
        
        int erro = GetLastError();
        
        if(erro == 134 || erro == 138)  // Requote
        {
            Sleep(delay);
            continue;
        }
        else if(erro == 2)  // Sem conexão
        {
            Sleep(delay);
            continue;
        }
        else
        {
            Print("Erro ao enviar ordem: " + IntegerToString(erro));
            return -1;
        }
    }
    
    return -1;  // Falhou após todas as tentativas
}
```

### Filtro de Spread

```c
input double SPREAD_MAXIMO_PONTOS = 10.0;

bool verificarSpread()
{
    double bid = Bid();
    double ask = Ask();
    double spread = ask - bid;
    double spreadPontos = spread / Point();
    
    if(spreadPontos > SPREAD_MAXIMO_PONTOS)
    {
        Print("Spread muito alto: " + DoubleToString(spreadPontos, 1) + " pontos");
        return false;
    }
    
    return true;
}
```

### Controle de Drawdown

```c
input double DRAWDOWN_MAXIMO_PERCENT = 10.0;

bool verificarDrawdown()
{
    double balance = AccountBalance();
    double equity = AccountEquity();
    double drawdown = ((balance - equity) / balance) * 100;
    
    if(drawdown > DRAWDOWN_MAXIMO_PERCENT)
    {
        bloquiarOperacoes = true;
        Alert("✗ Drawdown máximo atingido: " + DoubleToString(drawdown, 2) + "%");
        return false;
    }
    
    return true;
}
```

---

## 📝 ESTRUTURA OBRIGATÓRIA DO CÓDIGO MQ5

```c
//+------------------------------------------------------------------+
//| Nome da EA                                                       |
//| Descrição breve                                                  |
//| Versão: 1.0                                                      |
//| Autor: Nome                                                      |
//| Data: 01/07/2026                                                 |
//+------------------------------------------------------------------+

#property strict
#property version "1.0"
#property description "Descrição da EA"
#property icon "📊"

//+------ INCLUDES ------+
#include "<biblioteca_necessaria.mqh>"

//+------ INPUTS - CONTROLE ------+
input int MAGIC_NUMBER = 12345;
input string EA_COMMENT = "EA_NOME_v1.0";
input bool EA_ATIVA = true;

//+------ INPUTS - TIMEFRAME ------+
input ENUM_TIMEFRAMES TIMEFRAME_EA = PERIOD_H1;

//+------ INPUTS - GESTÃO DE RISCO ------+
input double LOTE_FIXO = 1.0;
input double RISCO_PERCENTUAL = 2.0;
input double CAPITAL_INICIAL = 10000.0;

//+------ INPUTS - STOP LOSS E GAIN ------+
input double STOP_LOSS_PONTOS = 50.0;
input double GAIN_ALVO_PONTOS = 100.0;
input bool USAR_BREAKEVEN = true;
input double PONTOS_BREAKEVEN = 30.0;

//+------ INPUTS - METAS DIÁRIAS ------+
input double META_GANHO_DIARIO = 1000.0;
input double STOP_LOSS_DIARIO = 500.0;
input bool RESET_AUTOMATICO = true;
input string HORARIO_RESET = "09:30";

//+------ INPUTS - HORÁRIOS ------+
input bool USAR_HORARIO = true;
input string HORARIO_INICIO = "09:30";
input string HORARIO_FIM = "17:00";

//+------ INPUTS - INDICADORES ------+
input bool USAR_RSI = true;
input int RSI_PERIODO = 14;
input double RSI_COMPRA = 30.0;
input double RSI_VENDA = 70.0;

//+------ INPUTS - LOGGING ------+
input bool LOGGING_ATIVO = true;
input bool LOG_POR_TICK = false;  // true = tick, false = candle

//+------ INPUTS - DASHBOARD ------+
input bool DASHBOARD_ATIVO = true;

//+------ VARIÁVEIS GLOBAIS ------+
int handleRSI;
double resultadoDia = 0;
int operacoesGanhas = 0;
int operacoesPerdidas = 0;
bool bloquiarOperacoes = false;

//+------ FUNÇÃO PRINCIPAL: OnTick ------+
void OnTick()
{
    // 1. Verificações Básicas
    if(!verificarConexao()) return;
    if(!verificarResetDiario()) return;
    if(!dentroDoHorarioOperacional()) return;
    if(!verificarDrawdown()) return;
    if(!verificarSpread()) return;
    if(bloquiarOperacoes) return;
    
    // 2. Logging (se ativo)
    if(LOGGING_ATIVO && LOG_POR_TICK)
        logarCandle();
    
    // 3. Atualizar Dashboard
    if(DASHBOARD_ATIVO)
        atualizarDashboard();
    
    // 4. Lógica da EA (sinais, entrada, saída)
    // ...
}

//+------ FUNÇÃO PRINCIPAL: OnInit ------+
int OnInit()
{
    // Criar indicadores
    handleRSI = iRSI(Symbol(), TIMEFRAME_EA, RSI_PERIODO, PRICE_CLOSE);
    
    if(handleRSI == INVALID_HANDLE)
    {
        Alert("Erro ao criar RSI");
        return INIT_FAILED;
    }
    
    // Validar inputs
    if(!validarInputs())
        return INIT_FAILED;
    
    // Inicializar logs
    criarArquivoLog();
    
    Print("EA " + EA_COMMENT + " iniciada com sucesso");
    return INIT_SUCCEEDED;
}

//+------ FUNÇÃO PRINCIPAL: OnDeinit ------+
void OnDeinit(const int reason)
{
    IndicatorRelease(handleRSI);
    Print("EA " + EA_COMMENT + " finalizada");
}

//+------ FUNÇÕES AUXILIARES ------+
// ... suas funções aqui ...
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

Antes de submeter uma EA, verifique:

- [ ] Magic Number único e definido
- [ ] Comment personalizado com nome e versão da EA
- [ ] Cálculo correto de lotes para o ativo
- [ ] Logging completo implementado
- [ ] Dashboard visual com todos os elementos
- [ ] Gestão de meta diária e stop loss diário
- [ ] Controle de horário operacional
- [ ] Tratamento de erros e reconexão
- [ ] Filtro de spread implementado
- [ ] Controle de drawdown
- [ ] Validação de inputs
- [ ] Todos os parâmetros em PORTUGUÊS-BR
- [ ] Comentários claros no código
- [ ] Testado em backtest
- [ ] Logs salvos e analisados
- [ ] Documentação atualizada

---

**Versão deste documento:** 1.0
**Última atualização:** 01/07/2026
