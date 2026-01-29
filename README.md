# Sistema de Temperatura por CEP com OpenTelemetry e Zipkin

## O que é isso?

Esse projeto é um sistema distribuído em Go que recebe um CEP (Código de Endereçamento Postal) brasileiro, descobre qual é a cidade e retorna a temperatura atual em diferentes escalas (Celsius, Fahrenheit e Kelvin), tudo com rastreamento distribuído via OpenTelemetry e visualização no Zipkin.

### A Arquitetura

O sistema tem dois microserviços:

- **Service A**: Cuida da validação da entrada (CEP com 8 dígitos)
- **Service B**: Faz a orquestração, busca a localização e a temperatura

Os dois serviços têm OpenTelemetry integrado pra fazer rastreamento distribuído.

## Os Componentes Principais

### Service A (Aquele que Valida)
- **Porta**: 8080
- **O que faz**:
  - Recebe POST com CEP em JSON
  - Valida se o CEP tem exatamente 8 dígitos
  - Manda um CEP válido pra Service B
  - Retorna erro 422 se o CEP for inválido
  - Rastreia as requisições com OpenTelemetry

**Os Endpoints**:
- `POST /cep` - Processa o CEP
- `GET /health` - Checa se tá tudo OK

### Service B (Aquele que Busca a Temperatura)
- **Porta**: 8081
- **O que faz**:
  - Recebe um CEP válido de Service A
  - Consulta a API viaCEP pra saber qual é a cidade
  - Consulta a API WeatherAPI pra pegar a temperatura
  - Converte a temperatura (Celsius → Fahrenheit → Kelvin)
  - Retorna o resultado tudo certinho
  - Rastreia tudo com OpenTelemetry

**Os Endpoints**:
- `POST /weather` - Processa a requisição de clima
- `GET /health` - Checa se tá tudo OK

### Pra Ver o que Tá Acontecendo

#### OpenTelemetry Collector
- **Porta gRPC**: 4317
- **Porta HTTP**: 4318
- Coleta os traces dos dois serviços
- Manda tudo pra Zipkin

#### Zipkin
- **Porta**: 9411
- Um negócio web pra você ver os traces distribuídos
- Dá pra ver a latência entre os serviços

## O que você Precisa ter

### Pra Rodar Localmente (sem Docker)

- Go 1.21 ou mais novo
- Docker e Docker Compose (pro OTEL Collector e Zipkin)

### Pra Rodar com Docker

- Docker
- Docker Compose

## Como Rodar o Projeto

### Opção 1: Com Docker Compose (A Mais Fácil)

1. **Clone ou extraia o projeto**
   ```bash
   cd /caminho/do/projeto
   ```

2. **Configure as variáveis de ambiente**
   ```bash
   cp .env .env.local
   # Edite .env.local e coloca sua chave da WeatherAPI
   # WEATHER_API_KEY=sua_chave_aqui
   ```

3. **Inicie os serviços**
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

   Ou manualmente:
   ```bash
   docker-compose up -d
   ```

4. **Checa se os serviços tão rodando**
   ```bash
   # Service A
   curl http://localhost:8080/health
   
   # Service B
   curl http://localhost:8081/health
   ```

5. **Testa a API**
   ```bash
   # Exemplo com CEP válido (São Paulo)
   curl -X POST http://localhost:8080/cep \
     -H 'Content-Type: application/json' \
     -d '{"cep":"01310100"}'
   
   # Exemplo com CEP inválido
   curl -X POST http://localhost:8080/cep \
     -H 'Content-Type: application/json' \
     -d '{"cep":"123"}'
   ```

