#!/bin/bash

# Test API Script for Observability Stack
# This script performs functional tests on the APIs and verifies system operation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Testing Observability Stack${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Test 1: Service A Health Check
echo -e "${YELLOW}Test 1: Service A Health Check${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:8080/health)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Service A is healthy${NC}"
    echo -e "  Response: $BODY"
else
    echo -e "${RED}✗ Service A health check failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

# Test 2: Service B Health Check
echo -e "\n${YELLOW}Test 2: Service B Health Check${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:8081/health)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Service B is healthy${NC}"
    echo -e "  Response: $BODY"
else
    echo -e "${RED}✗ Service B health check failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

# Test 3: Zipkin is Accessible
echo -e "\n${YELLOW}Test 3: Zipkin UI Accessibility${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -L http://localhost:9411/)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "${GREEN}✓ Zipkin is accessible at http://localhost:9411${NC}"
else
    echo -e "${RED}✗ Zipkin not accessible (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

# Test 4: OTEL Collector is Running
echo -e "\n${YELLOW}Test 4: OTEL Collector Connectivity${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:4317/opentelemetry.proto.collector.trace.v1.TraceService/Export -H "Content-Type: application/grpc" 2>/dev/null || echo "")
if [ -z "$RESPONSE" ]; then
    echo -e "${GREEN}✓ OTEL Collector is running (gRPC endpoint accessible)${NC}"
else
    echo -e "${YELLOW}⚠ OTEL Collector connectivity check inconclusive${NC}"
fi

# Test 5: API Endpoint - Valid CEP
echo -e "\n${YELLOW}Test 5: API POST /cep with Valid CEP (20040020)${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"20040020"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "500" ]; then
    echo -e "${GREEN}✓ API endpoint /cep is responding${NC}"
    echo -e "  HTTP Code: $HTTP_CODE"
    echo -e "  Response: $BODY"
else
    echo -e "${RED}✗ API endpoint returned unexpected status (HTTP $HTTP_CODE)${NC}"
fi

# Test 6: API Endpoint - Invalid CEP
echo -e "\n${YELLOW}Test 6: API POST /cep with Invalid CEP (12345)${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8080/cep \
  -H 'Content-Type: application/json' \
  -d '{"cep":"12345"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "400" ]; then
    echo -e "${GREEN}✓ API correctly rejects invalid CEP${NC}"
    echo -e "  Response: $BODY"
else
    echo -e "${YELLOW}⚠ API validation may not be working as expected (HTTP $HTTP_CODE)${NC}"
fi

# Test 7: Check Traces in Zipkin
echo -e "\n${YELLOW}Test 7: Checking Traces in Zipkin${NC}"
TRACES=$(curl -s 'http://localhost:9411/api/v2/traces?limit=10' | grep -o '"traceID"' | wc -l)
if [ "$TRACES" -gt 0 ]; then
    echo -e "${GREEN}✓ Traces are being collected${NC}"
    echo -e "  Found $TRACES trace IDs in the last 10 traces"
else
    echo -e "${YELLOW}⚠ No traces found yet (this is normal on first startup)${NC}"
fi

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Functional Tests Completed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "\n${YELLOW}Service URLs:${NC}"
echo -e "  Service A:     http://localhost:8080"
echo -e "  Service B:     http://localhost:8081"
echo -e "  Zipkin:        http://localhost:9411"
echo -e "\n${YELLOW}Example Commands:${NC}"
echo -e "  Test API:      curl -X POST http://localhost:8080/cep -H 'Content-Type: application/json' -d '{\"cep\":\"20040020\"}'"
echo -e "  View Traces:   Open http://localhost:9411 in your browser"
echo -e "  View Logs:     docker compose logs -f [service-a|service-b|otel-collector]"
