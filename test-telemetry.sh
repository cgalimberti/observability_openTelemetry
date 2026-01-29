#!/bin/bash

# Telemetry Testing Script
# Queries Zipkin for traces and displays them in a readable format

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═════════════════════════════════════════${NC}"
echo -e "${BLUE}   Telemetry Testing - Zipkin Traces${NC}"
echo -e "${BLUE}═════════════════════════════════════════${NC}\n"

# Function to query traces
get_traces() {
    local service=$1
    local limit=${2:-5}
    
    echo -e "${YELLOW}Querying traces for service: $service (limit: $limit)${NC}\n"
    
    curl -s "http://localhost:9411/api/v2/traces?serviceName=$service&limit=$limit" | \
    python3 << 'EOF'
import sys
import json

data = json.load(sys.stdin)

if not data:
    print("No traces found")
    sys.exit(0)

for trace_idx, trace in enumerate(data, 1):
    print(f"\n--- Trace #{trace_idx} ---")
    
    for span_idx, span in enumerate(trace, 1):
        trace_id = span.get('traceId', 'N/A')
        span_id = span.get('id', 'N/A')
        parent_id = span.get('parentId', 'root')
        name = span.get('name', 'unknown')
        duration = span.get('duration', 0) / 1000  # Convert to ms
        service = span.get('localEndpoint', {}).get('serviceName', 'unknown')
        
        # Indent if it has a parent
        indent = "  └─ " if parent_id != 'root' else "  ├─ "
        
        print(f"{indent}Span: {name}")
        print(f"    Service: {service}")
        print(f"    Duration: {duration:.2f}ms")
        print(f"    TraceID: {trace_id}")
        print(f"    SpanID: {span_id}")
        if parent_id != 'root':
            print(f"    ParentID: {parent_id}")
        
        tags = span.get('tags', {})
        if tags:
            print(f"    Tags:")
            for key, value in tags.items():
                print(f"      - {key}: {value}")
        
        print()
EOF
}

# List available services
echo -e "${YELLOW}Available Services:${NC}"
SERVICES=$(curl -s http://localhost:9411/api/v2/services)
echo "$SERVICES" | python3 -m json.tool | grep -E '^\s+"' | sed 's/"//g' | sed 's/,//g'

echo -e "\n${YELLOW}Select a service to view traces:${NC}\n"

# Get traces from both services
echo -e "${GREEN}=== Service A Traces ===${NC}"
get_traces "service-a" 3

echo -e "\n${GREEN}=== Service B Traces ===${NC}"
get_traces "service-b" 3

# Show span count
echo -e "\n${YELLOW}Trace Statistics:${NC}"
SPAN_COUNT_A=$(curl -s 'http://localhost:9411/api/v2/traces?serviceName=service-a&limit=100' | python3 -c "import sys, json; data=json.load(sys.stdin); print(sum(len(t) for t in data))" 2>/dev/null || echo "0")
SPAN_COUNT_B=$(curl -s 'http://localhost:9411/api/v2/traces?serviceName=service-b&limit=100' | python3 -c "import sys, json; data=json.load(sys.stdin); print(sum(len(t) for t in data))" 2>/dev/null || echo "0")

echo "Service A spans (last 100 traces): $SPAN_COUNT_A"
echo "Service B spans (last 100 traces): $SPAN_COUNT_B"

echo -e "\n${YELLOW}View Full Traces:${NC}"
echo "Open in browser: http://localhost:9411"
echo "Select service from dropdown and click 'Find Traces'"

echo -e "\n${BLUE}═════════════════════════════════════════${NC}\n"
