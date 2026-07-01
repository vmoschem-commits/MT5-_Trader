# MT5 Expert Advisors (EAs) - Ambiente de Desenvolvimento

Espaço dedicado ao desenvolvimento de **Expert Advisors profissionais para MetaTrader 5** com foco em operações nos mercados **B3 (WIN, WDO)** e **Forex (XAUUSD)**.

## 🎯 Objetivo

Criar EAs robustas, seguras e rastreáveis que atendem aos mais altos padrões profissionais de gestão de risco, logging e operação automatizada.

## 📁 Estrutura do Repositório

```
MT5-_Trader/
├── README.md
├── PADROES.md                          # Padrões e requisitos obrigatórios
├── CHANGELOG.md
│
├── 📁 templates/
│   ├── EA_Template_Basico.mq5          # Template básico com toda estrutura
│   ├── bibliotecas/
│   │   ├── Risk_Management.mqh         # Gestão de risco e lotes
│   │   ├── Market_Data.mqh             # Cálculo de ticks/pontos/valores
│   │   ├── Order_Management.mqh        # Gerenciamento de operações
│   │   ├── Dashboard.mqh               # Painel visual
│   │   ├── Logger.mqh                  # Sistema de logs
│   │   ├── Time_Manager.mqh            # Controle de horários
│   │   ├── Notification.mqh            # Notificações e alertas
│   │   └── Error_Handler.mqh           # Tratamento de erros
│   └── parametros_exemplo.txt          # Presets de configuração
│
├── 📁 EAs_Ativos/
│   ├── 📁 WIN/                         # Expert Advisors para WIN
│   │   ├── EA_WIN_Exemplo_v1.0.mq5
│   │   └── historico_testes.txt
│   ├── 📁 WDO/                         # Expert Advisors para WDO
│   │   ├── EA_WDO_Exemplo_v1.0.mq5
│   │   └── historico_testes.txt
│   └── 📁 XAUUSD/                      # Expert Advisors para OURO
│       ├── EA_OURO_Exemplo_v1.0.mq5
│       └── historico_testes.txt
│
├── 📁 logs/
│   ├── EA_WIN_20260701.log             # Logs organizados por data
│   ├── EA_WDO_20260701.log
│   └── EA_OURO_20260701.log
│
├── 📁 analise_e_testes/
│   ├── planilha_backtest.xlsx          # Análise de backtests
│   ├── relatorio_performance.txt       # Relatórios de performance
│   └── testes_de_stress.txt            # Testes de estresse
│
├── 📁 documentacao/
│   ├── SPECS_ATIVOS.md                 # Especificações (Points, Ticks, Values)
│   ├── GUIA_IMPLEMENTACAO.md           # Como implementar uma nova EA
│   ├── GUIA_DASHBOARD.md               # Documentação do painel
│   └── TROUBLESHOOTING.md              # Resolução de problemas
│
└── 📁 scripts_auxiliares/
    ├── converter_logs.py                # Converter logs para CSV
    └── gerar_relatorio.py              # Gerar relatórios automáticos
```

## ✅ Critérios Obrigatórios (Core)

Toda EA desenvolvida **DEVE** atender aos seguintes requisitos:

### 1️⃣ Cálculo Correto de Ticks e Valores
- ✓ Suporte B3: WIN, WDO (respeitar Point, Tick Size, Tick Value)
- ✓ Suporte Forex: XAUUSD
- ✓ Cálculo automático de lotes em função do capital
- ✓ Conversão correta entre pontos e moeda

### 2️⃣ Logging Completo (Candle a Candle ou Tick)
- ✓ Abertura, fechamento, alta, baixa, volume
- ✓ Sinais de entrada/saída
- ✓ Valores de todos os indicadores
- ✓ Resultado por operação (gains/losses em pontos e moeda)
- ✓ Equity, Balance, Drawdown
- ✓ Registro de erros e exceções

