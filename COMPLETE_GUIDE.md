# Guia Completo de Implementação

## Sistema de Temperatura por CEP com OpenTelemetry e Zipkin

### 🎯 Visão Geral do Projeto

Esse é um sistema distribuído completo e pronto pra produção em Go que:
1. Valida CEPs brasileiros
2. Busca cidades usando a API viaCEP
3. Recupera temperatura atual usando WeatherAPI
4. Converte temperaturas (Celsius, Fahrenheit, Kelvin)
5. Implementa tracing distribuído com OpenTelemetry
6. Visualiza traces com Zipkin

---

## 📁 Arquivos do Projeto

### Documentação
```
README.md                    # Documentação completa
QUICKSTART.md               # Guia rápido de 5 minutos
API.md                      # Referência de APIs
ARCHITECTURE.md             # Design do sistema
DEVELOPMENT.md              # Guia do desenvolvedor
TROUBLESHOOTING.md          # Problemas comuns
PROJECT_SUMMARY.md          # Este resumo
```

### Código Fonte
```
service-a/
  ├── main.go               # Implementação do Service A
  ├── go.mod               # Módulo Go
  ├── go.sum               # Dependências
  └── Dockerfile           # Imagem Docker

service-b/
  ├── main.go               # Implementação do Service B
  ├── go.mod               # Módulo Go
  ├── go.sum               # Dependências
  └── Dockerfile           # Imagem Docker
```

### Configuração e Scripts
```
docker-compose.yml          # Orquestração de serviços
otel-collector-config.yml   # Config do coletor de traces
.env                        # Variáveis de ambiente
.gitignore                  # Regras de git ignore
start.sh                    # Inicia serviços
stop.sh                     # Para serviços
test.sh                     # Roda testes
```

---

## 🚀 Setup Rápido (5 Minutos)

### 1. Configura o Ambiente
```bash
cd observability_openTelemetry
cp .env .env.local

# Edita .env.local - Adiciona sua chave WeatherAPI:
# WEATHER_API_KEY=sua_chave_de_https://www.weatherapi.com
nano .env.local
```

### 2. Inicia os Serviços
```bash
chmod +x start.sh stop.sh test.sh
./start.sh
```

### 3. Testa o Sistema
```bash
# Validação e roteamento do Service A
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'

# Deve retornar:
# {
#   "city": "São Paulo",
#   "temp_C": 28.5,
#   "temp_F": 83.3,
#   "temp_K": 301.65
# }
```

### 4. Visualiza os Traces
Abre no navegador: **http://localhost:9411**
- Clica em "Run Query"
- Seleciona serviço na dropdown
- Clica num trace pra ver detalhes

### 5. Para os Serviços
```bash
./stop.sh
```

---

## 🏗 Arquitetura

### Fluxo do Sistema
```
┌─────────────────┐
│   Client (You)  │
└────────┬────────┘
         │ POST /cep
         │ {"cep": "01310100"}
         ▼
    ┌──────────────────────────┐
    │   Service A (Port 8080)  │
    │  - Validates 8-digit CEP │
    │  - Checks string type    │
    └────────┬─────────────────┘
             │ Valid CEP?
             │ YES → Forward to B
             ▼
    ┌──────────────────────────┐
    │   Service B (Port 8081)  │
    │  - Lookup: viaCEP API    │
    │  - Weather: WeatherAPI   │
    │  - Convert: C→F→K       │
    └────────┬─────────────────┘
             │ Return JSON
             ▼
         ┌──────────────────┐
         │  Client Response │
         └──────────────────┘
             PLUS
         ┌──────────────────┐
         │  Traces sent to  │
         │  OTEL Collector  │
         │      ↓           │
         │    Zipkin UI     │
         │   (9411)         │
         └──────────────────┘
```

### Detalhes dos Serviços

#### Service A - Input Handler
- **Port**: 8080
- **Endpoint**: POST /cep
- **Input**: `{"cep": "XXXXXXXX"}`
- **Validations**:
  - Exactly 8 characters
  - All numeric
  - String type (not number)
- **Responses**:
  - 200: Forwarded response from Service B
  - 422: Invalid CEP format
  - 500: Service B unreachable

#### Service B - Orchestration
- **Port**: 8081
- **Endpoint**: POST /weather
- **Input**: `{"cep": "XXXXXXXX"}`
- **Operations**:
  1. Call viaCEP API → Get city name
  2. Call WeatherAPI → Get temperature (°C)
  3. Convert to Fahrenheit: F = C × 1.8 + 32
  4. Convert to Kelvin: K = C + 273
