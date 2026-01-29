# Testing Guide (Guia de Testes)

## Quick Start

Para fazer testes funcionais rapidamente, execute:

```bash
./test-api.sh
```

Isso vai testar todos os endpoints e componentes do sistema.

## Teste Manual Rápido

1. **Verificar que os serviços estão rodando:**
   ```bash
   docker compose ps
   ```

2. **Teste de Health Check:**
   ```bash
   curl http://localhost:8080/health
   curl http://localhost:8081/health
   ```

3. **Teste da API Principal (CEP):**
   ```bash
   curl -X POST http://localhost:8080/cep \
     -H 'Content-Type: application/json' \
     -d '{"cep":"20040020"}'
   ```

4. **Ver Traces no Zipkin:**
   - Abra http://localhost:9411 no navegador

## Cenários de Teste

### Scenario 1: CEP Válido com Temperatura
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"20040020"}'
```

**Esperado:** 
- HTTP 200
- JSON com address, city, e temperatura

### Scenario 2: CEP Inválido (Formato)
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"123"}'
```

**Esperado:** 
- HTTP 422 (Unprocessable Entity)
- Mensagem de erro sobre formato

### Scenario 3: CEP Inexistente
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"99999999"}'
```

**Esperado:**
- HTTP 400 (Bad Request)
- Mensagem "can not find zipcode"

### Scenario 4: Request Inválido (sem CEP)
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{}'
```

**Esperado:**
- HTTP 400 ou 422
- Mensagem de erro sobre campo obrigatório

## Observando os Traces

### No Zipkin UI:
1. Abra http://localhost:9411
2. Clique em "service-a" no dropdown "Service Name"
3. Clique em "Find Traces"
4. Você deve ver os traces das suas requisições

### Nos Logs:
```bash
# Ver todos os logs em tempo real
docker compose logs -f

# Ver logs de um serviço específico
docker compose logs -f service-a
docker compose logs -f service-b
docker compose logs -f otel-collector
```

## Teste de Carga (Opcional)

Se quiser testar com múltiplas requisições:

```bash
# 10 requisições sequenciais
for i in {1..10}; do
  curl -s -X POST http://localhost:8080/cep \
    -H 'Content-Type: application/json' \
    -d '{"cep":"20040020"}' | head -c 50
  echo ""
done
```

## Troubleshooting

Se algum teste falhar:

1. **Verificar se os containers estão rodando:**
   ```bash
   docker compose ps
   ```

2. **Ver logs de erro:**
   ```bash
   docker compose logs service-a
   docker compose logs service-b
   docker compose logs otel-collector
   ```

3. **Reiniciar a stack:**
   ```bash
   ./stop.sh
   sleep 2
   ./start.sh
   ```

4. **Verificar configuração da API Key:**
   ```bash
   cat .env | grep WEATHER_API_KEY
   ```

## Expected Response Times

- Health Check: < 10ms
- CEP Query (com temperatura): 500-2000ms (depende de APIs externas)
- Zipkin Query: < 500ms

## Configurações de Teste

Para testar com diferentes configurações, edite o arquivo `.env`:

```bash
# Usar endpoint OTEL diferente
OTEL_EXPORTER_OTLP_ENDPOINT=http://seu-host:4318

# Configurar serviços remotos
SERVICE_A_URL=http://seu-service-a:8080
SERVICE_B_URL=http://seu-service-b:8081
```

Depois reinicie os containers:
```bash
docker compose down
docker compose up -d
```
