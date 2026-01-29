# Arquitetura do Sistema

## Visão Geral

```
┌─────────────────────────────────────────────────────────────────┐
│                    Cliente HTTP (Você)                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                    POST /cep
                    {cep: "XXXXXXXX"}
                         │
                         ▼
        ┌────────────────────────────┐
        │   Service A (8080)         │
        │   Valida & Roteia          │
        └────────┬───────────────────┘
                 │
            Validação
            ├─ 8 dígitos? ✓
            ├─ É string? ✓
            └─ Manda pra B
                 │
                 │  HTTP POST /weather
                 │  {cep: "XXXXXXXX"}
                 │
                 ▼
        ┌────────────────────────────┐
        │   Service B (8081)         │
        │   Busca & Converte         │
        └────┬───────────────────┬───┘
             │                   │
             │                   │
        GET  |                   | GET
            |                   |
    ┌───────▼──────┐  ┌────────▼────────┐
    │  viaCEP API  │  │  WeatherAPI     │
    │  Busca CEP   │  │  Pega Temp      │
    │              │  │                 │
    │ (Localidade) │  │ (temp_c)        │
    └──────┬───────┘  └────────┬────────┘
           │                   │
           └───────┬───────────┘
                   │
        Converte Temperatura
        ├─ F = C * 1.8 + 32
        └─ K = C + 273
                   │
                   ▼
        Response:
        {
          city: "São Paulo",
          temp_C: 28.5,
          temp_F: 83.3,
          temp_K: 301.65
        }
                   │
                   ▼
        ┌────────────────────────────┐
        │    Cliente HTTP (Você)     │
        └────────────────────────────┘
```

## Fluxo com Observabilidade

```
┌──────────────────────────────────────────────────────────┐
│    Instrumentação com OpenTelemetry                      │
└──────┬───────────────────────────────────────────────────┘
       │
       ├─ Tracer Provider
       │  ├─ Service A Tracer
       │  └─ Service B Tracer
       │
       ├─ Exporters
       │  └─ OTLP HTTP (→ otel-collector:4318)
       │
       └─ Spans
          ├─ handleCEP (Service A)
          ├─ callServiceB (Service A)
          ├─ handleWeather (Service B)
          ├─ lookupCEP (Service B)
          └─ getTemperature (Service B)
          
                 ▼
        ┌────────────────────────┐
        │  OTEL Collector (4318) │
        │  (otel-collector)      │
        │                        │
        │ Receivers: OTLP HTTP   │
        │ Processors: Batch      │
        │ Exporters: Zipkin      │
        └────────┬───────────────┘
                 │
                 ▼
        ┌────────────────────────┐
        │   Zipkin (9411)        │
        │   Armazenamento: Memory│
        │   UI: Interface Web    │
        └────────────────────────┘
```

## Componentes Detalhados

### Service A: Input Handler

```
┌─────────────────────────────────┐
│      Service A (Port 8080)      │
├─────────────────────────────────┤
│                                 │
│  HTTP Server                    │
│  ├─ POST /cep                   │
│  │  ├─ Decode JSON              │
│  │  ├─ Validate (8 digits)      │
│  │  ├─ [Create Span]            │
│  │  ├─ Call Service B           │
│  │  │  └─ [Create HTTP Span]    │
│  │  └─ Return Response           │
│  │                              │
│  ├─ GET /health                 │
│  │  └─ Return 200 OK            │
│  │                              │
│  └─ [OTEL Tracer]               │
│     └─ Export to Collector      │
│                                 │
└─────────────────────────────────┘
```

**Principais Funções:**
- `main()`: Inicializa tracer e inicia servidor
- `initTracer()`: Configura OTEL exporter
- `handleCEP()`: Processa requisição POST
- `validateCEP()`: Valida formato do CEP
- `callServiceB()`: Chamada HTTP para Service B

### Service B: Orchestration

```
┌─────────────────────────────────┐
│      Service B (Port 8081)      │
├─────────────────────────────────┤
│                                 │
│  HTTP Server                    │
│  ├─ POST /weather               │
│  │  ├─ Decode JSON              │
│  │  ├─ [Create Span]            │
│  │  │                           │
│  │  ├─ lookupCEP()              │
│  │  │  ├─ [Create Span]         │
│  │  │  ├─ Call viaCEP API       │
│  │  │  └─ Return City           │
│  │  │                           │
│  │  ├─ getTemperature()         │
│  │  │  ├─ [Create Span]         │
│  │  │  ├─ Call WeatherAPI       │
│  │  │  └─ Return Temp (Celsius) │
│  │  │                           │
│  │  ├─ convertTemperatures()    │
│  │  │  ├─ Calculate Fahrenheit  │
│  │  │  └─ Calculate Kelvin      │
│  │  │                           │
│  │  └─ Return JSON Response     │
│  │                              │
│  ├─ GET /health                 │
│  │  └─ Return 200 OK            │
│  │                              │
│  └─ [OTEL Instrumentation]      │
│     ├─ Tracer                   │
│     └─ HTTP Instrumentation     │
│                                 │
└─────────────────────────────────┘
```

