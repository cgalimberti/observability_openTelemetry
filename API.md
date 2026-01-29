# Documentação de API

## URLs Base

- **Service A**: `http://localhost:8080`
- **Service B**: `http://localhost:8081`

## Endpoints do Service A

### 1. Busca de CEP

**Endpoint**: `POST /cep`

**Descrição**: Submete um CEP (Código de Endereçamento Postal) pra buscar a temperatura. Valida a entrada e encaminha pro Service B.

**Request**:
```http
POST /cep HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "cep": "01310100"
}
```

**Parâmetros do Body**:
| Parâmetro | Tipo | Obrigatório | Descrição | Restrições |
|-----------|------|-----------|-----------|----------|
| cep | string | Sim | Código postal | Exatamente 8 dígitos, só números |

**Respostas**:

#### Sucesso (200 OK)
Resposta encaminhada do Service B com dados de temperatura.

```json
{
  "city": "São Paulo",
  "temp_C": 28.5,
  "temp_F": 83.3,
  "temp_K": 301.65
}
```

#### Entrada Inválida (422 Unprocessable Entity)

```json
{
  "message": "invalid zipcode"
}
```

**Possíveis Razões**:
- CEP não tem exatamente 8 dígitos
- CEP tem caracteres não-numéricos
- CEP não é uma string

#### Não Encontrado (404 Not Found)
Formato do CEP é válido mas o código postal não existe.

```json
{
  "message": "can not find zipcode"
}
```

#### Erro Interno (500)
Service B tá inacessível ou deu ruim internamente.

```json
{
  "message": "internal server error"
}
```

**Exemplos**:

CEP válido:
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

CEP inválido (muito curto):
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"123"}'
```

CEP inválido (tem letra):
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"0131010A"}'
```

---

### 2. Health Check

**Endpoint**: `GET /health`

**Description**: Checks if Service A is running and healthy.

**Request**:
```http
GET /health HTTP/1.1
Host: localhost:8080
```

**Response (200 OK)**:
```json
{
  "status": "ok"
}
```

**Example**:
```bash
curl http://localhost:8080/health
```

---

## Service B Endpoints

### 1. Weather Information

**Endpoint**: `POST /weather`

**Description**: Gets current weather/temperature for a given postal code. This endpoint is typically called by Service A but can be called directly.

**Request**:
```http
POST /weather HTTP/1.1
Host: localhost:8081
Content-Type: application/json

{
  "cep": "01310100"
}
```

**Request Body Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| cep | string | Yes | Brazilian postal code (8 digits) |

**Responses**:

#### Success (200 OK)

```json
{
  "city": "São Paulo",
  "temp_C": 28.5,
  "temp_F": 83.3,
  "temp_K": 301.65
}
```

**Response Fields**:
| Field | Type | Description |
|-------|------|-------------|
| city | string | Name of the city found for the CEP |
| temp_C | float | Temperature in Celsius |
| temp_F | float | Temperature in Fahrenheit |
| temp_K | float | Temperature in Kelvin |

#### Invalid Input (422 Unprocessable Entity)

```json
{
  "message": "invalid zipcode"
}
```

**Possible Reasons**:
- CEP doesn't have exactly 8 digits
- CEP format is incorrect

#### Not Found (404 Not Found)

```json
{
  "message": "can not find zipcode"
}
```

**Reason**: The postal code doesn't exist in the database.

#### Internal Error (500)

```json
{
  "message": "failed to get temperature"
}
```

**Possible Reasons**:
- WeatherAPI is unreachable
- Invalid API key
- API rate limit exceeded
- Network connectivity issue

**Examples**:

```bash
curl -X POST http://localhost:8081/weather \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

---

### 2. Health Check

**Endpoint**: `GET /health`

**Description**: Checks if Service B is running and healthy.

**Request**:
```http
GET /health HTTP/1.1
Host: localhost:8081
```

**Response (200 OK)**:
```json
{
  "status": "ok"
}
```

**Example**:
```bash
curl http://localhost:8081/health
```

---

## Test Cases

### Valid CEPs (São Paulo Area)

```bash
# Av. Paulista, São Paulo
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'

