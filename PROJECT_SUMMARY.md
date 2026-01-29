# Resumo do Projeto

## Sistema de Temperatura por CEP com OpenTelemetry e Zipkin

### 📦 Tudo Pronto para Usar

Essa é uma implementação completa e pronta pra produção de um sistema distribuído de busca de temperatura feito em Go com tracing OpenTelemetry e visualização no Zipkin.

---

## ✅ Estrutura do Projeto

```
observability_openTelemetry/
│
├── 📄 Documentação
│   ├── README.md                 # Documentação principal
│   ├── QUICKSTART.md             # Guia rápido de 5 minutos
│   ├── API.md                    # Referência das APIs
│   ├── ARCHITECTURE.md           # Design do sistema
│   ├── DEVELOPMENT.md            # Guia de desenvolvimento
│   └── TROUBLESHOOTING.md        # Problemas comuns e soluções
│
├── 🐳 Configuração Docker
│   ├── docker-compose.yml        # Orquestração de todos os serviços
│   ├── otel-collector-config.yml # Configuração do OTEL Collector
│   ├── service-a/Dockerfile      # Imagem do Service A
│   └── service-b/Dockerfile      # Imagem do Service B
│
├── 🔧 Service A (Validador de Entrada)
│   ├── service-a/main.go         # Implementação do Service A
│   ├── service-a/go.mod          # Definição do módulo Go
│   └── service-a/go.sum          # Lock das dependências
│
├── 🔧 Service B (Orquestração)
│   ├── service-b/main.go         # Implementação do Service B
│   ├── service-b/go.mod          # Definição do módulo Go
│   └── service-b/go.sum          # Lock das dependências
│
├── 🚀 Scripts de Execução
│   ├── start.sh                  # Inicia todos os serviços
│   ├── stop.sh                   # Para todos os serviços
│   └── test.sh                   # Roda a suite de testes
│
└── ⚙️  Configuração
    ├── .env                      # Variáveis de ambiente
    └── .gitignore               # Regras do git ignore
```

---

## 🎯 Funcionalidades Implementadas

### Service A (Porta 8080)
✅ **Validação de Entrada**
- Valida o formato do CEP (exatamente 8 dígitos, tipo string)
- Retorna HTTP 422 pra entrada inválida
- Retorna HTTP 400 pra JSON malformado

✅ **Roteamento HTTP**
- Endpoint POST /cep pra submeter CEP
- Endpoint GET /health pra health check
- Encaminha CEP válido pro Service B

✅ **Integração OpenTelemetry**
- Spans de tracing pra manipulação de CEP
- Spans de tracing pras chamadas HTTP ao Service B
- Propagação automática de contexto de trace

### Service B (Porta 8081)
✅ **Busca de CEP**
- Integração com a API viaCEP
- Retorna nome da cidade pra CEP válido
- Retorna HTTP 404 pra CEP que não existe

✅ **Recuperação de Temperatura**
- Integração com WeatherAPI
- Busca a temperatura atual em Celsius
- Converte pra Fahrenheit (F = C × 1.8 + 32)
- Converte pra Kelvin (K = C + 273)

✅ **Formatação de Resposta**
- Retorna JSON com nome da cidade e todas as escalas de temperatura
- Códigos HTTP apropriados pra todos os cenários
- Mensagens de erro como especificado

✅ **Instrumentação OpenTelemetry**
- Spans de tracing pra cada operação maior
- HTTP clients instrumentados pras APIs externas
- Medição de performance de todas as operações

### Observabilidade
✅ **OpenTelemetry Collector**
- Receiver HTTP OTLP na porta 4318
- Processamento em lote dos traces
- Limitação de memória pra estabilidade

✅ **Integração Zipkin**
- Recebe traces do OTEL Collector
- UI web na porta 9411
- Visualização e análise de traces
- Grafo de dependências dos serviços
- Análise de latência

---

## 🏗️  Architecture Highlights

### Service Communication
```
Client → Service A (validation)
       → Service B (lookup + conversion)
       → External APIs (viaCEP, WeatherAPI)
```

### Trace Flow
```
Request enters Service A
→ Span created: handleCEP
→ Span created: callServiceB
  → HTTP request to Service B (trace context propagated)
  → Span created: handleWeather (child of handleCEP)
  → Span created: lookupCEP
    → HTTP call to viaCEP
  → Span created: getTemperature
    → HTTP call to WeatherAPI
  → Response returned with all temperatures
→ OTEL exporters send all spans to Collector
→ Collector sends to Zipkin for visualization
```

