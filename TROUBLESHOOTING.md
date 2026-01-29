# Guia de Troubleshooting

## Problemas Comuns e Soluções

### 1. Docker Compose Não Inicia

**Problema**: `docker-compose up` falha ou containers saem na hora

**Soluções**:

1. Checa se Docker tá rodando:
   ```bash
   docker ps
   ```

2. Verifica se docker-compose tá instalado:
   ```bash
   docker-compose --version
   ```

3. Limpa e reconstrói:
   ```bash
   docker-compose down
   docker system prune -a
   docker-compose build --no-cache
   docker-compose up -d
   ```

4. Checa os logs:
   ```bash
   docker-compose logs
   docker-compose logs service-a
   docker-compose logs service-b
   docker-compose logs otel-collector
   ```

### 2. Service A ou Service B Não Inicia

**Problema**: Containers ficam reiniciando ou saem com código de erro

**Checa os logs**:
```bash
docker-compose logs service-a
docker-compose logs service-b
```

**Causas comuns**:

1. **Porta já tá sendo usada**:
   ```bash
   # Acha o processo que tá usando a porta 8080
   lsof -i :8080
   
   # Ou mexe na porta no docker-compose.yml
   ```

2. **OTEL Collector não tá pronto**:
   ```bash
   docker-compose up -d otel-collector
   sleep 5
   docker-compose up -d service-a service-b
   ```

3. **Endpoint configurado errado**:
   ```bash
   # Checa as variáveis de ambiente
   docker-compose ps
   docker exec service-a env | grep OTEL
   ```

### 3. Service A Não Consegue Conectar em Service B

**Problema**: Service A não consegue acessar Service B

**Checa a conectividade de rede**:
```bash
# Testa dentro do container de Service A
docker exec service-a curl http://service-b:8081/health

# Checa a rede
docker network ls
docker network inspect observability_opentelemetry_otel-network
```

**Solução**:

1. Verifica se os dois serviços tão na mesma rede:
   ```bash
   docker-compose ps
   ```

2. Reinicia os serviços:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### 4. Zipkin Não Mostra Traces

**Problema**: Zipkin tá rodando mas não tá mostrando traces

**Checa o OTEL Collector**:
```bash
# Checa se o collector tá rodando
docker-compose ps otel-collector

# Checa os logs do collector
docker-compose logs otel-collector

# Procura por mensagens "accepted" ou "exported"
```

**Soluções**:

1. Aguarda um pouco (traces vêm em lotes):
   ```bash
   sleep 10
   # Depois atualiza a UI do Zipkin
   ```

2. Faz mais requisições pra gerar traces:
   ```bash
   for i in {1..5}; do
     curl -X POST http://localhost:8080/cep \
       -H 'Content-Type: application/json' \
       -d '{"cep":"01310100"}'
     sleep 1
   done
   ```

3. Checa a configuração do OTEL Collector:
   ```bash
   docker exec otel-collector cat /etc/otel-collector-config.yml
   ```

4. Verifica se Zipkin tá recebendo os traces:
   ```bash
   docker-compose logs zipkin
   ```

### 5. "invalid zipcode" em Entrada Válida

**Problema**: Até CEPs válidos são rejeitados como inválidos

**Checa a lógica de validação**:

1. Verifica se o CEP tem exatamente 8 dígitos:
   ```bash
   curl -X POST http://localhost:8080/cep \
     -H 'Content-Type: application/json' \
     -d '{"cep":"01310100"}'
   ```

2. Checa se é uma string (não número):
   ```bash
   # ERRADO - CEP como número
   curl -X POST http://localhost:8080/cep \
     -H 'Content-Type: application/json' \
     -d '{"cep":1310100}'
   
   # CERTO - CEP como string
   curl -X POST http://localhost:8080/cep \
     -H 'Content-Type: application/json' \
     -d '{"cep":"01310100"}'
   ```

### 6. "can not find zipcode" em CEP Válido

**Problema**: CEP válido retorna 404 Not Found

**Causas**:

1. **CEP não existe no banco de dados do viaCEP**:
   ```bash
   # Testa direto com viaCEP
   curl https://viacep.com.br/ws/01310100/json/
   ```

2. **Problema de conectividade de rede**:
   ```bash
   # Checa dentro do container
   docker exec service-b curl https://viacep.com.br/ws/01310100/json/
   ```

