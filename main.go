package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"time"

	clientv3 "go.etcd.io/etcd/client/v3"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/propagation"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.25.0"
	"go.opentelemetry.io/otel/trace"
)

func main() {
	oteldemo()
}

var serviceName = semconv.ServiceNameKey.String("test-service")

// Initialize a gRPC connection to be used by both the tracer and meter
// providers.
func initConn() (*grpc.ClientConn, error) {
	// It connects the OpenTelemetry Collector through local gRPC connection.
	// You may replace `localhost:4317` with your endpoint.
	endpoint := "localhost:4317"
	endpoint = "localhost:5081" // openobserve
	conn, err := grpc.NewClient(endpoint,
		// Note the use of insecure transport here. TLS is recommended in production.
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		// grpc.WithAuthority("Basic YWRtaW5AbGFuazhzLmNuOmFkbWlu"),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create gRPC connection to collector: %w", err)
	}

	return conn, err
}

// Initializes an OTLP exporter, and configures the corresponding trace provider.
func initTracerProvider(ctx context.Context, res *resource.Resource, conn *grpc.ClientConn) (func(context.Context) error, error) {
	// Set up a trace exporter
	headers := make(map[string]string)
	headers["organization"] = "default"
	headers["stream-name"] = "trace_default"
	headers["Authorization"] = "Basic YWRtaW5AbGFuazhzLmNuOmFkbWlu"
	traceExporter, err := otlptracegrpc.New(ctx, otlptracegrpc.WithGRPCConn(conn), otlptracegrpc.WithHeaders(headers))
	if err != nil {
		return nil, fmt.Errorf("failed to create trace exporter: %w", err)
	}

	// Register the trace exporter with a TracerProvider, using a batch
	// span processor to aggregate spans before export.
	bsp := sdktrace.NewBatchSpanProcessor(traceExporter)
	tracerProvider := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
		sdktrace.WithResource(res),
		sdktrace.WithSpanProcessor(bsp),
	)
	otel.SetTracerProvider(tracerProvider)

	// Set global propagator to tracecontext (the default is no-op).
	otel.SetTextMapPropagator(propagation.TraceContext{})

	// Shutdown will flush any remaining spans and shut down the exporter.
	return tracerProvider.Shutdown, nil
}

// Initializes an OTLP exporter, and configures the corresponding meter provider.
func initMeterProvider(ctx context.Context, res *resource.Resource, conn *grpc.ClientConn) (func(context.Context) error, error) {
	headers := make(map[string]string)
	headers["organization"] = "default"
	headers["stream-name"] = "metrics_default"
	headers["Authorization"] = "Basic YWRtaW5AbGFuazhzLmNuOmFkbWlu"
	metricExporter, err := otlpmetricgrpc.New(ctx, otlpmetricgrpc.WithGRPCConn(conn), otlpmetricgrpc.WithHeaders(headers))
	if err != nil {
		return nil, fmt.Errorf("failed to create metrics exporter: %w", err)
	}

	meterProvider := sdkmetric.NewMeterProvider(
		sdkmetric.WithReader(sdkmetric.NewPeriodicReader(metricExporter)),
		sdkmetric.WithResource(res),
	)
	otel.SetMeterProvider(meterProvider)

	return meterProvider.Shutdown, nil
}

