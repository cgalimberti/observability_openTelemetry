# Testing & Telemetry Quick Reference

## 📋 Arquivos Disponíveis

| Arquivo | Tipo | Tamanho | Descrição |
|---------|------|---------|-----------|
| [test-api.sh](test-api.sh) | Script | 4.6K | Testes funcionais automatizados da API |
| [test-telemetry.sh](test-telemetry.sh) | Script | 5.4K | Visualiza traces do Zipkin |
| [TESTING.md](TESTING.md) | Doc | 3.3K | Guia completo de testes manuais |
| [TELEMETRY.md](TELEMETRY.md) | Doc | 6.4K | Guia de telemetria e OpenTelemetry |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Doc | 12K | Soluções e diagnóstico |

## 🚀 Comandos Rápidos

### Testar Funcionalidades

```bash
# Suite completa de testes
./test-api.sh

# Testes manuais específicos
curl http://localhost:8080/health
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"20040020"}'
```

### Testar Telemetria

```bash
# Ver traces no CLI
./test-telemetry.sh

# Abrir Zipkin no navegador
# http://localhost:9411

# Gerar traces com requisições
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"20040020"}'
```

### Gerenciar Stack

```bash
# Iniciar
./start.sh

# Parar
./stop.sh

# Reiniciar
./stop.sh && sleep 2 && ./start.sh

# Ver status
docker compose ps

# Ver logs
docker compose logs -f
docker compose logs -f service-a
docker compose logs -f service-b
```

## 📊 Cenários de Teste

### ✓ Teste Básico (5 min)
1. Execute: `./test-api.sh`
2. Verifique resultados
3. Tudo verde = sistema ok

### ✓ Teste com Telemetria (10 min)
1. Execute: `curl -X POST http://localhost:8080/cep -H 'Content-Type: application/json' -d '{"cep":"20040020"}'`
2. Aguarde 2 segundos
3. Execute: `./test-telemetry.sh`
4. Ou abra: `http://localhost:9411`

### ✓ Teste de Carga (15 min)
```bash
# 20 requisições sequenciais
for i in {1..20}; do
  curl -s -X POST http://localhost:8080/cep \
    -H 'Content-Type: application/json' \
    -d '{"cep":"20040020"}' &
done
wait
```

### ✓ Teste de Múltiplos CEPs (5 min)
```bash
# Testar com diferentes CEPs
for cep in "20040020" "01310100" "30130100" "90040390"; do
  echo "Testing CEP: $cep"
  curl -s -X POST http://localhost:8080/cep \
    -H 'Content-Type: application/json' \
    -d "{\"cep\":\"$cep\"}"
  echo ""
done
```

## 🎯 O que Cada Script Testa

### test-api.sh
- ✓ Health check Service A
- ✓ Health check Service B
- ✓ Acessibilidade Zipkin
- ✓ Conectividade OTEL
- ✓ API POST /cep com CEP válido
- ✓ Validação com CEP inválido
- ✓ Coleta de traces

### test-telemetry.sh
- ✓ Serviços registrados no Zipkin
- ✓ Estatísticas de traces e spans
- ✓ Últimos spans de cada serviço
- ✓ Exemplo de trace completo

## 🔗 URLs Importantes

| Serviço | URL | Descrição |
|---------|-----|-----------|
| Service A | http://localhost:8080 | Handler de CEP (entrada) |
| Service B | http://localhost:8081 | Orquestrador (temperatura) |
| Zipkin | http://localhost:9411 | Visualizador de traces |
| OTEL gRPC | localhost:4317 | Coleta de traces (gRPC) |
| OTEL HTTP | localhost:4318 | Coleta de traces (HTTP) |

## 📈 Fluxo de Teste Recomendado

```
1. Iniciar stack
   └─ ./start.sh

2. Testes funcionais
   └─ ./test-api.sh

3. Testar telemetria
   ├─ Fazer requisição POST /cep
   ├─ Aguardar 2 segundos
   └─ ./test-telemetry.sh ou abrir Zipkin

4. Testar logs em tempo real
   └─ docker compose logs -f

5. Testar múltiplos CEPs
   └─ Ver responses esperadas

6. Parar stack
   └─ ./stop.sh
```

## ⚠️ Troubleshooting Rápido

| Problema | Solução |
|----------|---------|
| Sem resposta em /health | Verificar: `docker compose ps` |
| API retorna erro | Ver: `docker compose logs service-a` |
| Sem traces no Zipkin | 1. Fazer requisição POST /cep<br>2. Aguardar 2s<br>3. Refreshar Zipkin |
| Erro 500 na temperatura | Verificar chave WeatherAPI em .env |
| Container não inicia | `docker compose logs` e ver erro |

## 📚 Documentação

- **TESTING.md** - Testes manuais passo a passo
- **TELEMETRY.md** - Como funciona telemetria
- **TROUBLESHOOTING.md** - Soluções de problemas
- **README.md** - Visão geral do projeto
- **API.md** - Documentação dos endpoints

## 🎓 Próximos Passos

1. Explorar Zipkin UI para entender traces
2. Modificar spans nos serviços
3. Adicionar métricas customizadas
4. Configurar alertas (opcional)
5. Integrar com outras ferramentas (Grafana, etc)

---

**Dica:** Sempre execute `./test-api.sh` após mudanças para garantir que tudo continua funcionando! ✅
