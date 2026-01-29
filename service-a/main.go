package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
	"go.opentelemetry.io/otel/trace"
)

const (
	serviceName = "service-a"
	port        = ":8080"
)

type CEPRequest struct {
	CEP string `json:"cep"`
}

type ErrorResponse struct {
	Message string `json:"message"`
}

type TemperatureResponse struct {
	City  string  `json:"city"`
	TempC float64 `json:"temp_C"`
	TempF float64 `json:"temp_F"`
	TempK float64 `json:"temp_K"`
}

var (
	tracer trace.Tracer
)

func initTracer() func(context.Context) error {
	exporter, err := otlptracehttp.New(context.Background(),
		otlptracehttp.WithEndpoint(getOTLPEndpoint()),
	)
	if err != nil {
		log.Fatalf("failed to create exporter: %v", err)
	}

	r, err := resource.New(context.Background(), resource.WithAttributes(
		semconv.ServiceName(serviceName),
	))
	if err != nil {
		log.Fatalf("failed to create resource: %v", err)
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(r),
	)
	otel.SetTracerProvider(tp)

	return tp.Shutdown
}

func getOTLPEndpoint() string {
	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if endpoint == "" {
		endpoint = "http://otel-collector:4318"
	}
	// Remove http:// prefix if present
	if len(endpoint) > 7 && endpoint[:7] == "http://" {
		return endpoint[7:]
	}
	if len(endpoint) > 8 && endpoint[:8] == "https://" {
		return endpoint[8:]
	}
	return endpoint
}

func validateCEP(cep string) bool {
	if len(cep) != 8 {
		return false
	}
	for _, ch := range cep {
		if ch < '0' || ch > '9' {
			return false
		}
	}
	return true
}

func handleCEP(w http.ResponseWriter, r *http.Request) {
	ctx, span := tracer.Start(r.Context(), "handleCEP")
	defer span.End()

	if r.Method != http.MethodPost {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(ErrorResponse{Message: "method not allowed"})
		return
	}

	var req CEPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(ErrorResponse{Message: "invalid request"})
		return
	}

	if !validateCEP(req.CEP) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnprocessableEntity)
		json.NewEncoder(w).Encode(ErrorResponse{Message: "invalid zipcode"})
		return
	}

	// Call Service B
	serviceB := getServiceBURL()
	serviceBResp, err := callServiceB(ctx, serviceB, req.CEP)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(ErrorResponse{Message: "internal server error"})
		return
	}

	defer serviceBResp.Body.Close()

	// Forward the response from Service B
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(serviceBResp.StatusCode)
	io.Copy(w, serviceBResp.Body)
}

func callServiceB(ctx context.Context, baseURL string, cep string) (*http.Response, error) {
	ctx, span := tracer.Start(ctx, "callServiceB")
	defer span.End()

	payload := CEPRequest{CEP: cep}
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, baseURL+"/weather", bytes.NewBuffer(payloadBytes))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	return client.Do(req)
}

func getServiceBURL() string {
	url := os.Getenv("SERVICE_B_URL")
	if url == "" {
		url = "http://service-b:8081"
	}
	return url
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func main() {
	shutdown := initTracer()
	defer shutdown(context.Background())

	tracer = otel.Tracer(serviceName)

	http.HandleFunc("/cep", handleCEP)
	http.HandleFunc("/health", healthCheck)

	fmt.Printf("Service A started on %s\n", port)
	log.Fatal(http.ListenAndServe(port, nil))
}
