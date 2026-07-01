//+------------------------------------------------------------------+
//| Biblioteca de Dashboard para EA SAR + Bollinger                  |
//| Versão: 1.0                                                      |
//| Data: 01/07/2026                                                 |
//+------------------------------------------------------------------+

#ifndef __DASHBOARD_SAR_BB_MQH__
#define __DASHBOARD_SAR_BB_MQH__

//+------ CLASSE DE DASHBOARD ------+
class DashboardManager
{
private:
    bool dashboard_ativo;
    int largura;
    int altura;
    color cor_fundo;
    color cor_texto;
    color cor_ganho;
    color cor_perda;
    
public:
    DashboardManager();
    ~DashboardManager();
    
    bool Inicializar(bool ativo = true);
    
    void AtualizarDashboard(string symbol, ENUM_TIMEFRAMES tf,
                            double resultado_dia, int operacoes_ganhas, int operacoes_perdidas,
                            int total_operacoes, double resultado_flutuante,
                            double meta_ganho, double stop_loss_dia,
                            bool ea_ativa, string ultima_operacao,
                            IndicatorData &dados, string versao_ea);
    
    void Desenhar();
    void Limpar();
};

//+------ CONSTRUTOR ------+
DashboardManager::DashboardManager()
{
    dashboard_ativo = true;
    largura = 600;
    altura = 400;
    cor_fundo = clrDarkSlateGray;
    cor_texto = clrWhiteSmoke;
    cor_ganho = clrLimeGreen;
    cor_perda = clrCrimson;
}

//+------ DESTRUTOR ------+
DashboardManager::~DashboardManager()
{
    Limpar();
}

//+------ INICIALIZAR DASHBOARD ------+
bool DashboardManager::Inicializar(bool ativo)
{
    dashboard_ativo = ativo;
    if(!dashboard_ativo)
        return true;
    
    // Criar objeto rectangle para fundo
    string nome_rect = "painel_fundo";
    ObjectCreate(0, nome_rect, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, nome_rect, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, nome_rect, OBJPROP_YDISTANCE, 10);
    ObjectSetInteger(0, nome_rect, OBJPROP_XSIZE, largura);
    ObjectSetInteger(0, nome_rect, OBJPROP_YSIZE, altura);
    ObjectSetInteger(0, nome_rect, OBJPROP_BGCOLOR, cor_fundo);
    ObjectSetInteger(0, nome_rect, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, nome_rect, OBJPROP_STATE, false);
    ObjectSetInteger(0, nome_rect, OBJPROP_HIDDEN, true);
    
    return true;
}

//+------ ATUALIZAR DASHBOARD ------+
void DashboardManager::AtualizarDashboard(string symbol, ENUM_TIMEFRAMES tf,
                                          double resultado_dia, int operacoes_ganhas, int operacoes_perdidas,
                                          int total_operacoes, double resultado_flutuante,
                                          double meta_ganho, double stop_loss_dia,
                                          bool ea_ativa, string ultima_operacao,
                                          IndicatorData &dados, string versao_ea)
{
    if(!dashboard_ativo)
        return;
    
    // Calcular posições
    int x_inicio = 20;
    int y_pos = 30;
    int y_espacamento = 25;
    
    // Limpar textos antigos
    for(int i = 0; i < 50; i++)
    {
        string obj_name = "dashboard_text_" + IntegerToString(i);
        if(ObjectFind(0, obj_name) >= 0)
            ObjectDelete(0, obj_name);
    }
    
    int linha = 0;
    
    // Título
    string titulo = "╔══════════════════════════════════════╗";
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, titulo);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_texto);
    linha++;
    
    // Status e Informações
    string status_ea = ea_ativa ? "[LIGADA]" : "[DESLIGADA]";
    color cor_status = ea_ativa ? cor_ganho : cor_perda;
    
    string info_linha = "   EA: SAR+BB v" + versao_ea + " | Status: " + status_ea;
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, info_linha);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_status);
    linha++;
    
    // Ativo e Timeframe
    string ativo_tf = "   Ativo: " + symbol + " | TF: " + EnumToString(tf);
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, ativo_tf);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_texto);
    linha++;
    
    // Linha separadora
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, "   ═════════════════════════════════════");
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_texto);
    linha++;
    
    // Resultado do Dia
    color cor_resultado = (resultado_dia >= 0) ? cor_ganho : cor_perda;
    string resultado_str = "   Resultado Dia: R$ " + DoubleToString(resultado_dia, 2);
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, resultado_str);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_resultado);
    linha++;
    
    // Resultado Flutuante
    color cor_flutuante = (resultado_flutuante >= 0) ? cor_ganho : cor_perda;
    string flutuante_str = "   Em Aberto: R$ " + DoubleToString(resultado_flutuante, 2);
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, flutuante_str);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_flutuante);
    linha++;
    
    // Estatísticas
    string stats = "   Operações: " + IntegerToString(total_operacoes) + " | Ganhos: " + IntegerToString(operacoes_ganhas) + " | Perdas: " + IntegerToString(operacoes_perdidas);
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, stats);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_texto);
    linha++;
    
    // Taxa de acerto
    double win_rate = (total_operacoes > 0) ? (operacoes_ganhas * 100.0 / total_operacoes) : 0;
    string winrate_str = "   Win Rate: " + DoubleToString(win_rate, 2) + "%";
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, winrate_str);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_texto);
    linha++;
    
    // Metas
    string meta_str = "   Meta de Ganho: R$ " + DoubleToString(meta_ganho, 2) + " | Stop: R$ " + DoubleToString(stop_loss_dia, 2);
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, meta_str);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_texto);
    linha++;
    
    // Indicadores
    string sar_direcao = dados.sar_subindo ? "SUBINDO" : "DESCENDO";
    string bb_direcao = dados.bb_media_subindo ? "SUBINDO" : "DESCENDO";
    string ind_str = "   SAR: " + sar_direcao + " " + DoubleToString(dados.sar_atual, 5) + " | BB: " + bb_direcao;
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, ind_str);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_texto);
    linha++;
    
    // Hora do Servidor
    string hora_servidor = "   Hora: " + TimeToString(TimeCurrent(), TIME_SECONDS);
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, hora_servidor);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_texto);
    linha++;
    
    // Última operação
    string ultima_op_str = "   Última Op: " + ultima_operacao;
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, ultima_op_str);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_texto);
    linha++;
    
    // Rodapé
    ObjectCreate(0, "dashboard_text_" + IntegerToString(linha), OBJ_TEXT, 0, TimeCurrent(), 0);
    ObjectSetString(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_TEXT, "╚══════════════════════════════════════╝");
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_XDISTANCE, x_inicio);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_YDISTANCE, y_pos + linha * y_espacamento);
    ObjectSetInteger(0, "dashboard_text_" + IntegerToString(linha), OBJPROP_COLOR, cor_texto);
}

//+------ LIMPAR DASHBOARD ------+
void DashboardManager::Limpar()
{
    for(int i = 0; i < 100; i++)
    {
        string obj_name = "dashboard_text_" + IntegerToString(i);
        if(ObjectFind(0, obj_name) >= 0)
            ObjectDelete(0, obj_name);
    }
    
    if(ObjectFind(0, "painel_fundo") >= 0)
        ObjectDelete(0, "painel_fundo");
}

#endif