**Principais Funções:**
- `main()`: Inicializa tracer e inicia servidor
- `initTracer()`: Configura OTEL exporter
- `handleWeather()`: Processa requisição POST
- `lookupCEP()`: Consulta viaCEP API
- `getTemperature()`: Consulta WeatherAPI
- `convertTemperatures()`: Converte temperaturas

### Infrastructure Components

#### OTEL Collector
```
Collectors (4317/gRPC, 4318/HTTP)
         │
    ┌────┴─────┐
    │ Processors│
    │ - Batch  │
    │ - Memory │
    └────┬─────┘
         │
    ┌────┴─────────┐
    │ Exporters    │
    ├─ Logging     │
    └─ Zipkin API  │
```

#### Zipkin
```
Web UI (port 9411)
├─ Search Traces
├─ Service Dependencies
├─ Latency Analysis
└─ Error Tracking
```

## Fluxo de Requisição Completo

1. **Cliente** → Service A POST /cep
2. Service A:
   - Cria span "handleCEP"
   - Valida CEP
   - Cria span "callServiceB"
   - Faz requisição HTTP para Service B
   - Encerra spans
   - Retorna response
3. Service B:
   - Cria span "handleWeather"
   - Cria span "lookupCEP"
   - Faz requisição para viaCEP
   - Encerra span "lookupCEP"
   - Cria span "getTemperature"
   - Faz requisição para WeatherAPI
   - Encerra span "getTemperature"
   - Converte temperaturas
   - Encerra span "handleWeather"
   - Retorna response JSON
4. Service A encaminha response para cliente
5. **OTEL Exporters** enviam spans para Collector
6. **Collector** exporta para Zipkin
7. **Zipkin** armazena traces para análise

## Spans Implementados

### Service A
```
Trace ID: abc123...
├─ Span: handleCEP (root)
│  ├─ Timestamp: 2024-01-15T10:30:00Z
│  ├─ Duration: 150ms
│  └─ Events:
│     └─ CEP validation: success
│
│  └─ Span: callServiceB (child)
│     ├─ Timestamp: 2024-01-15T10:30:00.050Z
│     ├─ Duration: 100ms
│     └─ Attributes:
│        ├─ http.method: POST
│        ├─ http.url: http://service-b:8081/weather
│        └─ http.status_code: 200
```

### Service B
```
Trace ID: abc123... (propagado do Service A)
├─ Span: handleWeather (root)
│  ├─ Duration: 100ms
│  │
│  ├─ Span: lookupCEP (child)
│  │  ├─ Duration: 50ms
│  │  └─ Attributes:
│  │     ├─ cep: "01310100"
│  │     └─ city: "São Paulo"
│  │
│  └─ Span: getTemperature (child)
│     ├─ Duration: 40ms
│     └─ Attributes:
│        ├─ city: "São Paulo"
│        └─ temp_celsius: 28.5
```

## Tratamento de Erros

```
Erro no CEP?
├─ Formato inválido
│  └─ HTTP 422 + "invalid zipcode"
│
├─ CEP não encontrado
│  ├─ Service A: Encaminha para B
│  └─ Service B: HTTP 404 + "can not find zipcode"
│
└─ Erro na API de temperatura
   └─ Service B: HTTP 500 + "failed to get temperature"
```

## Escalabilidade e Performance

### Pontos de Otimização

1. **Caching**
   - Cache de CEPs/cidades
   - Cache de temperaturas (TTL: 5-15 min)

2. **Connection Pooling**
   - Reutilizar conexões HTTP
   - Connection persistence

3. **Rate Limiting**
   - Limitar requisições por cliente
   - Proteger APIs externas

4. **Async Processing**
   - Fila de requisições
   - Background jobs

### Métricas Coletadas

- Latência P50, P95, P99
- Taxa de sucesso/erro
- Throughput (req/s)
- Tempo gasto em cada serviço
- Tempo gasto em APIs externas

## Segurança

### Validação de Input
- CEP: 8 dígitos apenas
- Type checking: string
- Length validation

### API Keys
- Armazenadas em environment variables
- Nunca em logs
- Rotação periódica

### Network
- Containers em rede isolada
- Service-to-service communication
- No external exposure desnecessário

## Conclusão

Este sistema demonstra uma arquitetura de microserviços robusta com:
- Validação de entrada rigorosa
- Orquestração clara de serviços
- Rastreamento distribuído completo
- Tratamento de erros apropriado
- Escalabilidade e observabilidade
