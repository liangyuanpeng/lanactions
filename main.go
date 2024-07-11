package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"slices"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/go-github/v56/github"
	clientv3 "go.etcd.io/etcd/client/v3"
	"golang.org/x/oauth2"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"github.com/karmada-io/karmada/pkg/sharedcli/klogflag"
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
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	"k8s.io/apimachinery/pkg/util/sets"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	cliflag "k8s.io/component-base/cli/flag"
	"k8s.io/klog/v2"
)

func main() {
	// oteldemo()
	// svcdemo()
	// ghdemo()
	// preditdemo()
	// cancelghaction()
	latestReleaseRef()
}

type Vrefs struct {
	Vrefs []string `json:"refs"`
}

func latestReleaseRef() {

	fss := cliflag.NamedFlagSets{}

	// Set klog flags
	logsFlagSet := fss.FlagSet("logs")
	klogflag.Add(logsFlagSet)

	ghtoken := os.Getenv("GITHUB_TOKEN")
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: ghtoken},
	)
	tc := oauth2.NewClient(context.TODO(), ts)
	ghclient := github.NewClient(tc)

	owner := "kubernetes"
	repo := "kubernetes"

	refs, _, err := ghclient.Repositories.ListBranches(context.TODO(), owner, repo, &github.BranchListOptions{
		ListOptions: github.ListOptions{
			PerPage: 1000,
		},
	})
	if err != nil {
		panic(err)
	}

	lastReleasesTmp := sets.NewString()

	for _, refobj := range refs {
		ref := refobj.GetName()
		if !strings.HasPrefix(ref, "release-") {
			continue
		}
		if strings.HasPrefix(ref, "release-0") {
			continue
		}
		refversion := strings.ReplaceAll(ref, "release-1.", "")
		lastReleasesTmp.Insert(refversion)
		// if len(lastReleases) == 0 {
		// 	lastReleases = append(lastReleases, refversion)
		// }
		// newLastReleases := []string{}
		// for _, r := range lastReleases {
		// 	if len(newLastReleases) >= 3 {
		// 		break
		// 	}
		// 	if r == refversion {
		// 		continue
		// 	}
		// 	refversionsem, err := version.ParseSemantic(refversion)
		// 	if err != nil {
		// 		panic(err)
		// 	}
		// 	rversionsem, err := version.ParseSemantic(r)
		// 	if err != nil {
		// 		panic(err)
		// 	}

		// 	if !refversionsem.LessThan(rversionsem) {
		// 		newLastReleases = append(newLastReleases, refversion)
		// 	}

		// }
		// lastReleases = newLastReleases
		// log.Println("ref.name:", ref, lastReleases)

	}
	klog.V(4).Info(lastReleasesTmp.List())
	strs := lastReleasesTmp.List()
	// sort.Strings(strs)
	// log.Println(strs)
	// log.Println("sofr with slices............")
	// slices.Sort(strs)
	// log.Println(strs)

	lastReleasesNums := []int{}
	for _, s := range strs {
		v, err := strconv.Atoi(s)
		if err != nil {
			klog.V(4).ErrorS(err, "parse failed!")
			continue
		}
		lastReleasesNums = append(lastReleasesNums, v)
	}
	// sort.Ints(lastReleasesInts)
	sort.Ints(lastReleasesNums)
	// slices.Sort(lastReleasesInts)
	klog.V(4).Info(lastReleasesNums)

	klog.V(4).Info("sort with slices............")
	slices.Sort(lastReleasesNums)
	klog.V(4).Info(lastReleasesNums)

	lastReleases := sets.NewString()

	for i := len(lastReleasesNums) - 1; i > 0; i-- {
		v := lastReleasesNums[i]
		refv := fmt.Sprintf("release-1.%d", v)
		lastReleases.Insert(refv)
		if lastReleases.Len() >= 3 {
			break
		}
	}

	lastReleases.Insert("master")
	klog.V(4).Info(lastReleases.List())
	vrefs := &Vrefs{
		Vrefs: lastReleases.List(),
	}
	klog.V(4).Info("vrefs:", vrefs)
	data, err3 := json.Marshal(vrefs)
	if err3 != nil {
		fmt.Println(err)
	}
	fmt.Println(string(data))

}

