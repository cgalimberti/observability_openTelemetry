# Guia de Desenvolvimento

## Setup Inicial

### Ambiente de Desenvolvimento

```bash
# Clone o repositório
git clone <repository-url>
cd observability_openTelemetry

# Instale as dependências do Go
go mod download -x

# Checa a versão do Go
go version  # Deve ser 1.21 ou mais novo
```

### Variáveis de Ambiente

Cria um arquivo `.env.local` pra desenvolvimento:

```bash
# Chaves de API
WEATHER_API_KEY=sua_chave_de_api

# OTEL
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

# URLs dos serviços
SERVICE_B_URL=http://localhost:8081
SERVICE_A_URL=http://localhost:8080
```

## Estrutura de Código

### Service A - main.go

```go
// Inicialização do tracer
tracer = otel.Tracer(serviceName)

// Span para operação
ctx, span := tracer.Start(ctx, "operacao")
defer span.End()
```

### Service B - main.go

```go
// Instrumentação automática de HTTP client
client := &http.Client{
    Transport: otelhttp.NewTransport(http.DefaultTransport),
}
```

## Build e Deploy

### Build Local

```bash
# Build Service A
cd service-a
go build -o service-a main.go

# Build Service B
cd service-b
go build -o service-b main.go
```

### Build Docker

```bash
# Build individual
docker build -t service-a:latest ./service-a
docker build -t service-b:latest ./service-b

# Via docker-compose
docker-compose build
```

## Testes

### Testes Manuais

```bash
# Health check
curl http://localhost:8080/health
curl http://localhost:8081/health

# CEP válido
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'

# CEP inválido
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"abc"}'
```

### Checa os Traces

1. Abre http://localhost:9411
2. Seleciona o serviço na dropdown "Service Name"
3. Clica em "Run Query"
4. Clica num trace pra ver os detalhes

## Debugging

### Logs Docker

```bash
# Todos os serviços
docker-compose logs -f

# Serviço específico
docker-compose logs -f service-a
docker-compose logs -f service-b

# OTEL Collector
docker-compose logs -f otel-collector

# Zipkin
docker-compose logs -f zipkin
```

## Debugging

### Logs

```bash
# Logs de um serviço
docker-compose logs -f service-a
docker-compose logs -f service-b
docker-compose logs -f otel-collector

# Segue um container específico
docker logs -f service-a-1
```

### Profiling

```bash
# CPU Profiling
go pprof http://localhost:6060/debug/pprof

# Memory Profiling
curl http://localhost:6060/debug/pprof/heap > heap.prof
go tool pprof heap.prof
```

### Dicas de Debug

- **Trace não aparece no Zipkin?** Checa se o OTEL Collector tá rodando
- **Erro de conexão com viaCEP?** Valida o CEP, a API retorna 404 pra CEPs inválidos
- **WeatherAPI retorna erro 400?** A cidade pode ter caracteres especiais, checa a saída do viaCEP

## Otimização de Performance

### Otimizações Implementadas

- **Connection Pooling**: HTTP client com timeout configurável
- **Context Propagation**: Usa spans pra tracking distribuído
- **Lazy Loading**: APIs externas são chamadas sob demanda
- **Error Handling**: Circuit breaker em caso de falhas repetidas

### Tá achando tudo lento?

```bash
# Checa o tempo de resposta
time curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'

# Analisa o trace no Zipkin pra ver onde tá demorando
```

### Limites Conhecidos

- viaCEP: ~1-2 segundos por lookup
- WeatherAPI: ~500-800ms por requisição
- OTEL: ~50-100ms adicional por trace

### Entra no Container

```bash
docker exec -it service-a sh
docker exec -it service-b sh
```

## Mudanças Comuns

### Bota uma Nova Rota

No `service-a/main.go` ou `service-b/main.go`:

```go
// Registra a rota
http.HandleFunc("/nova-rota", handleNovaRota)

// Implementa o handler
func handleNovaRota(w http.ResponseWriter, r *http.Request) {
    ctx, span := tracer.Start(r.Context(), "handleNovaRota")
    defer span.End()
    
    // Sua lógica aqui
}
```

### Adiciona um Novo Span

```go
ctx, span := tracer.Start(ctx, "nome-do-span")
defer span.End()

// Seu código aqui
// span.SetAttributes() pra adicionar atributos
```

### Mexe no OTEL Collector

Edita `otel-collector-config.yml`:

```yaml
receivers:
  # Bota novos receivers aqui
  
processors:
  # Mexe nos processadores aqui
  
exporters:
  # Adiciona novos exporters aqui
  
service:
  pipelines:
    # Configura os pipelines aqui
```

Depois reinicia:
```bash
docker-compose restart otel-collector
```

## Monitoramento

### Métricas Importantes

1. **Latência P99**: Tempo 99º percentil de requisição
2. **Taxa de Erro**: Porcentagem de requisições com erro
3. **Throughput**: Requisições por segundo
4. **Dependências**: Visualiza as chamadas entre serviços

Tudo tá disponível no Zipkin.

## Performance

### Benchmarking

```bash
# Teste de carga com Apache Bench
ab -n 1000 -c 10 -p data.json -T application/json http://localhost:8080/cep

# Com wrk
wrk -t4 -c100 -d30s http://localhost:8080/health
```

### Otimizações Possíveis

1. **Caching** de resultados de CEP
2. **Connection pooling** pras APIs externas
3. **Timeout** ajustado pras operações
4. **Batch processing** de requisições

## Commits e Versionamento

### Padrão de Commit

```
feat: descrição da feature
fix: descrição do bug fix
docs: atualizações de documentação
refactor: mudanças de código sem alterar funcionalidade
test: adição de testes
chore: mudanças em build, dependencies, etc
```

### Versionamento

Usa Semantic Versioning (SemVer):
- MAJOR.MINOR.PATCH
- v1.0.0, v1.1.0, v1.1.1

## Checklist pra Deploy

- [ ] Todos os testes passando
- [ ] Variáveis de ambiente configuradas
- [ ] Documentação atualizada
- [ ] Imagens Docker buildadas
- [ ] Health checks passando
- [ ] Traces aparecendo no Zipkin
- [ ] Sem logs de erro

## Recursos Úteis

- [OpenTelemetry Go SDK](https://pkg.go.dev/go.opentelemetry.io/otel/sdk)
- [Go HTTP Server](https://golang.org/pkg/net/http/)
- [Docker Documentation](https://docs.docker.com/)
- [Zipkin Query Language](https://zipkin.io/zipkin-query-language/)
