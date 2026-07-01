//+------------------------------------------------------------------+
//| Biblioteca de Logging para EA SAR + Bollinger                    |
//| Versão: 1.0                                                      |
//| Data: 01/07/2026                                                 |
//+------------------------------------------------------------------+

#ifndef __LOGGER_SAR_BB_MQH__
#define __LOGGER_SAR_BB_MQH__

//+------ CLASSE DE LOGGING ------+
class LoggerManager
{
private:
    string nome_arquivo;
    bool logging_ativo;
    
public:
    LoggerManager();
    ~LoggerManager();
    
    bool Inicializar(string symbol, ENUM_TIMEFRAMES tf, bool ativo = true);
    
    void LogarCandle(string symbol, ENUM_TIMEFRAMES tf, 
                     IndicatorData &dados,
                     double close, double open, double high, double low, long volume);
    
    void LogarOperacao(string tipo_operacao, double preco_entrada, double volume, 
                       double preço_saida, double resultado_pontos, double resultado_moeda,
                       double balance, double equity, double drawdown);
    
    void LogarErro(string descricao_erro, string contexto);
    
    void LogarSinal(string tipo_sinal, IndicatorData &dados);
    
    string ObterCaminhoArquivo() { return nome_arquivo; }
};

//+------ CONSTRUTOR ------+
LoggerManager::LoggerManager()
{
    nome_arquivo = "";
    logging_ativo = true;
}

//+------ DESTRUTOR ------+
LoggerManager::~LoggerManager()
{
}

//+------ INICIALIZAR LOGGER ------+
bool LoggerManager::Inicializar(string symbol, ENUM_TIMEFRAMES tf, bool ativo)
{
    logging_ativo = ativo;
    
    if(!logging_ativo)
        return true;
    
    // Criar nome do arquivo de log
    string data = TimeToString(TimeCurrent(), TIME_DATE);
    string timeframe_str = "";
    
    switch(tf)
    {
        case PERIOD_M5:  timeframe_str = "M5"; break;
        case PERIOD_M15: timeframe_str = "M15"; break;
        case PERIOD_M30: timeframe_str = "M30"; break;
        case PERIOD_H1:  timeframe_str = "H1"; break;
        default:         timeframe_str = "TX"; break;
    }
    
    nome_arquivo = "Logs/\\EA_SAR_BB_" + symbol + "_" + timeframe_str + "_" + data + ".log";
    
    // Criar cabeçalho do arquivo
    int handle = FileOpen(nome_arquivo, FILE_READ|FILE_WRITE|FILE_TXT);
    if(handle != INVALID_HANDLE)
    {
        FileSeek(handle, 0, SEEK_END);
        FileWriteString(handle, "="*100 + "\n");
        FileWriteString(handle, "EA: SAR Parabólico + Bandas de Bollinger\n");
        FileWriteString(handle, "Ativo: " + symbol + " | Timeframe: " + timeframe_str + "\n");
        FileWriteString(handle, "Data de Início: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\n");
        FileWriteString(handle, "="*100 + "\n\n");
        FileClose(handle);
    }
    
    Print("[OK] Logger inicializado: " + nome_arquivo);
    return true;
}

//+------ LOGAR CANDLE ------+
void LoggerManager::LogarCandle(string symbol, ENUM_TIMEFRAMES tf,
                                IndicatorData &dados,
                                double close, double open, double high, double low, long volume)
{
    if(!logging_ativo)
        return;
    
    int handle = FileOpen(nome_arquivo, FILE_READ|FILE_WRITE|FILE_TXT);
    if(handle == INVALID_HANDLE)
        return;
    
    FileSeek(handle, 0, SEEK_END);
    
    // Formatar dados da candle
    string tempo = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
    string log_linha = "[" + tempo + "] ";
    log_linha += "OPEN:" + DoubleToString(open, Digits()) + " | ";
    log_linha += "HIGH:" + DoubleToString(high, Digits()) + " | ";
    log_linha += "LOW:" + DoubleToString(low, Digits()) + " | ";
    log_linha += "CLOSE:" + DoubleToString(close, Digits()) + " | ";
    log_linha += "VOL:" + IntegerToString(volume) + " | ";
    log_linha += "SAR:" + DoubleToString(dados.sar_atual, 5) + " | ";
    log_linha += "BB_SUP:" + DoubleToString(dados.bb_superior, Digits()) + " | ";
    log_linha += "BB_MED:" + DoubleToString(dados.bb_media, Digits()) + " | ";
    log_linha += "BB_INF:" + DoubleToString(dados.bb_inferior, Digits());
    
    FileWriteString(handle, log_linha + "\n");
    FileClose(handle);
}

