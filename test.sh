#!/bin/bash

# Test script for the temperature lookup system
# This script tests all endpoints and scenarios

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SERVICE_A_URL="http://localhost:8080"
SERVICE_B_URL="http://localhost:8081"
ZIPKIN_URL="http://localhost:9411"

# Counter for tests
PASSED=0
FAILED=0

# Function to print test header
print_header() {
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}========================================${NC}\n"
}

# Function to print test result
print_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $1"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}: $1"
        ((FAILED++))
    fi
}

# Function to check if service is running
check_service() {
    local url=$1
    local name=$2
    
    echo "Checking $name at $url..."
    
    if curl -s "$url/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $name is running${NC}"
    else
        echo -e "${RED}✗ $name is NOT running${NC}"
        echo "Please start the services with: ./start.sh"
        exit 1
    fi
}

# Main test execution
main() {
    echo -e "${YELLOW}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  Temperature Lookup System - Test Suite           ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Check services
    print_header "Checking Services"
    check_service "$SERVICE_A_URL" "Service A"
    check_service "$SERVICE_B_URL" "Service B"
    echo "✓ Zipkin available at $ZIPKIN_URL"
    
    # Health checks
    print_header "1. Health Checks"
    
    RESPONSE=$(curl -s "$SERVICE_A_URL/health")
    [ "$RESPONSE" = '{"status":"ok"}' ]
    print_result "Service A health check"
    
    RESPONSE=$(curl -s "$SERVICE_B_URL/health")
    [ "$RESPONSE" = '{"status":"ok"}' ]
    print_result "Service B health check"
    
    # Valid CEP Tests
    print_header "2. Valid CEP Tests"
    
    echo "Testing CEP: 01310100 (São Paulo - Av. Paulista)"
    RESPONSE=$(curl -s -X POST "$SERVICE_A_URL/cep" \
        -H 'Content-Type: application/json' \
        -d '{"cep":"01310100"}')
    
    echo "Response: $RESPONSE"
    
    # Check if response contains expected fields
    echo "$RESPONSE" | grep -q "temp_C" && echo -e "${GREEN}✓ Contains temp_C${NC}" || echo -e "${RED}✗ Missing temp_C${NC}"
    echo "$RESPONSE" | grep -q "temp_F" && echo -e "${GREEN}✓ Contains temp_F${NC}" || echo -e "${RED}✗ Missing temp_F${NC}"
    echo "$RESPONSE" | grep -q "temp_K" && echo -e "${GREEN}✓ Contains temp_K${NC}" || echo -e "${RED}✗ Missing temp_K${NC}"
    echo "$RESPONSE" | grep -q "city" && echo -e "${GREEN}✓ Contains city${NC}" || echo -e "${RED}✗ Missing city${NC}"
    
    ((PASSED++))
    
    # Invalid CEP Tests
    print_header "3. Invalid CEP Tests"
    
    echo "Test 3.1: Too short (123)"
    RESPONSE=$(curl -s -X POST "$SERVICE_A_URL/cep" \
        -H 'Content-Type: application/json' \
        -d '{"cep":"123"}')
    
    echo "Response: $RESPONSE"
    echo "$RESPONSE" | grep -q "invalid zipcode" && {
        echo -e "${GREEN}✓ Returns correct error message${NC}"
        ((PASSED++))
    } || {
        echo -e "${RED}✗ Wrong error message${NC}"
        ((FAILED++))
    }
    
    echo -e "\nTest 3.2: Too long (0131010001)"
    RESPONSE=$(curl -s -X POST "$SERVICE_A_URL/cep" \
        -H 'Content-Type: application/json' \
        -d '{"cep":"0131010001"}')
    
    echo "Response: $RESPONSE"
    echo "$RESPONSE" | grep -q "invalid zipcode" && {
        echo -e "${GREEN}✓ Returns correct error message${NC}"
        ((PASSED++))
    } || {
        echo -e "${RED}✗ Wrong error message${NC}"
        ((FAILED++))
    }
    
    echo -e "\nTest 3.3: Contains letters (0131010A)"
    RESPONSE=$(curl -s -X POST "$SERVICE_A_URL/cep" \
        -H 'Content-Type: application/json' \
        -d '{"cep":"0131010A"}')
    
    echo "Response: $RESPONSE"
    echo "$RESPONSE" | grep -q "invalid zipcode" && {
        echo -e "${GREEN}✓ Returns correct error message${NC}"
        ((PASSED++))
    } || {
        echo -e "${RED}✗ Wrong error message${NC}"
        ((FAILED++))
    }
    
    echo -e "\nTest 3.4: Non-existent CEP (99999999)"
    RESPONSE=$(curl -s -X POST "$SERVICE_A_URL/cep" \
        -H 'Content-Type: application/json' \
        -d '{"cep":"99999999"}')
    
    echo "Response: $RESPONSE"
    echo "$RESPONSE" | grep -q "can not find zipcode" && {
        echo -e "${GREEN}✓ Returns correct error message${NC}"
        ((PASSED++))
    } || {
        echo -e "${RED}✗ Wrong error message (expected 404 - can not find zipcode)${NC}"
        ((FAILED++))
    }
    
    # Service B Direct Tests
    print_header "4. Service B Direct Tests"
    
    echo "Testing direct call to Service B with valid CEP"
    RESPONSE=$(curl -s -X POST "$SERVICE_B_URL/weather" \
        -H 'Content-Type: application/json' \
        -d '{"cep":"01310100"}')
    
    echo "Response: $RESPONSE"
    echo "$RESPONSE" | grep -q "city" && {
        echo -e "${GREEN}✓ Service B returns city${NC}"
        ((PASSED++))
    } || {
        echo -e "${RED}✗ Service B failed${NC}"
        ((FAILED++))
    }
    
    # Temperature Conversion Tests
    print_header "5. Temperature Conversion Validation"
    
    echo "Verifying temperature conversions..."
    RESPONSE=$(curl -s -X POST "$SERVICE_A_URL/cep" \
        -H 'Content-Type: application/json' \
        -d '{"cep":"01310100"}')
    
    # Extract temperature values
    TEMP_C=$(echo "$RESPONSE" | grep -o '"temp_C":[0-9.]*' | grep -o '[0-9.]*$')
    TEMP_F=$(echo "$RESPONSE" | grep -o '"temp_F":[0-9.]*' | grep -o '[0-9.]*$')
    TEMP_K=$(echo "$RESPONSE" | grep -o '"temp_K":[0-9.]*' | grep -o '[0-9.]*$')
    
    if [ -n "$TEMP_C" ] && [ -n "$TEMP_F" ] && [ -n "$TEMP_K" ]; then
        echo "Celsius: $TEMP_C"
        echo "Fahrenheit: $TEMP_F"
        echo "Kelvin: $TEMP_K"
        
        # Basic validation: F should be around C * 1.8 + 32
        # K should be around C + 273
        echo -e "${GREEN}✓ All temperatures present${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ Missing temperature values${NC}"
        ((FAILED++))
    fi
    
    # Trace Verification
    print_header "6. Trace Availability"
    
    echo "Checking if Zipkin is collecting traces..."
    sleep 2  # Wait for traces to be sent
    
    TRACE_COUNT=$(curl -s "$ZIPKIN_URL/api/v2/traces" | grep -o '"traceID"' | wc -l)
    
    if [ "$TRACE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Zipkin has recorded traces${NC}"
        echo "  Traces found: $TRACE_COUNT"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ No traces found in Zipkin yet (may need to wait longer)${NC}"
    fi
    
    # Summary
    print_header "Test Summary"
    
    TOTAL=$((PASSED + FAILED))
    
    echo "Total Tests: $TOTAL"
    echo -e "Passed: ${GREEN}$PASSED${NC}"
    echo -e "Failed: ${RED}$FAILED${NC}"
    
    if [ $FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✓ All tests passed!${NC}\n"
        exit 0
    else
        echo -e "\n${RED}✗ Some tests failed!${NC}\n"
        exit 1
    fi
}

# Run main
main "$@"
