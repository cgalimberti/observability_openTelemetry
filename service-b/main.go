package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
	"go.opentelemetry.io/otel/trace"
)

const (
	serviceName = "service-b"
	port        = ":8081"
)

type CEPRequest struct {
	CEP string `json:"cep"`
}

type WeatherResponse struct {
	Current struct {
		TempC float64 `json:"temp_c"`
	} `json:"current"`
}

type ViaCEPResponse struct {
	Localidade string `json:"localidade"`
	Erro       bool   `json:"erro"`
}

type TemperatureResponse struct {
	City  string  `json:"city"`
	TempC float64 `json:"temp_C"`
	TempF float64 `json:"temp_F"`
	TempK float64 `json:"temp_K"`
}

type ErrorResponse struct {
	Message string `json:"message"`
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

func getWeatherAPIKey() string {
	key := os.Getenv("WEATHER_API_KEY")
	if key == "" {
		log.Println("Warning: WEATHER_API_KEY not set, using default test key")
		key = "test_key"
	}
	return key
}

func lookupCEP(ctx context.Context, cep string) (string, error) {
	ctx, span := tracer.Start(ctx, "lookupCEP")
	defer span.End()

	url := fmt.Sprintf("https://viacep.com.br/ws/%s/json/", cep)

	client := &http.Client{
		Timeout:   5 * time.Second,
		Transport: otelhttp.NewTransport(http.DefaultTransport),
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}

	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	var viaCepResp ViaCEPResponse
	if err := json.NewDecoder(resp.Body).Decode(&viaCepResp); err != nil {
		return "", err
	}

	if viaCepResp.Erro {
		return "", fmt.Errorf("cep not found")
	}

	if viaCepResp.Localidade == "" {
		return "", fmt.Errorf("localidade not found")
	}

	return viaCepResp.Localidade, nil
}

func getTemperature(ctx context.Context, city string) (float64, error) {
	ctx, span := tracer.Start(ctx, "getTemperature")
	defer span.End()

	apiKey := getWeatherAPIKey()
	// Properly encode the query parameters
	params := url.Values{}
	params.Add("key", apiKey)
	params.Add("q", city)
	params.Add("aqi", "no")
	url := fmt.Sprintf("https://api.weatherapi.com/v1/current.json?%s", params.Encode())

	client := &http.Client{
		Timeout:   5 * time.Second,
		Transport: otelhttp.NewTransport(http.DefaultTransport),
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return 0, err
	}

	resp, err := client.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return 0, fmt.Errorf("weather API error: %s", string(body))
	}

	var weatherResp WeatherResponse
	if err := json.NewDecoder(resp.Body).Decode(&weatherResp); err != nil {
		return 0, err
	}

	return weatherResp.Current.TempC, nil
}

func convertTemperatures(celsius float64) (fahrenheit, kelvin float64) {
	fahrenheit = celsius*1.8 + 32
	kelvin = celsius + 273
	return
}

func handleWeather(w http.ResponseWriter, r *http.Request) {
	ctx, span := tracer.Start(r.Context(), "handleWeather")
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

	if len(req.CEP) != 8 {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnprocessableEntity)
		json.NewEncoder(w).Encode(ErrorResponse{Message: "invalid zipcode"})
		return
	}

	// Lookup CEP
	city, err := lookupCEP(ctx, req.CEP)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(ErrorResponse{Message: "can not find zipcode"})
		return
	}

	// Get temperature
	tempC, err := getTemperature(ctx, city)
	if err != nil {
		log.Printf("Error getting temperature: %v\n", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(ErrorResponse{Message: "failed to get temperature"})
		return
	}

	tempF, tempK := convertTemperatures(tempC)

	response := TemperatureResponse{
		City:  city,
		TempC: tempC,
		TempF: tempF,
		TempK: tempK,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
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

	http.HandleFunc("/weather", handleWeather)
	http.HandleFunc("/health", healthCheck)

	fmt.Printf("Service B started on %s\n", port)
	log.Fatal(http.ListenAndServe(port, nil))
}