---

## 🔧 Stack de Tecnologias

| Componente | Tecnologia | Versão |
|-----------|-----------|------|
| Linguagem | Go | 1.21 |
| Framework HTTP | Standard library | net/http |
| Observabilidade | OpenTelemetry | v1.21.0 |
| Coleção de Traces | OTEL Collector | 0.88.0 |
| Visualização de Traces | Zipkin | Última |
| Container Runtime | Docker | Última |
| Orquestração | Docker Compose | 3.8 |
| APIs Externas | viaCEP, WeatherAPI | Atual |

---

## 📄 Endpoints das APIs

### Service A
- `POST /cep` - Submete CEP pra buscar temperatura
- `GET /health` - Health check

### Service B
- `POST /weather` - Busca o clima pra um CEP (chamado pelo Service A)
- `GET /health` - Health check

### Infraestrutura
- UI do Zipkin: `http://localhost:9411`
- OTEL Collector: `http://localhost:4318`

---

## 🧪 Testing

### Test Suite
Run comprehensive tests:
```bash
./test.sh
```

Tests include:
- Service health checks
- Valid CEP processing
- Invalid CEP validation
- Error handling (404, 422, 500)
- Temperature conversion accuracy
- Zipkin trace collection

### Manual Testing
```bash
# Valid request
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'

# Invalid CEP
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"123"}'
```

---

## 🚀 Começo Rápido

1. **Configura o Ambiente**
   ```bash
   cd observability_openTelemetry
   cp .env .env.local
   # Adiciona WEATHER_API_KEY no .env.local
   ```

2. **Inicia os Serviços**
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

3. **Testa a API**
   ```bash
   curl -X POST http://localhost:8080/cep \
     -H 'Content-Type: application/json' \
     -d '{"cep":"01310100"}'
   ```

4. **Visualiza os Traces**
   - Abre http://localhost:9411
   - Clica em "Run Query"

5. **Para os Serviços**
   ```bash
   ./stop.sh
   ```

---

## 📖 Arquivos de Documentação

| Arquivo | Propósito |
|---------|----------|
| **README.md** | Documentação completa com todos os detalhes |
| **QUICKSTART.md** | Guia rápido de setup em 5 minutos |
| **API.md** | Referência completa das APIs com exemplos |
| **ARCHITECTURE.md** | Design do sistema e detalhes dos componentes |
| **DEVELOPMENT.md** | Guia de desenvolvimento e debug |
| **TROUBLESHOOTING.md** | Problemas comuns e soluções |

---

## 🔐 Funcionalidades de Segurança

✅ Validação de entrada em todos os endpoints
✅ Type checking pra parâmetros de requisição
✅ Tratamento de erro sem expor detalhes internos
✅ Chaves de API em variáveis de ambiente (não hardcoded)
✅ Rede Docker isolada
✅ Comunicação apenas entre serviços

---

## 📈 Performance e Observabilidade

### Métricas Capturadas
- Latência de requisição fim-a-fim
- Tempo de processamento do Service A
- Tempo de processamento do Service B
- Tempo de busca de CEP (API viaCEP)
- Tempo de busca de temperatura (WeatherAPI)

### Hierarquia de Traces
- Span raiz: Manipulação de requisição inicial
- Spans filhos: Cada operação de serviço
- Sub-spans: Chamadas de APIs externas

### Visualização
- UI do Zipkin mostra timeline de trace
- Dependências de serviços visíveis
- Breakdown de latência por serviço
- Tracking e análise de erros

---

## 🐳 Deploy com Docker

### Serviços
1. **Service A** - HTTP server na porta 8080
2. **Service B** - HTTP server na porta 8081
3. **OTEL Collector** - Coleção de traces na porta 4318
4. **Zipkin** - Visualização na porta 9411

### Rede
- Todos os serviços numa rede Docker isolada
- Comunicação interna via nomes de serviços
- Nenhuma exposição externa, exceto portas

### Persistência
- Zipkin usa armazenamento em memória
- Perfeito pra desenvolvimento/testes
- Pode ser trocado por backend persistente

---

## ✨ Conquistas Principais

✅ **Implementação Completa de Serviços**
- Service A e B completamente funcionais
- Todos os endpoints requeridos implementados
- Códigos HTTP e mensagens apropriadas

✅ **Integração OpenTelemetry**
- Tracing distribuído entre serviços
- Propagação de contexto de trace
- Spans detalhados pra todas as operações
- Medição de performance