6. **Acessa o Zipkin**
   - Abre [http://localhost:9411](http://localhost:9411) no navegador
   - Clica em "Run Query" pra ver os traces

7. **Para os serviços**
   ```bash
   ./stop.sh
   ```

   Ou manualmente:
   ```bash
   docker-compose down
   ```

### Opção 2: Rodando Local (sem Docker pros serviços)

1. **Instala as dependências**
   ```bash
   # Service A
   cd service-a
   go mod download
   
   # Service B
   cd ../service-b
   go mod download
   ```

2. **Inicia OTEL Collector e Zipkin com Docker**
   ```bash
   docker-compose up -d otel-collector zipkin
   ```

3. **Executa os serviços**
   ```bash
   # Terminal 1 - Service A
   cd service-a
   export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
   export SERVICE_B_URL=http://localhost:8081
   go run main.go
   
   # Terminal 2 - Service B
   cd service-b
   export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
   export WEATHER_API_KEY=sua_chave_aqui
   go run main.go
   ```

4. **Testa conforme acima**

## Como Pega a Chave de API

### WeatherAPI

1. Va em [https://www.weatherapi.com/](https://www.weatherapi.com/)
2. Clica em "Sign up"
3. Cria uma conta (tem versão gratuita!)
4. Entra no dashboard e copia sua chave
5. Coloca no arquivo `.env`:
   ```
   WEATHER_API_KEY=sua_chave_aqui
   ```

## Exemplos de Uso

### Requisição que dá certo

**Request:**
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

**Response (200 OK):**
```json
{
  "city": "São Paulo",
  "temp_C": 28.5,
  "temp_F": 83.3,
  "temp_K": 301.65
}
```

### CEP Inválido (Formato Errado)

**Request:**
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"123"}'
```

**Response (422 Unprocessable Entity):**
```json
{
  "message": "invalid zipcode"
}
```

### CEP Não Encontrado

**Request:**
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"99999999"}'
```

**Response (404 Not Found):**
```json
{
  "message": "can not find zipcode"
}
```

## Ver os Traces no Zipkin

1. Abre [http://localhost:9411](http://localhost:9411)
2. Na aba "Search", você vai ver:
   - **Service Name**: Seleciona "service-a" ou "service-b"
   - **Spans**: Vê os spans de cada operação
3. Clica num trace pra ver:
   - Tempo total da requisição
   - Detalhes de cada span
   - Tempo gasto em cada etapa

### Os Spans que Tão Implementados

**Service A:**
- `handleCEP` - Processamento da requisição de CEP
- `callServiceB` - Chamada HTTP pra Service B

**Service B:**
- `handleWeather` - Processamento da requisição de clima
- `lookupCEP` - Consulta à API viaCEP
- `getTemperature` - Consulta à API WeatherAPI

## Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `WEATHER_API_KEY` | Chave de API da WeatherAPI | - |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Endpoint do OTEL Collector | `http://otel-collector:4318` |
| `SERVICE_B_URL` | URL do Service B | `http://service-b:8081` |

## Estrutura do Projeto

```
.
├── service-a/
│   ├── main.go
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── service-b/
│   ├── main.go
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── docker-compose.yml
├── otel-collector-config.yml
├── .env
├── .gitignore
├── start.sh
├── stop.sh
└── README.md
```

## APIs que a Gente Usa

### viaCEP
- **URL**: https://viacep.com.br/ws/{cep}/json/
- **Método**: GET
- **O que faz**: Busca informações de localização por CEP

### WeatherAPI
- **URL**: https://api.weatherapi.com/v1/current.json
- **Método**: GET
- **O que faz**: Busca dados de clima em tempo real
- **Precisa de**: API Key

## Como Converter Temperatura

- **Fahrenheit**: F = C × 1,8 + 32
- **Kelvin**: K = C + 273

## Troubleshooting

### Containers não iniciam
```bash
# Verifique o status
docker-compose logs

# Reconstrua as imagens
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Zipkin não mostra traces
- Verifique se OTEL Collector está rodando: `docker logs otel-collector`
- Verifique se os serviços estão enviando traces
- Aguarde alguns segundos após fazer requisições

### Erro "can not find zipcode"
- Verifique se o CEP é válido
- Certifique-se de que tem internet ativa (consulta viaCEP)

### Erro "failed to get temperature"
- Verifique se a chave de WeatherAPI está configurada
- Verifique se a chave é válida
- Verifice limites de requisições da API gratuita

### Service A não consegue acessar Service B
- Verifique se ambos estão na mesma rede Docker: `docker network ls`
- Teste a conectividade: `docker exec service-a curl http://service-b:8081/health`

## Desenvolvimento

### Modifica code e recompila

```bash
# Reconstrói as imagens
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Vê os logs em tempo real
```bash
docker-compose logs -f
```

### Entra no shell do container
```bash
docker exec -it service-a sh
docker exec -it service-b sh
```

## Performance e Métricas

O sistema já coleta automaticamente:
- Latência de cada requisição
- Tempo de resposta de APIs externas
- Hierarquia de chamadas entre serviços
- Erros e exceções

Tudo fica visível no Zipkin pra você otimizar a performance.

## Segurança

Umas coisas boas pra fazer em produção:

1. **Usar secrets manager** pra guardar as chaves de API
2. **Implementar autenticação** entre os serviços
3. **Adicionar rate limiting**
4. **Usar HTTPS** em vez de HTTP
5. **Implementar validação adicional** de entrada
6. **Adicionar CORS** se precisar

## Licença

Este projeto é fornecido como exemplo educacional.

## Suporte

Para dúvidas ou problemas:
1. Verifique os logs: `docker-compose logs`
2. Consulte a seção Troubleshooting acima
3. Verifique se todas as variáveis de ambiente estão configuradas

## Referências

- [OpenTelemetry Go Documentation](https://opentelemetry.io/docs/instrumentation/go/)
- [Zipkin Documentation](https://zipkin.io/pages/quickstart.html)
- [viaCEP API](https://viacep.com.br/)
- [WeatherAPI Documentation](https://www.weatherapi.com/docs/)