func oteldemo() {
	log.Printf("Waiting for connection...")

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	conn, err := initConn()
	if err != nil {
		log.Fatal(err)
	}

	res, err := resource.New(ctx,
		resource.WithAttributes(
			// The service name used to display traces in backends
			serviceName,
		),
	)
	if err != nil {
		log.Fatal(err)
	}

	shutdownTracerProvider, err := initTracerProvider(ctx, res, conn)
	if err != nil {
		log.Fatal(err)
	}
	defer func() {
		if err := shutdownTracerProvider(ctx); err != nil {
			log.Fatalf("failed to shutdown TracerProvider: %s", err)
		}
	}()

	shutdownMeterProvider, err := initMeterProvider(ctx, res, conn)
	if err != nil {
		log.Fatal(err)
	}
	defer func() {
		if err := shutdownMeterProvider(ctx); err != nil {
			log.Fatalf("failed to shutdown MeterProvider: %s", err)
		}
	}()

	tracer := otel.Tracer("test-tracer")
	meter := otel.Meter("test-meter")

	// Attributes represent additional key-value descriptors that can be bound
	// to a metric observer or recorder.
	commonAttrs := []attribute.KeyValue{
		attribute.String("attrA", "chocolate"),
		attribute.String("attrB", "raspberry"),
		attribute.String("attrC", "vanilla"),
	}

	runCount, err := meter.Int64Counter("run", metric.WithDescription("The number of times the iteration ran"))
	if err != nil {
		log.Fatal(err)
	}

	// Work begins
	ctx, span := tracer.Start(
		ctx,
		"CollectorExporter-Example",
		trace.WithAttributes(commonAttrs...))
	defer span.End()
	for i := 0; i < 10; i++ {
		_, iSpan := tracer.Start(ctx, fmt.Sprintf("Sample-%d", i))
		runCount.Add(ctx, 1, metric.WithAttributes(commonAttrs...))
		log.Printf("Doing really hard work (%d / 10)\n", i+1)

		<-time.After(time.Second)
		iSpan.End()
	}

	log.Printf("Done!")
}

func etcdtest() {
	config := clientv3.Config{
		Endpoints: []string{"192.168.66.2:3379"},
		// Endpoints: []string{"192.168.66.2:23379"},
		// Endpoints:   []string{"192.168.66.2:3379"},
		DialTimeout: 5 * time.Second,
	}
	client, err := clientv3.New(config)
	if err != nil {
		log.Fatal("init client error:", err)
	}

	fmt.Println(client.Cluster.MemberList(context.TODO()))
	resp, err := client.Maintenance.Status(context.TODO(), "http://192.168.66.2:3379")
	if err != nil {
		log.Fatal("Maintenance Status error:", err)
	}
	log.Println(resp.Version)

	err = client.Watcher.RequestProgress(context.TODO())

	if err != nil {
		log.Fatal("RequestProgress error:", err)
	}
	watchch := client.Watcher.Watch(context.TODO(), "/lan", clientv3.WithProgressNotify(), clientv3.WithPrefix())
	for {
		kv := <-watchch
		log.Println(kv)
	}

	// c := make(chan *kvresp, 100)
	// revmap := make(map[int64]string)
	// var mu sync.RWMutex
	// putdata(client, 6, c)
	// for {
	// 	x := <-c
	// 	mu.RLock()
	// 	if _, ok := revmap[x.reversion]; ok {
	// 		log.Fatalf("exist reversion:%d when working for key:%s !! \n", x.reversion, x.key)
	// 	}
	// 	revmap[x.reversion] = x.key
	// 	log.Printf("finished for key:%s and reversion:%d \n", x.key, x.reversion)
	// 	mu.RUnlock()
	// }
}

type kvresp struct {
	key       string
	reversion int64
}

func putdata(client *clientv3.Client, channelcount int, cc chan *kvresp) {

	sts := []string{"/kindtest/configmaps/namespace/cm2", "/kindtest/configmaps/namespace/cm1", "/kindtest/configmaps/namespace/cm3", "/kindtest/configmaps/namespace/cm4", "/kindtest/configmaps/namespace/cm5", "/kindtest/configmaps/namespace/cm6"}

	for i := 0; i < channelcount; i++ {
		go func(ic int) {
			for {
				k := sts[ic]
				resp, err := client.KV.Put(context.TODO(), k, "world1111111111111111kkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxpppppppppppppppppppppppppwwwwwwwwwwwwwwwwwwwwwwwwwwqqqqqqqqqqqqqqqqqqqqqqqq")
				if err != nil {
					log.Fatal("put data failed!", err)
				}
				cc <- &kvresp{
					reversion: resp.Header.Revision,
					key:       k,
				}
				// time.Sleep(200)
			}

		}(i)
	}
}