3. **API do viaCEP fora do ar**:
   - Checa o [status do viaCEP](https://viacep.com.br/)

### 7. Temperatura Retorna 0 ou Erro

**Problema**: Temperatura retorna 0 ou dá erro

**Checa a chave da WeatherAPI**:
```bash
# Verifica se a chave tá setada
docker exec service-b env | grep WEATHER_API_KEY

# Testa a API direto
curl "https://api.weatherapi.com/v1/current.json?key=YOUR_KEY&q=São%20Paulo&aqi=no"
```

**Soluções**:

1. **Chave inválida ou faltando**:
   ```bash
   # Seta no .env
   WEATHER_API_KEY=sua_chave_valida_aqui
   
   # Reconstrói com o novo env
   docker-compose down
   docker-compose up -d
   ```

2. **Limite de requisições da API excedido**:
   - A versão free tem limites de requisições
   - Aguarda ou faz um upgrade no plano

3. **Nome da cidade não reconhecido**:
   - WeatherAPI pode precisar de um formato diferente pra cidade
   - Checa a documentação da API

### 8. Porta Já em Uso

**Problema**: `Error: bind: address already in use`

**Solução**:

1. Acha o processo que tá usando a porta:
   ```bash
   lsof -i :8080
   lsof -i :8081
   lsof -i :9411
   ```

2. Mata o processo ou usa outra porta:
   ```bash
   # Mata o processo
   kill -9 <PID>
   
   # Ou mexe na porta do docker-compose.yml
   ```

### 9. Latência Alta ou Timeouts

**Problema**: Requisições demoram muito ou dão timeout

**Checa**:

1. Latência das APIs externas:
   ```bash
   time curl https://viacep.com.br/ws/01310100/json/
   time curl "https://api.weatherapi.com/v1/current.json?key=YOUR_KEY&q=São%20Paulo"
   ```

2. Latência de rede:
   ```bash
   docker exec service-b ping 8.8.8.8
   ```

3. Limites de recurso:
   ```bash
   docker stats
   ```

4. Aumenta os timeouts no código se necessário

### 10. Containers Rodando mas APIs Não Respondem

**Problema**: Serviços tão rodando mas endpoints retornam connection refused

**Checa**:

1. Serviços tão realmente rodando:
   ```bash
   docker-compose ps
   curl http://localhost:8080/health
   curl http://localhost:8081/health
   ```

2. Checa o firewall:
   ```bash
   sudo ufw status
   sudo ufw allow 8080
   sudo ufw allow 8081
   sudo ufw allow 9411
   ```

3. Checa se tá listening na porta correta:
   ```bash
   docker exec service-a netstat -tlnp | grep 8080
   ```

### 11. Problemas de Memória

**Problema**: Containers crasham ou o sistema fica lento

**Checa o uso de memória**:
```bash
docker stats

# Aumenta o limite de memória se necessário (edita docker-compose.yml)
# Adiciona:
# services:
#   service-a:
#     mem_limit: 512m
```

### 12. Erros de Permissão

**Problema**: Scripts não conseguem executar

**Arruma**:
```bash
chmod +x start.sh stop.sh test.sh
./start.sh
```

## Passos pra Debugar

### Passo 1: Checa o Status do Docker
```bash
docker --version
docker ps
docker network ls
```

### Passo 2: Checa os Logs dos Serviços
```bash
docker-compose logs --tail=50 service-a
docker-compose logs --tail=50 service-b
docker-compose logs --tail=50 otel-collector
```

### Passo 3: Testa Conectividade
```bash
# Health de Service A
curl -v http://localhost:8080/health

# Health de Service B
curl -v http://localhost:8081/health

# UI do Zipkin
curl -v http://localhost:9411

# OTEL Collector
curl -v http://localhost:4318/v1/traces
```

### Passo 4: Testa a Chamada da API
```bash
curl -v -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

### Passo 5: Checa os Traces no Zipkin
1. Abre http://localhost:9411
2. Clica em "Run Query"
3. Procura por traces de service-a e service-b

### Passo 6: Inspeciona o Container
```bash
docker exec -it service-a sh
# Dentro do container:
env
ps aux
curl http://localhost:8080/health
curl http://service-b:8081/health
```

## Otimização de Performance

### Se a Latência Tiver Alta:

1. **Adiciona cache** pras buscas de CEP
2. **Aumenta os pools de conexão**
3. **Usa redes mais rápidas**
4. **Otimiza as queries do banco**

### Se o Throughput For Baixo:

1. **Aumenta os recursos do container**
2. **Adiciona load balancing**
3. **Implementa fila de requisições**
4. **Otimiza as dependências**

## Monitoramento e Alertas

### Usa Alertas do Zipkin

1. Abre o Zipkin: http://localhost:9411
2. Procura por traces lentos (latência P99)
3. Identifica os gargalos
4. Otimiza de acordo

### Coleta Métricas

- Latências P50, P95, P99
- Taxa de erros
- Throughput (requisições/segundo)
- Dependências de serviços

## Procedimentos de Recuperação

### Reset Completo

```bash
# Para tudo
./stop.sh

# Remove todos os containers e networks
docker-compose down -v

# Remove imagens não usadas
docker image prune -a

# Reconstrói e inicia fresh
docker-compose build --no-cache
docker-compose up -d

# Verifica
docker-compose ps
curl http://localhost:8080/health
```

### Reset Parcial

```bash
# Reinicia serviços específicos
docker-compose restart service-a service-b

# Ou
docker-compose down service-a service-b
docker-compose up -d service-a service-b
```

## Precisa de Ajuda?

Se os problemas persistirem:

1. **Checa os logs** - Sempre começa por aqui
2. **Lê a documentação** - README.md, ARCHITECTURE.md
3. **Roda a suite de testes** - `./test-api.sh`
4. **Verifica a configuração** - .env, docker-compose.yml
5. **Checa os serviços externos** - Status do viaCEP, WeatherAPI

## Testes Funcionais

### Rodando os Testes Automatizados

Use o script `test-api.sh` para fazer testes completos:

```bash
./test-api.sh
```

Esse script verifica:
- ✓ Health check do Service A
- ✓ Health check do Service B
- ✓ Acessibilidade do Zipkin
- ✓ Conectividade do OTEL Collector
- ✓ Endpoint /cep com CEP válido
- ✓ Validação com CEP inválido
- ✓ Coleta de traces

### Testes Manuais

**1. Health Check dos Serviços**
```bash
# Service A
curl http://localhost:8080/health

# Service B
curl http://localhost:8081/health
```

Esperado: `{"status":"ok"}`

**2. Testar a API de Consulta de CEP**
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"20040020"}'
```

Resposta esperada (se a chave de API estiver configurada):
```json
{
  "address": "Av Rio Branco",
  "city": "Rio de Janeiro",
  "temp_C": 28.5,
  "temp_F": 83.3,
  "temp_K": 301.65
}
```

**3. Verificar CEP Inválido**
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"12345"}'
```

Resposta esperada: HTTP 422 (Unprocessable Entity)
```json
{"message":"invalid CEP format"}
```

**4. Ver os Traces no Zipkin**
- Abra [http://localhost:9411](http://localhost:9411) no navegador
- Selecione um serviço no dropdown "Service Name"
- Procure pelos traces recentes

**5. Ver Logs dos Serviços**
```bash
# Todos os serviços
docker compose logs -f

# Service A apenas
docker compose logs -f service-a

# Service B apenas
docker compose logs -f service-b

# OTEL Collector
docker compose logs -f otel-collector
```

### Interpretando os Resultados

| Status | Significado | Ação |
|--------|-------------|------|
| ✓ | Tudo ok | Nenhuma necessária |
| ⚠ | Comportamento esperado ou não crítico | Verificar logs para detalhes |
| ✗ | Erro | Veja a seção relevante de troubleshooting |

### Exemplos de CEPs para Teste

Aqui estão alguns CEPs reais do Brasil que você pode usar:

| CEP | Localidade |
|-----|-----------|
| 01310100 | Av Paulista, São Paulo |
| 20040020 | Av Rio Branco, Rio de Janeiro |
| 30130100 | Av Getúlio Vargas, Belo Horizonte |
| 40015040 | Pelourinho, Salvador |

## Recursos Úteis

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Zipkin Documentation](https://zipkin.io/)
- [viaCEP API](https://viacep.com.br/)
- [WeatherAPI Documentation](https://www.weatherapi.com/docs/)
