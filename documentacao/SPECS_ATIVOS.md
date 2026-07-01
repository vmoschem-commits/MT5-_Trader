# Especificações Técnicas dos Ativos

## 📊 B3 - Índice Futuro (WIN)

### Dados Técnicos

| Propriedade | Valor |
|-------------|-------|
| **Símbolo** | WINZ (Z = mês de expiração) |
| **Contrato** | Índice Futuro Mini |
| **Horário** | 09:30 - 17:30 (Brasília) |
| **Point** | 0.1 |
| **Tick Size** | 5 |
| **Tick Value** | R$ 5 |
| **Digits** | 1 |
| **Contract Size** | 1 |
| **Lote Mínimo** | 1 contrato |
| **Lote Máximo** | Sem limite específico |

### Fórmulas para WIN

```
Valor em Pontos = Preço * 0.1
Valor em Reais = (Pontos / 5) × R$ 5
Exemplo: 98.400 = 9.840 pontos = (9.840 / 5) × R$ 5 = R$ 9.840
```

### Características

- ✓ Spread típico: 5-10 pontos (normalmente 1 tick)
- ✓ Volatilidade: Alta durante abertura (9:30-10:00)
- ✓ Volume: Máximo 09:30-12:00 e 14:00-17:00
- ✓ Pausa para almoço: 11:55-13:00

---

## 📊 B3 - Dólar Futuro (WDO)

### Dados Técnicos

| Propriedade | Valor |
|-------------|-------|
| **Símbolo** | WDOZ (Z = mês de expiração) |
| **Contrato** | Dólar Futuro (100 USD) |
| **Horário** | 09:30 - 17:30 (Brasília) |
| **Point** | 0.0001 |
| **Tick Size** | 0.0001 |
| **Tick Value** | R$ 1 |
| **Digits** | 4 |
| **Contract Size** | 100 |
| **Lote Mínimo** | 1 contrato (100 USD) |
| **Lote Máximo** | Sem limite específico |

### Fórmulas para WDO

```
Valor em Pontos = Preço em centavos
Valor em Reais = Pontos × R$ 1
Exemplo: 5.1234 = 51.234 pontos = 51.234 × R$ 1 = R$ 51.23
```

### Características

- ✓ Spread típico: 1-3 ticks (0.0001-0.0003)
- ✓ Volatilidade: Alta em releases macroeconômicos
- ✓ Volume: Máximo durante pregão normal
- ✓ Líquido durante todo horário de funcionamento

---

## 📊 Forex - Ouro (XAUUSD)

### Dados Técnicos

| Propriedade | Valor |
|-------------|-------|
| **Símbolo** | XAUUSD |
| **Contrato** | 100 onças troy |
| **Horário** | 00:00 - 23:00 UTC (com pausas) |
| **Point** | 0.01 |
| **Tick Size** | 0.01 |
| **Tick Value** | USD variável (aprox. USD 1) |
| **Digits** | 2 |
| **Contract Size** | 100 |
| **Lote Mínimo** | 0.01 lote (1 onça) |
| **Lote Máximo** | Sem limite específico |

### Fórmulas para XAUUSD

```
Valor em Pontos = Preço × 100
Valor em USD = Pontos × 0.01
Exemplo: 2.050,50 = 205.050 pontos = 205.050 × USD 0.01 = USD 2.050,50
```

### Características

- ✓ Spread típico: 2-5 centavos (0.02-0.05)
- ✓ Volatilidade: Alta em FOMC, CPI, NFP
- ✓ Volume: 24/5 (segunda-sexta)
- ✓ Picos de atividade: Londres (08:00-12:00 UTC) e NY (13:00-21:00 UTC)

---

## 🔢 Conversão de Unidades

### De Pontos para Moeda

```c
double pontosParaMoveda(string symbol, double pontos)
{
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double contractSize = SymbolInfoInteger(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    
    return (pontos / tickSize) * tickValue * contractSize;
}
```

### De Moeda para Pontos

```c
double moedaParaPontos(string symbol, double moeda)
{
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double contractSize = SymbolInfoInteger(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    
    return (moeda * tickSize) / (tickValue * contractSize);
}
```

---

## 💰 Cálculo de Lote por Risco

### Fórmula Universal

```
Lote = (Capital × % Risco) / (Stop Loss em Pontos × Tick Value / Tick Size × Contract Size)
```

### Exemplo: WIN com Risco de 2% do Capital de R$ 10.000

```
Capital = R$ 10.000
Risco = 2% = R$ 200
Stop Loss = 50 pontos
Tick Value = R$ 5
Tick Size = 5 pontos
Contract Size = 1

Lote = (10.000 × 0.02) / (50 × (5/5) × 1)
Lote = 200 / 50
Lote = 4 contratos
```

### Exemplo: WDO com Risco de 2% do Capital de R$ 10.000

```
Capital = R$ 10.000
Risco = 2% = R$ 200
Stop Loss = 100 pontos (0.0100 em preço)
Tick Value = R$ 1
Tick Size = 0.0001 (1 ponto)
Contract Size = 100

Lote = (10.000 × 0.02) / (100 × (1/1) × 100)
Lote = 200 / 10.000
Lote = 0.02 contratos = 2 USD
```

### Exemplo: XAUUSD com Risco de 2% do Capital de USD 5.000

```
Capital = USD 5.000
Risco = 2% = USD 100
Stop Loss = 100 pontos (1.00 em preço)
Tick Value = USD ~1
Tick Size = 0.01
Contract Size = 100

Lote = (5.000 × 0.02) / (100 × (1/0.01) × 100)
Lote = 100 / 1.000.000
Lote = 0.0001 (reajustar conforme broker)
```

---

## 🎯 Horários Importantes

### B3 (Brasília - UTC-3 ou UTC-2)

| Período | Horário |
|---------|----------|
| Abertura | 09:30 |
| Pausa Almoço | 11:55 - 13:00 |
| Encerramento | 17:30 |
| Pré-Abertura | 09:00 - 09:25 |

### Forex - XAUUSD (UTC)

| Sessão | Horário UTC | Horário BRT (UTC-3) |
|--------|-------------|--------------------|
| Ásia | 22:00 - 06:00 | 19:00 - 03:00 |
| Londres | 08:00 - 16:00 | 05:00 - 13:00 |
| NY | 13:00 - 21:00 | 10:00 - 18:00 |

---

## 📈 Volatilidade Esperada

### WIN
- Segundas e sextas: 10-20% maior volatilidade
- Abertura (09:30-10:00): +50% volatilidade
- Almoço (11:55-13:00): Reduzida
- Final do dia (16:30-17:30): +30% volatilidade

### WDO
- Reage fortemente a dados econômicos
- CPI, FOMC: +100% volatilidade
- Risco geopolítico: +200% volatilidade
- Horário NY: Máxima atividade

### XAUUSD
- FOMC Decision: +500% volatilidade
- CPI/PPI: +300% volatilidade
- NFP: +200% volatilidade
- Abertura Londres: +100% volatilidade

---

**Última atualização:** 01/07/2026