func cancelghaction() {
	ghtoken := os.Getenv("GITHUB_TOKEN")
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: ghtoken},
	)
	tc := oauth2.NewClient(context.TODO(), ts)
	ghclient := github.NewClient(tc)

	owner := "liangyuanpeng"
	repo := "etcd"

	wfs, _, err := ghclient.Actions.ListWorkflows(context.TODO(), owner, repo, &github.ListOptions{})
	if err != nil {
		panic(err)
	}

	for _, wf := range wfs.Workflows {
		wfrs, _, err := ghclient.Actions.ListWorkflowRunsByID(context.TODO(), owner, repo, wf.GetID(), &github.ListWorkflowRunsOptions{})
		if err != nil {
			panic(err)
		}

		for _, wfr := range wfrs.WorkflowRuns {
			klog.Info("cancel wf:", wf.GetName(), wfr.GetID(), wfr.GetStatus())
			if wfr.GetStatus() == "in_progress" || wfr.GetStatus() == "queued" {
				_, err = ghclient.Actions.CancelWorkflowRunByID(context.TODO(), owner, repo, wfr.GetID())
				if err != nil {
					klog.Infof("cancel wf %s|%v failed!\n", wf.GetName(), wfr.GetID(), err)
				}
			}

		}

	}

}

func svcdemo() {

	// k8s.io/api v0.28.5
	// k8s.io/api v0.29.4
	// k8s.io/api v0.30.2

	config := "/home/runner/work/lanactions/lanactions/k8s26config"
	config = "/home/runner/.kube/config"
	restConfig, err := clientcmd.BuildConfigFromFlags("", config)
	if err != nil {
		panic(err)
	}
	clientSet, err := kubernetes.NewForConfig(restConfig)
	if err != nil {
		panic(err)
	}
	ns := "default"
	svcname := "test"

	aaService := &corev1.Service{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "v1",
			Kind:       "Service",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      svcname,
			Namespace: ns,
		},
		Spec: corev1.ServiceSpec{
			Type: corev1.ServiceTypeLoadBalancer,
			Ports: []corev1.ServicePort{
				{
					Name:       "http",
					Protocol:   corev1.ProtocolTCP,
					Port:       80,
					TargetPort: intstr.IntOrString{IntVal: 80},
				},
			},
			Selector: map[string]string{"app": "nginx"},
		},
	}

	clientSet.CoreV1().Services(ns).Delete(context.TODO(), svcname, metav1.DeleteOptions{})

	rsvc, err := clientSet.CoreV1().Services(ns).Create(context.TODO(), aaService, metav1.CreateOptions{})
	if err != nil {
		panic(err)
	}

	//, IPMode: ptr.To(corev1.LoadBalancerIPModeVIP)
	ingresses := []corev1.LoadBalancerIngress{{IP: fmt.Sprintf("172.19.1.%d", 1+6)}}
	rsvc.Status.LoadBalancer = corev1.LoadBalancerStatus{Ingress: ingresses}
	_, err = clientSet.CoreV1().Services(ns).UpdateStatus(context.TODO(), rsvc, metav1.UpdateOptions{})
	if err != nil {
		panic(err)
	}

	latestSvc, err := clientSet.CoreV1().Services(ns).Get(context.TODO(), svcname, metav1.GetOptions{})
	if err != nil {
		panic(err)
	}

	klog.Infof("the latest serviceStatus loadBalancer: %v", latestSvc.Status.LoadBalancer)
	if latestSvc.Status.LoadBalancer.Ingress[0].IPMode != nil {
		klog.Infof("ipmode:%v", *latestSvc.Status.LoadBalancer.Ingress[0].IPMode)
	}

}

func preditdemo() {
	ghtoken := os.Getenv("GITHUB_TOKEN")
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: ghtoken},
	)
	tc := oauth2.NewClient(context.TODO(), ts)
	ghclient := github.NewClient(tc)

	owner := "liangyuanpeng"
	repo := "karmada"
	prnum := 65
	// ^^^ can read it from prowjob env

	pr, _, err := ghclient.PullRequests.Get(context.TODO(), owner, repo, prnum)
	if err != nil {
		panic(err)
	}

	releaseNote := "The base image `alpine` has been bumped from 3.20.0 to 3.20.1 "
	// parse title to get it ^^^

	newbody := pr.GetBody() + "```release-note\n  " + releaseNote + ".  \n```"
	updatepr := &github.PullRequest{
		Body: &newbody,
	}

	_, _, err = ghclient.PullRequests.Edit(context.TODO(), owner, repo, prnum, updatepr)
	if err != nil {
		panic(err)
	}

}

func ghdemo() {
	ghtoken := os.Getenv("GITHUB_TOKEN")
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: ghtoken},
	)
	tc := oauth2.NewClient(context.TODO(), ts)
	ghclient := github.NewClient(tc)
	reporesp, _, err := ghclient.Repositories.GetReleaseByTag(context.TODO(), "karmada-io", "karmada", "v1.9.1")
	if err != nil {
		panic(err)
	}
	log.Println("reporesp:", reporesp.GetTargetCommitish())

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