- **Response Format**:
  ```json
  {
    "city": "São Paulo",
    "temp_C": 28.5,
    "temp_F": 83.3,
    "temp_K": 301.65
  }
  ```
- **Status Codes**:
  - 200: Success
  - 404: CEP not found
  - 422: Invalid CEP format
  - 500: API error

---

## 🔍 Testes

### Suite de Testes Automática
```bash
./test.sh
```

Runs:
- Health checks
- Valid CEP processing
- Invalid input validation
- Error scenarios
- Temperature conversions
- Zipkin trace verification

### Testes Manuais

**Valid CEP (São Paulo):**
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

**Invalid CEP (too short):**
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"123"}'
```

**Invalid CEP (contains letters):**
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"0131010A"}'
```

**Direct Service B call:**
```bash
curl -X POST http://localhost:8081/weather \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

---

## 🔍 Tracing e Observabilidade

### Integração com OpenTelemetry
- **Spans Created**:
  - Service A: `handleCEP`, `callServiceB`
  - Service B: `handleWeather`, `lookupCEP`, `getTemperature`

- **Attributes Captured**:
  - HTTP method, URL, status code
  - CEP value
  - City name
  - Temperature values
  - Latencies

### Visualização do Zipkin
1. Open http://localhost:9411
2. Click "Run Query"
3. Select service: "service-a" or "service-b"
4. Click on trace to see:
   - Request timeline
   - Span hierarchy
   - Latency breakdown
   - Error information

### Key Metrics Tracked
- End-to-end request latency
- Service A processing time
- Service B processing time
- viaCEP API response time
- WeatherAPI response time

---

## 🐳 Setup Docker

### Serviços Rodando
```
Service A          - HTTP on 8080
Service B          - HTTP on 8081
OTEL Collector    - HTTP on 4318
Zipkin            - HTTP on 9411
```

### Comandos Docker
```bash
# View all services
docker-compose ps

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f service-a

# Access container shell
docker exec -it service-a sh

# Stop services
docker-compose down

# Remove all containers and volumes
docker-compose down -v

# Rebuild images
docker-compose build --no-cache
```

---

## ⚙️ Configuration

### Environment Variables (.env)
```bash
# REQUIRED - Get from https://www.weatherapi.com
WEATHER_API_KEY=your_api_key

# OPTIONAL - Default values work for Docker Compose
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
SERVICE_B_URL=http://service-b:8081
```

### Port Mapping
| Service | Port | Purpose |
|---------|------|---------|
| Service A | 8080 | Input validation |
| Service B | 8081 | Weather lookup |
| OTEL Collector | 4318 | Trace collection |
| Zipkin | 9411 | Trace UI |

---

## 🐛 Troubleshooting

### Serviços N\u00e3o Iniciam
```bash
# Checa se Docker t\u00e1 rodando
docker ps

# Visualiza erros
docker-compose logs

# Reconstr\u00f3i
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Sem Traces no Zipkin
```bash
# Aguarda um pouco (traces v\u00e3o em lotes)
sleep 10

# Faz mais requisi\u00e7\u00f5es
./test.sh

# Checa logs do collector
docker-compose logs otel-collector

# Atualiza UI do Zipkin
```

### "can not find zipcode"
- CEP n\u00e3o existe no banco de dados do viaCEP
- Teste: `curl https://viacep.com.br/ws/01310100/json/`

### Temperatura Retorna Erro
- Checa chave WeatherAPI: `docker exec service-b env | grep WEATHER`
- Verifica se chave \u00e9 v\u00e1lida em https://www.weatherapi.com
- Checa limites da API

### Porta J\u00e1 em Uso
```bash
# Acha o processo
lsof -i :8080

# Mata o processo
kill -9 <PID>

# Ou mexe na porta do docker-compose.yml
```

---

## 📚 API Reference

### Service A
**POST /cep**
```json
Request:
{
  "cep": "01310100"
}

Response (200):
{
  "city": "São Paulo",
  "temp_C": 28.5,
  "temp_F": 83.3,
  "temp_K": 301.65
}

Response (422):
{
  "message": "invalid zipcode"
}
```

**GET /health**
```json
Response (200):
{
  "status": "ok"
}
```

### Service B
**POST /weather**
- Same as Service A's POST /cep but called internally

**GET /health**
- Same as Service A's GET /health

---

## 🔐 Security Notes

✅ **Implemented**
- Input validation (CEP format)
- Type checking
- Error handling without leaking internals
- API keys in environment variables
- Isolated Docker network