### 3️⃣ Dashboard Visual Obrigatório
- ✓ Botões: Ligar/Desligar, Zerar, Breakeven, Fechar Todas
- ✓ Resultado Fechado (dia)
- ✓ Resultado Flutuante (floating)
- ✓ Total do Dia (líquido)
- ✓ Contador: Gains / Losses / Operações
- ✓ Meta de Ganho e Stop Loss Diário com alerta visual
- ✓ Status da EA (Ligada/Desligada)
- ✓ Horário do Servidor

### 4️⃣ Gestão Financeira Diária
- ✓ Meta de ganho diário (em moeda)
- ✓ Stop Loss Diário (em moeda)
- ✓ Bloqueio automático ao atingir meta ou stop
- ✓ Reset automático configurável

### 5️⃣ Gestão por Operação
- ✓ Gain e Stop Loss fixo (pontos ou moeda)
- ✓ Breakeven automático
- ✓ Trailing Stop
- ✓ Fechamento Parcial
- ✓ Modo pontos OU moeda (configurável)

## 🔧 Critérios Complementares Essenciais

- ✓ Magic Number único + Comment personalizado
- ✓ Controle de horário operacional (por dia da semana)
- ✓ Candles com cores padrão (verde/vermelho)
- ✓ Gestão de risco por operação (fixo, %, ou moeda)
- ✓ Máximo de operações simultâneas
- ✓ Tratamento de erros e reconexão automática
- ✓ Filtro de Spread máximo
- ✓ Controle de Drawdown máximo
- ✓ Fechamento automático ao final do dia
- ✓ Validação de inputs
- ✓ Proteção contra múltiplas instâncias
- ✓ Todos os parâmetros externados em PORTUGUÊS-BR
- ✓ Modo visual para backtest (setas, comentários)
- ✓ Notificações (push, alertas sonoros)

## 🚀 Como Começar

### 1. Leia os Padrões
```
→ Abra: PADROES.md
→ Entenda os requisitos específicos por ativo
```

### 2. Use o Template
```
→ Copie: templates/EA_Template_Basico.mq5
→ Renomeie para seu EA
→ Siga a estrutura comentada
```

### 3. Implemente as Bibliotecas
```
→ Use as .mqh da pasta templates/bibliotecas/
→ Elas já implementam os requisitos obrigatórios
```

### 4. Organize na Pasta Correta
```
→ EA_WIN_SeuNome_v1.0.mq5 → EAs_Ativos/WIN/
→ EA_WDO_SeuNome_v1.0.mq5 → EAs_Ativos/WDO/
→ EA_OURO_SeuNome_v1.0.mq5 → EAs_Ativos/XAUUSD/
```

### 5. Teste e Documente
```
→ Backtest a EA
→ Salve os logs em: logs/
→ Documente resultados em: analise_e_testes/
```

## 📊 Ativos Suportados

### B3 (Bovespa)
- **WIN** - Índice Futuro Mini
  - Point: 0.1, Tick Size: 5, Tick Value: R$ 5, Digits: 1
  - Contract Size: 1

- **WDO** - Dólar Futuro
  - Point: 0.0001, Tick Size: 0.0001, Tick Value: R$ 1, Digits: 4
  - Contract Size: 100

### Forex
- **XAUUSD** - Ouro
  - Point: 0.01, Tick Size: 0.01, Tick Value: USD variável, Digits: 2
  - Contract Size: 100

## 📝 Documentação

- [Padrões Obrigatórios](./PADROES.md)
- [Especificações dos Ativos](./documentacao/SPECS_ATIVOS.md)
- [Guia de Implementação](./documentacao/GUIA_IMPLEMENTACAO.md)
- [Documentação do Dashboard](./documentacao/GUIA_DASHBOARD.md)
- [Troubleshooting](./documentacao/TROUBLESHOOTING.md)
- [Changelog](./CHANGELOG.md)

## 🔐 Segurança

- Todas as EAs devem ter Magic Number único
- Comment personalizado para identificação
- Proteção contra múltiplas instâncias
- Validação de inputs configuráveis
- Tratamento robusto de erros

## 📞 Suporte

Este é um ambiente profissional de desenvolvimento. Siga os padrões estabelecidos e documente todas as implementações.

**Última atualização:** 01/07/2026
