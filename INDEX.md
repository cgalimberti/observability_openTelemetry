# ÍNDICE - Sistema de Temperatura por CEP com OpenTelemetry e Zipkin

## 📚 Referência Completa de Arquivos

### 📖 Arquivos de Documentação (8 arquivos)

1. **README.md** - Começa Aqui
   - Documentação completa do sistema
   - Todas as instruções de setup
   - Exemplos de uso da API
   - Guia de troubleshooting
   - Melhor para: Referência completa

2. **QUICKSTART.md** - Começo Rápido (5 minutos)
   - Instruções mínimas de setup
   - Comandos de teste rápido
   - Problemas comuns
   - Melhor para: Começar rápido

3. **API.md** - Referência de Endpoints
   - Documentação completa da API
   - Exemplos de requisição/resposta
   - Códigos de erro e cenários
   - Exemplos de SDK
   - Melhor para: Integração com API

4. **ARCHITECTURE.md** - Design do Sistema
   - Diagrama da arquitetura do sistema
   - Detalhes dos componentes
   - Fluxo de dados
   - Hierarquia de spans
   - Melhor para: Entender o design

5. **DEVELOPMENT.md** - Guia do Desenvolvedor
   - Setup de desenvolvimento
   - Instruções de build
   - Dicas de debug
   - Exemplos de modificação de código
   - Melhor para: Desenvolvimento de código

6. **TROUBLESHOOTING.md** - Resolução de Problemas
   - Problemas comuns e correções
   - Procedimentos de debug
   - Passos de recuperação
   - Troubleshooting detalhado
   - Melhor para: Resolver problemas

7. **PROJECT_SUMMARY.md** - Visão Geral do Projeto
   - Checklist do projeto
   - Conformidade com requisitos
   - Stack de tecnologias
   - Conquistas principais
   - Melhor para: Status do projeto

8. **COMPLETE_GUIDE.md** - Guia Completo de Implementação
   - Guia passo-a-passo completo
   - Detalhes de arquitetura
   - Informações de deployment
   - Melhor para: Entendimento completo

---

## 💻 Código Fonte (2 Serviços Go)

#### Service A - Validador de Entrada
- **service-a/main.go** (400+ linhas)
  - Servidor HTTP na porta 8080
  - Validação de CEP (8 dígitos, string)
  - Encaminhamento pro Service B
  - Spans OpenTelemetry
  - Endpoints: POST /cep, GET /health

- **service-a/go.mod**
  - Definição do módulo
  - Dependências OpenTelemetry

- **service-a/go.sum**
  - Checksums das dependências

- **service-a/Dockerfile**
  - Build multi-stage
  - Imagem otimizada pra produção

#### Service B - Orquestração
- **service-b/main.go** (400+ linhas)
  - Servidor HTTP na porta 8081
  - Integração com API viaCEP
  - Integração com WeatherAPI
  - Conversão de temperatura
  - Instrumentação OpenTelemetry
  - Endpoints: POST /weather, GET /health

- **service-b/go.mod**
  - Definição do módulo
  - Todas as dependências

- **service-b/go.sum**
  - Checksums das dependências

- **service-b/Dockerfile**
  - Build multi-stage
  - Imagem otimizada

---

### 🐳 Docker e Orquestração (4 arquivos)

1. **docker-compose.yml**
   - 4 serviços: Service A, Service B, OTEL Collector, Zipkin
   - Configuração de rede
   - Mapeamento de portas
   - Montagem de volumes
   - Variáveis de ambiente
   - Dependências de serviços

2. **otel-collector-config.yml**
   - Receivers OTLP (gRPC e HTTP)
   - Processador em lote
   - Exportador Zipkin
   - Configuração de pipeline de trace

3. **.env**
   - Variáveis de ambiente
   - Chave WeatherAPI (template)
   - Configuração do endpoint OTEL
   - URLs dos serviços

4. **.gitignore**
   - Exclusões de binários
   - Arquivos de IDE
   - Saídas de build
   - Arquivos de ambiente

---

### 🚀 Scripts de Execução (3 arquivos)

1. **start.sh**
   - Inicia todos os serviços
   - Aguarda prontidão
   - Exibe URLs dos serviços
   - Mostra exemplos de testes
   - Exibe informações de acesso ao Zipkin

2. **stop.sh**
   - Para todos os serviços
   - Limpa containers

3. **test.sh**
   - Suite de testes automatizada
   - Health checks
   - Testes de CEP válido
   - Testes de entrada inválida
   - Testes de tratamento de erro
   - Testes de conversão de temperatura
   - Verificação de trace

---

### ⚙️ Configuration Files

1. **.env**
   - WEATHER_API_KEY (required)
   - OTEL_EXPORTER_OTLP_ENDPOINT (optional)
   - SERVICE_B_URL (optional)

2. **.gitignore**
   - Binary files
   - IDE files
   - Environment files
   - Git files

---

## 📋 Guia Rápido de Navegação

### Pra Começar
1. Lê: **QUICKSTART.md** (5 minutos)
2. Roda: `./start.sh`
3. Testa: `curl -X POST http://localhost:8080/cep ...`
4. Visualiza: Abre http://localhost:9411

### Pra Entender o Sistema
1. Lê: **README.md** (visão geral completa)
2. Revisa: **ARCHITECTURE.md** (design do sistema)
3. Estuda: Código dos serviços em **service-a/main.go** e **service-b/main.go**