//+------ LOGAR OPERAÇÃO ------+
void LoggerManager::LogarOperacao(string tipo_operacao, double preco_entrada, double volume,
                                   double preco_saida, double resultado_pontos, double resultado_moeda,
                                   double balance, double equity, double drawdown)
{
    if(!logging_ativo)
        return;
    
    int handle = FileOpen(nome_arquivo, FILE_READ|FILE_WRITE|FILE_TXT);
    if(handle == INVALID_HANDLE)
        return;
    
    FileSeek(handle, 0, SEEK_END);
    
    string tempo = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
    string cor_resultado = (resultado_moeda >= 0) ? "[+]" : "[-]";
    
    string log_linha = "\n*** OPERAÇÃO FECHADA *** [" + tempo + "]\n";
    log_linha += "Tipo: " + tipo_operacao + "\n";
    log_linha += "Entrada: " + DoubleToString(preco_entrada, Digits()) + " | Volume: " + DoubleToString(volume, 2) + "\n";
    log_linha += "Saída: " + DoubleToString(preco_saida, Digits()) + "\n";
    log_linha += "Resultado: " + cor_resultado + " " + DoubleToString(resultado_pontos, 0) + " pontos = R$ " + DoubleToString(resultado_moeda, 2) + "\n";
    log_linha += "Balance: R$ " + DoubleToString(balance, 2) + " | Equity: R$ " + DoubleToString(equity, 2) + " | DD: " + DoubleToString(drawdown, 2) + "%\n";
    log_linha += "="*80 + "\n";
    
    FileWriteString(handle, log_linha);
    FileClose(handle);
}

//+------ LOGAR ERRO ------+
void LoggerManager::LogarErro(string descricao_erro, string contexto)
{
    if(!logging_ativo)
        return;
    
    int handle = FileOpen(nome_arquivo, FILE_READ|FILE_WRITE|FILE_TXT);
    if(handle == INVALID_HANDLE)
        return;
    
    FileSeek(handle, 0, SEEK_END);
    
    string tempo = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
    string log_linha = "\n[ERRO] [" + tempo + "] " + descricao_erro + " | Contexto: " + contexto + "\n";
    
    FileWriteString(handle, log_linha);
    FileClose(handle);
}

//+------ LOGAR SINAL ------+
void LoggerManager::LogarSinal(string tipo_sinal, IndicatorData &dados)
{
    if(!logging_ativo)
        return;
    
    int handle = FileOpen(nome_arquivo, FILE_READ|FILE_WRITE|FILE_TXT);
    if(handle == INVALID_HANDLE)
        return;
    
    FileSeek(handle, 0, SEEK_END);
    
    string tempo = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
    string direcao = (tipo_sinal == "COMPRA") ? "[SINAL DE COMPRA] " : "[SINAL DE VENDA] ";
    
    string log_linha = "\n" + direcao + "[" + tempo + "]\n";
    log_linha += "SAR: " + (dados.sar_subindo ? "SUBINDO" : "DESCENDO") + " | ";
    log_linha += "BB Média: " + (dados.bb_media_subindo ? "SUBINDO" : "DESCENDO") + "\n";
    
    FileWriteString(handle, log_linha);
    FileClose(handle);
}

#endif
