# Telemetry Guide (Guia de Telemetria)

## Visão Geral

Este projeto usa **OpenTelemetry** com **Zipkin** para coletar e visualizar traces distribuídos das aplicações. Cada requisição gera um trace que passa pelos dois serviços.

## Arquitetura de Telemetria

```
Request → Service A (handlecep) → Service B (handleWeather) → Response
  ↓            ↓                        ↓
Trace ID    Span: handlecep      Span: handleWeather
            Span: callServiceB   Span: getTemperature
                                 Span: lookupCEP
```

## Acessar o Zipkin

### Via Browser (Recomendado)

1. Abra [http://localhost:9411](http://localhost:9411)
2. Você verá a interface do Zipkin
3. Clique em dropdown "Service Name" e selecione:
   - `service-a` - Handler de entrada (CEP)
   - `service-b` - Orquestrador (Temperatura, viaCEP)
4. Clique em "Find Traces"
5. Clique em um trace para ver a árvore completa de spans

## Testar Telemetria

### Opção 1: Script Automatizado

```bash
./test-telemetry.sh
```

Mostra:
- ✓ Serviços registrados
- ✓ Estatísticas de traces e spans
- ✓ Últimos spans de cada serviço
- ✓ Exemplo de um trace completo

### Opção 2: API REST do Zipkin

**Listar serviços:**
```bash
curl http://localhost:9411/api/v2/services
```

Resposta: `["service-a","service-b"]`

**Buscar traces:**
```bash
# Traces de service-a
curl 'http://localhost:9411/api/v2/traces?serviceName=service-a&limit=10'

# Traces de service-b
curl 'http://localhost:9411/api/v2/traces?serviceName=service-b&limit=10'
```

**Buscar spans de um serviço:**
```bash
curl 'http://localhost:9411/api/v2/spans?serviceName=service-a'
```

### Opção 3: Gerar Traces com Requisições

1. Faça uma requisição à API:
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"20040020"}'
```

2. Aguarde 1-2 segundos para o trace ser processado
3. Veja no Zipkin - o novo trace aparecerá na lista

## Estrutura dos Traces

### Trace de um CEP

Quando você faz uma requisição `POST /cep`:

1. **Service A** - Inicia o trace
   - Span: `handlecep` (root)
     - Nome do span: operação que está sendo executada
     - Duração: tempo total da requisição
     
   - Span filho: `callserviceb` (HTTP request para B)
     - Mostra o tempo de comunicação inter-serviços

2. **Service B** - Recebe a requisição
   - Span: `handleWeather` (child of callserviceb)
     - Span filho: `lookupCEP`
       - Chamada ao viaCEP API
     - Span filho: `getTemperature`
       - Chamada ao WeatherAPI

## Métricas Disponíveis

Cada span inclui:

- **Trace ID**: Identificador único do fluxo completo
- **Span ID**: Identificador único do span
- **Parent ID**: ID do span pai (para hierarquia)
- **Duration**: Tempo de execução em microsegundos
- **Timestamp**: Quando o span iniciou
- **Tags**: Metadados adicionais (service name, span kind, etc)

## Exemplos de Durações

| Operação | Duração Típica |
|----------|----------------|
| handlecep (total) | 500-2000ms |
| callserviceb (rede) | 100-500ms |
| getTemperature (API externa) | 200-1000ms |
| lookupCEP (API viaCEP) | 100-500ms |

*Durações variam conforme latência de rede e disponibilidade de APIs externas*

## Monitorando em Tempo Real

### Logs com Traces

Cada serviço printa informações de trace nos logs:

```bash
# Ver logs de service-a
docker compose logs -f service-a

# Ver logs de service-b
docker compose logs -f service-b
```

Você verá mensagens como:
```
Service A started on :8080
Error getting temperature: weather API error: ...
2026/01/29 19:06:09 traces export: context deadline exceeded
```

### Verificar Coleta de Traces

```bash
# Verificar se OTEL Collector está rodando
docker compose ps otel-collector

# Ver logs do collector
docker compose logs otel-collector
```

## Troubleshooting Telemetria

### Sem traces aparecendo

1. **Faça uma requisição:**
   ```bash
   curl -X POST http://localhost:8080/cep \
     -H 'Content-Type: application/json' \
     -d '{"cep":"20040020"}'
   ```

2. **Aguarde 2 segundos** para o trace ser processado

3. **Refreshe o Zipkin**
   - F5 no navegador ou
   - Clique em "Find Traces" novamente

### Trace vazio ou incompleto

**Causa comum:** OTEL Collector timeout

**Solução:**
```bash
# Reiniciar collector
docker compose restart otel-collector

# Ver logs
docker compose logs otel-collector
```

### Spans com duração muito alta

Pode indicar:
- Lentidão da API externa (viaCEP, WeatherAPI)
- Problema de rede/conectividade
- Timeout na chamada

**Verificar:**
```bash
# Ver logs de erro
docker compose logs service-b

# Testar conectividade
curl https://api.weatherapi.com/v1/current.json?q=Rio+de+Janeiro
curl https://viacep.com.br/ws/20040020/json/
```

## Configuração de Telemetria

### Arquivo de Configuração

OTEL Collector usa `otel-collector-config.yml`:

```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318
      grpc:
        endpoint: 0.0.0.0:4317

exporters:
  jaeger:
    endpoint: http://zipkin:9411/api/v1/spans
```

### Variáveis de Ambiente

```bash
# Em .env
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
```

### Modificar Configuração

1. Edit `otel-collector-config.yml`
2. Reiniciar: `docker compose restart otel-collector`
3. Testar novamente

## Casos de Uso de Telemetria

### 1. Debug de Problemas

**Problema:** API lenta

**Solução:**
1. Abra Zipkin
2. Procure pelo trace lento
3. Identifique qual span demorou
4. Veja logs daquela operação específica

### 2. Análise de Performance

**Como:**
1. Execute várias requisições
2. Compare durações dos spans
3. Identifique gargalos

### 3. Rastrear Fluxo Distribuído

**Como:**
1. Veja um trace completo
2. Clique em spans para navegar
3. Entenda como dados fluem entre serviços

## Recursos Adicionais

- [OpenTelemetry Docs](https://opentelemetry.io/docs/)
- [Zipkin Docs](https://zipkin.io/pages/architecture.html)
- [W3C Trace Context](https://www.w3.org/TR/trace-context/)

## Comandos Úteis

```bash
# Ver estatísticas de traces
./test-telemetry.sh

# Testar API e gerar traces
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"20040020"}'

# Ver último trace de service-a (CLI)
curl 'http://localhost:9411/api/v2/traces?serviceName=service-a&limit=1'

# Verificar collector
docker compose ps otel-collector
docker compose logs otel-collector

# Reiniciar telemetria
docker compose restart otel-collector zipkin
```