### Pra Integração com API
1. Referência: **API.md** (todos os endpoints)
2. Exemplos: Comandos curl e SDKs
3. Códigos de erro: Códigos de resposta e mensagens

### Pra Desenvolvimento
1. Setup: **DEVELOPMENT.md**
2. Build: Instruções de build Go
3. Debug: Usando docker exec e logs

### Pra Resolver Problemas
1. Primeiro: **TROUBLESHOOTING.md**
2. Checa: Logs com `docker-compose logs`
3. Roda: `./test.sh` pra verificação

### Pra Deploy
1. Checa: **PROJECT_SUMMARY.md** pra requisitos
2. Revisa: **COMPLETE_GUIDE.md** pra deployment
3. Configura: Variáveis de ambiente

---

## 📊 O Que Cada Arquivo Faz

| Arquivo | Propósito | Quando Usar |
|---------|-----------|------------|
| README.md | Documentação completa | Pra entender tudo |
| QUICKSTART.md | Setup rápido | Primeira vez |
| API.md | Referência de endpoint | Construindo clientes API |
| ARCHITECTURE.md | Design do sistema | Entendendo o design |
| DEVELOPMENT.md | Guia do dev | Modificando código |
| TROUBLESHOOTING.md | Correção de problemas | Resolvendo problemas |
| PROJECT_SUMMARY.md | Visão geral do projeto | Status do projeto |
| COMPLETE_GUIDE.md | Guia completo | Entendimento profundo |
| main.go (ambos) | Código do serviço | Entendo a implementação |
| docker-compose.yml | Orquestração de serviços | Rodando os serviços |
| otel-collector-config.yml | Config de tracing | Coleta de traces |
| .env | Setup de ambiente | Configuração |
| start.sh | Inicia serviços | Rodando o sistema |
| stop.sh | Para serviços | Desligando |
| test.sh | Suite de testes | Validação |

---

## 🎯 Tarefas Comuns

### Roda o Sistema
```bash
cp .env .env.local
# Edita .env.local - Adiciona WEATHER_API_KEY
./start.sh
```

### Testa a API
```bash
./test.sh
# Ou manualmente:
curl -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"01310100"}'
```

### Visualiza Traces
```
Abre http://localhost:9411 no navegador
```

### Checa os Logs
```bash
docker-compose logs -f
docker-compose logs -f service-a
docker-compose logs -f service-b
```

### Para os Serviços
```bash
./stop.sh
```

### Roda os Testes
```bash
./test.sh
```

---

## 📈 Estatísticas de Arquivos

| Categoria | Contagem |
|-----------|----------|
| Documentação | 8 |
| Arquivos Código Go | 2 |
| Arquivos Módulo Go | 4 (2 mod + 2 sum) |
| Arquivos Docker | 2 |
| Configuração | 3 |
| Scripts | 3 |
| **Total** | **24** |

---

## 🔍 Links Rápidos de Acesso aos Arquivos

### Documentação
- [README.md](README.md) - Documentação completa
- [QUICKSTART.md](QUICKSTART.md) - Começo rápido
- [API.md](API.md) - Referência de API
- [ARCHITECTURE.md](ARCHITECTURE.md) - Design do sistema
- [DEVELOPMENT.md](DEVELOPMENT.md) - Guia do dev
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Correção de problemas
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Visão geral
- [COMPLETE_GUIDE.md](COMPLETE_GUIDE.md) - Guia completo

### Código
- [service-a/main.go](service-a/main.go) - Service A
- [service-b/main.go](service-b/main.go) - Service B

### Configuração
- [docker-compose.yml](docker-compose.yml) - Orquestração
- [otel-collector-config.yml](otel-collector-config.yml) - Tracing
- [.env](.env) - Ambiente

### Scripts
- [start.sh](start.sh) - Inicia serviços
- [stop.sh](stop.sh) - Para serviços
- [test.sh](test.sh) - Roda testes

---

## ✅ Todos os Arquivos Presentes

✅ 8 arquivos de documentação
✅ 2 arquivos de código fonte Go
✅ 4 arquivos de módulo Go
✅ 2 arquivos Dockerfile
✅ 3 arquivos de configuração
✅ 3 arquivos de script

**Total: 24 Arquivos do Projeto - Completo & Pronto**

---

## 🚀 Próximos Passos

1. **Escolha seu caminho:**
   - Começo rápido → Lê QUICKSTART.md
   - Entendimento completo → Lê README.md
   - Integração com API → Lê API.md
   - Desenvolvimento → Lê DEVELOPMENT.md

2. **Roda o sistema:**
   ```bash
   ./start.sh
   ```

3. **Testa:**
   ```bash
   ./test.sh
   ```

4. **Explora os traces:**
   - Abre http://localhost:9411

---

## 📞 Organização de Documentos

Este arquivo INDEX fornece um mapa de todos os arquivos do projeto:
- **O que tem em cada arquivo**
- **Quando usar cada arquivo**
- **Navegação entre arquivos**
- **Links de acesso rápido**

Começa com **QUICKSTART.md** pra o caminho mais rápido pra rodar o sistema, ou **README.md** pra informações completas.

---

**Status do Projeto: Completo ✅**
**Pronto pra Deploy: Sim ✅**
**Todos os Requisitos Atendidos: Sim ✅**
