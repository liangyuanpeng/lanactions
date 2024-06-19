package main

import (
	"context"
	"fmt"
	"log"
	"time"

	clientv3 "go.etcd.io/etcd/client/v3"
)

func main() {
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