# Centro, São Paulo
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310200"}'

# Pinheiros, São Paulo
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"05409000"}'
```

### Invalid Inputs

```bash
# Too short
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"123"}'

# Contains letters
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"0131010A"}'

# Too long
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"0131010001"}'

# Special characters
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310-100"}'

# Non-existent CEP (format valid)
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"99999999"}'
```

---

## Error Handling

### Flow Diagram

```
Request to Service A
    │
    ├─ Invalid JSON?
    │  └─ 400 Bad Request
    │
    ├─ Invalid CEP format?
    │  └─ 422 Unprocessable Entity
    │
    └─ Valid format
       │
       ├─ Call Service B
       │
       ├─ Service B returns 404?
       │  └─ Forward 404 Not Found
       │
       ├─ Service B returns 422?
       │  └─ Forward 422 Unprocessable Entity
       │
       ├─ Service B returns 200?
       │  └─ Forward 200 with temperature data
       │
       └─ Service B unreachable?
          └─ 500 Internal Server Error
```

---

## Performance Expectations

| Operation | Expected Time | Service |
|-----------|---------------|---------|
| CEP Validation | < 5ms | Service A |
| Geo-location Lookup | 50-200ms | Service B (viaCEP API) |
| Weather Lookup | 100-500ms | Service B (WeatherAPI) |
| Full Request | 200-800ms | Service A + Service B |

---

## Rate Limiting

The WeatherAPI free tier has the following limits:
- **Requests/day**: Limited based on plan
- **Current conditions**: Included
- **Hourly limit**: Check your API key limits

Implement rate limiting in production to prevent API quota issues.

---

## Headers

### Request Headers

| Header | Value | Required |
|--------|-------|----------|
| Content-Type | application/json | Yes |

### Response Headers

| Header | Value |
|--------|-------|
| Content-Type | application/json |
| X-Request-ID | Trace ID (via OTEL) |

---

## Tracing with Zipkin

All requests automatically generate traces visible in Zipkin:

1. Start a request
2. Go to http://localhost:9411
3. Click "Run Query"
4. Select service and view trace details

**Trace Information Captured**:
- Request start time
- Service processing time
- API call duration
- Total latency
- Span hierarchy

---

## Example Response Scenarios

### Scenario 1: Successful Request

```http
POST /cep HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{"cep":"01310100"}
```

**Response**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "city": "São Paulo",
  "temp_C": 28.5,
  "temp_F": 83.3,
  "temp_K": 301.65
}
```

### Scenario 2: Invalid CEP

```http
POST /cep HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{"cep":"123"}
```

**Response**:
```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{
  "message": "invalid zipcode"
}
```

### Scenario 3: CEP Not Found

```http
POST /cep HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{"cep":"00000000"}
```

**Response**:
```http
HTTP/1.1 404 Not Found
Content-Type: application/json

{
  "message": "can not find zipcode"
}
```

---

## SDK Recommendations

### cURL
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

### JavaScript
```javascript
fetch('http://localhost:8080/cep', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({cep: '01310100'})
})
.then(r => r.json())
.then(data => console.log(data));
```

### Python
```python
import requests

response = requests.post(
    'http://localhost:8080/cep',
    json={'cep': '01310100'},
    headers={'Content-Type': 'application/json'}
)
print(response.json())
```

### Go
```go
package main

import (
    "bytes"
    "encoding/json"
    "net/http"
)

func main() {
    payload := map[string]string{"cep": "01310100"}
    body, _ := json.Marshal(payload)
    resp, _ := http.Post(
        "http://localhost:8080/cep",
        "application/json",
        bytes.NewBuffer(body),
    )
    defer resp.Body.Close()
    // Process response
}
```

---

## Support

For issues or questions:
1. Check the README.md
2. Review logs: `docker-compose logs`
3. Verify environment variables are set
4. Ensure all containers are running