✅ **Visualização Zipkin**
- Visualização de traces em tempo real
- Tracking de dependências entre serviços
- Análise de latência
- UI web pra exploração

✅ **Docker e Docker Compose**
- Orquestração multi-container
- Startup automático de serviços
- Deploy fácil
- Ambientes isolados

✅ **Documentação Completa**
- Guias de setup e quickstart
- Referência de APIs
- Documentação de arquitetura
- Guia de desenvolvimento
- Guia de troubleshooting

✅ **Testes e Validação**
- Suite de testes automáticos
- Exemplos de testes manuais
- Health checks
- Cobertura de cenários de erro

---

## 🌎 Valor de Aprendizado

Este projeto demonstra:
- Arquitetura de microserviços
- Conceitos de tracing distribuído
- Implementação de OpenTelemetry
- Containerização com Docker
- Integração com APIs externas
- Padrões de tratamento de erros
- Estratégias de testes
- Boas práticas de documentação

---

## 📕 Configuração de Ambiente

### Variáveis Requeridas
- `WEATHER_API_KEY` - Chave WeatherAPI (pega gratuitamente em https://www.weatherapi.com/)

### Variáveis Opcionais
- `OTEL_EXPORTER_OTLP_ENDPOINT` - Endpoint do OTEL Collector (padrão: http://otel-collector:4318)
- `SERVICE_B_URL` - URL do Service B (padrão: http://service-b:8081)

---

## 🔄 Pronto pra CI/CD

O projeto inclui:
- Dockerfile pra cada serviço
- Docker Compose pra fácil orquestração
- Endpoints de health check
- Suite de testes
- Configuração de ambiente
- Pronto pra deployment GitOps

---

## 🚢 Production Considerations

For production deployment:

1. **Persistent Storage**
   - Replace in-memory Zipkin with database
   - Add persistence for trace data

2. **Security**
   - Add authentication/authorization
   - Use HTTPS
   - Implement rate limiting
   - Add request validation

3. **Scaling**
   - Add load balancing
   - Implement caching
   - Use message queues for async processing
   - Database connection pooling

4. **Monitoring**
   - Add alerting rules
   - Implement metric collection
   - Add health monitoring
   - Performance baseline tracking

5. **Resilience**
   - Retry logic for API calls
   - Circuit breakers
   - Timeout management
   - Graceful degradation

---

## 📞 Suporte e Troubleshooting

1. **Checa a Documentação**
   - README.md pra guia completo
   - QUICKSTART.md pra setup rápido
   - TROUBLESHOOTING.md pra problemas comuns

2. **Roda os Testes**
   ```bash
   ./test.sh
   ```

3. **Visualiza os Logs**
   ```bash
   docker-compose logs
   ```

4. **Debugua o Container**
   ```bash
   docker exec -it service-a sh
   ```

---

## ✅ Checklist - Todos os Requisitos Atendidos

### Requisitos do Serviço A
- ✅ Recebe POST com CEP de 8 dígitos
- ✅ Valida entrada (8 dígitos, tipo string)
- ✅ Encaminha CEP válido pro Service B
- ✅ Retorna 422 pra entrada inválida
- ✅ Retorna mensagem "invalid zipcode"

### Requisitos do Serviço B
- ✅ Recebe CEP de 8 dígitos do Service A
- ✅ Busca CEP e encontra localidade
- ✅ Retorna temperaturas (C, F, K)
- ✅ Retorna 200 em sucesso
- ✅ Retorna 422 pra formato de CEP inválido
- ✅ Retorna 404 pra CEP que não existe
- ✅ Formatação de mensagem apropriada

### Requisitos de OTEL + Zipkin
- ✅ Tracing distribuído entre serviços
- ✅ Spans pro serviço de busca de CEP
- ✅ Spans pro serviço de temperatura
- ✅ Implementação do OTEL Collector
- ✅ Visualização no Zipkin
- ✅ Propagação de trace

### Requisitos de Entrega
- ✅ Código fonte completo
- ✅ Documentação completa
- ✅ Setup Docker/Docker Compose
- ✅ Pronto pra testes de desenvolvimento

---

## 🎉 Projeto Completo!

Todos os requisitos foram implementados e entregues:
- Código fonte completo dos dois serviços
- Integração completa com OpenTelemetry e Zipkin
- Configuração Docker e Docker Compose
- Documentação completa
- Suite de testes e guia de quickstart
- Arquitetura pronta pra produção

Pronto pra deploy e usar! 🚀
