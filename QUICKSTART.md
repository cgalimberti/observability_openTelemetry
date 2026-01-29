# Guia de Início Rápido

## 🚀 Começa em 5 Minutos

### O que você precisa
- Docker e Docker Compose instalados
- Chave de WeatherAPI (pega uma grátis em https://www.weatherapi.com/)

### Passo 1: Configure o Ambiente

```bash
# Entra no diretório do projeto
cd observability_openTelemetry

# Copia o arquivo de exemplo
cp .env .env.local

# Edita com sua chave de WeatherAPI
nano .env.local
# Muda: WEATHER_API_KEY=sua_chave_aqui
```

### Passo 2: Inicia os Serviços

```bash
chmod +x start.sh
./start.sh
```

Aguarda a mensagem de confirmação.

### Passo 3: Testa a API

```bash
# Testa com um CEP válido (São Paulo)
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

### Passo 4: Vê os Traces

Abre no navegador: http://localhost:9411

- Clica no botão "Run Query"
- Seleciona um serviço da dropdown
- Vê seus traces!

### Passo 5: Para os Serviços

```bash
./stop.sh
```

---

## 📋 What's Running

| Service | Port | Purpose |
|---------|------|---------|
| Service A | 8080 | Input validation & routing |
| Service B | 8081 | CEP lookup & temperature |
| Zipkin | 9411 | Trace visualization |
| OTEL Collector | 4318 | Trace collection |

---

## 🧪 Run Tests

```bash
chmod +x test.sh
./test.sh
```

---

## 📚 Documentation

- **README.md** - Full documentation
- **API.md** - API endpoints and examples
- **ARCHITECTURE.md** - System design
- **DEVELOPMENT.md** - Development guide
- **TROUBLESHOOTING.md** - Common issues and fixes

---

## 🔧 Common Commands

```bash
# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f service-a

# Access service shell
docker exec -it service-a sh

# Health check
curl http://localhost:8080/health

# Stop and remove everything
docker-compose down -v

# Rebuild images
docker-compose build --no-cache
```

---

## 📝 Example Requests

### Valid CEP
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

### Invalid CEP
```bash
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"123"}'
```

### Direct Service B Call
```bash
curl -X POST http://localhost:8081/weather \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

---

## ⚠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| Port in use | `lsof -i :8080` then kill the process |
| No traces in Zipkin | Wait 10 seconds, refresh page |
| "can not find zipcode" | CEP doesn't exist or viaCEP API down |
| "failed to get temperature" | Check WeatherAPI key in .env |
| Containers won't start | Run `docker-compose logs` to see error |

See **TROUBLESHOOTING.md** for more issues.

---

## 🎯 Next Steps

1. Read **ARCHITECTURE.md** to understand the system
2. Review **API.md** for all available endpoints
3. Check **DEVELOPMENT.md** to modify the code
4. Deploy using Docker to production environment

---

## 📞 Support

- Check logs: `docker-compose logs`
- Run tests: `./test.sh`
- Review documentation files
- See TROUBLESHOOTING.md for common issues

---

**Happy coding!** 🎉