⚠️ **For Production**
- Add authentication/authorization
- Use HTTPS instead of HTTP
- Implement rate limiting
- Add request logging
- Use secrets manager for API keys
- Add request signing

---

## 📊 Performance

### Latências Esperadas
| Operação | Tempo |
|-----------|------|
| Validação CEP | < 5ms |
| Busca viaCEP | 50-200ms |
| Chamada WeatherAPI | 100-500ms |
| **Total da requisição** | 200-800ms |

### Dicas de Otimização
1. Adiciona cache pra buscas de CEP
2. Connection pooling pras APIs
3. Processamento em lote assíncrono
4. Rate limiting pra proteger APIs

---

## 🚢 Deployment

### Desenvolvimento
```bash
./start.sh
```

### Checklist pra Produção
- [ ] Usa backend Zipkin persistente (n\u00e3o em-mem\u00f3ria)
- [ ] Adiciona autentica\u00e7\u00e3o entre servi\u00e7os
- [ ] Usa HTTPS
- [ ] Implementa rate limiting
- [ ] Adiciona logging de requisi\u00e7\u00f5es
- [ ] Usa secrets manager pras chaves de API
- [ ] Adiciona health checks/monitoring
- [ ] Define limites de recursos
- [ ] Adiciona regras de alerta
- [ ] Habilita auto-scaling

---

## 📖 Arquivos de Documentação

| Arquivo | Conteúdo |
|---------|----------|
| README.md | Documentação completa |
| QUICKSTART.md | Setup de 5 minutos |
| API.md | Referência de endpoints |
| ARCHITECTURE.md | Design do sistema |
| DEVELOPMENT.md | Guia do dev |
| TROUBLESHOOTING.md | Problemas comuns |
| PROJECT_SUMMARY.md | Visão geral |

---

## ✅ Checklist de Verificação

### Instalação
- [ ] Repositório git clonado/extraído
- [ ] Docker e Docker Compose instalados
- [ ] .env configurado com chave WeatherAPI
- [ ] Todos os arquivos presentes

### Startup
- [ ] `./start.sh` roda com sucesso
- [ ] Todos os 4 serviços rodando
- [ ] Sem erros nos logs

### Testes
- [ ] Health checks passam
- [ ] CEP válido retorna temperatura
- [ ] CEP inválido retorna 422
- [ ] CEP inexistente retorna 404
- [ ] Traces aparecem no Zipkin

### Documentação
- [ ] Todos os arquivos MD presentes
- [ ] Scripts são executáveis
- [ ] Ambiente configurado

---

## 🎯 Critérios de Sucesso Atingidos

### Serviço A ✅
- ✅ Recebe POST com CEP de 8 dígitos
- ✅ Valida formato e tipo
- ✅ Encaminha pro Service B
- ✅ Retorna respostas apropriadas

### Serviço B ✅
- ✅ Processa CEP do Service A
- ✅ Busca cidade via viaCEP
- ✅ Pega temperatura da WeatherAPI
- ✅ Converte pra todas as escalas
- ✅ Retorna JSON formatado

### OpenTelemetry ✅
- ✅ Tracing distribuído implementado
- ✅ Spans pra todas as operações
- ✅ Propagação de contexto de trace

### Zipkin ✅
- ✅ Traces coletados
- ✅ UI web operacional
- ✅ Visualização de traces funcionando

### Entrega ✅
- ✅ Código fonte completo
- ✅ Documentação completa
- ✅ Setup Docker Compose
- ✅ Suite de testes incluída
- ✅ Guia de quick start

---

## 🤝 Suporte

1. **Documentação**
   - Começa com QUICKSTART.md
   - Checa README.md pra detalhes
   - Vê TROUBLESHOOTING.md pra problemas

2. **Testes**
   - Roda `./test.sh` pra verificação
   - Checa logs do Docker: `docker-compose logs`

3. **Debug**
   - Acessa container: `docker exec -it service-a sh`
   - Visualiza logs OTEL: `docker-compose logs otel-collector`
   - Checa Zipkin: http://localhost:9411

---

## 🎉 Pronto pra Usar!

Seu sistema completo distribuído de busca de temperatura está pronto pra:
- ✅ Receber e validar entrada de CEP
- ✅ Buscar cidades e temperaturas
- ✅ Converter escalas de temperatura
- ✅ Rastrear requisições com tracing distribuído
- ✅ Visualizar performance com Zipkin
- ✅ Fazer deploy com Docker

**Começa com**: `./start.sh` depois visita `http://localhost:9411` 🚀
