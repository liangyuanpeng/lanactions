package main

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	clientv3 "go.etcd.io/etcd/client/v3"
)

func main() {
	log.Println("hello world")
	// 客户端配置
	config := clientv3.Config{
		// 节点配置
		// Endpoints: []string{"192.168.66.2:12379"},
		Endpoints: []string{"192.168.66.2:23379"},
		// Endpoints:   []string{"192.168.66.2:3379"},
		DialTimeout: 5 * time.Second,
	}
	// 建立连接
	client, err := clientv3.New(config)
	if err != nil {
		log.Fatal("init client error:", err)
	}

	// 输出集群信息
	fmt.Println(client.Cluster.MemberList(context.TODO()))
	// client.Close()
	c := make(chan *kvresp, 100)
	// c := make(chan *clientv3.PutResponse, 100)
	revmap := make(map[int64]string)
	var mu sync.RWMutex
	putdata(client, 6, c)
	for {
		x, _ := <-c
		mu.RLock()
		log.Println(x)
		// log.Println(x.Header.Revision)
		// log.Println(x)

		if _, ok := revmap[x.reversion]; ok {
			log.Fatalln("exist reversion for key!!", x)
		}

		revmap[x.reversion] = string(x.key)
		// revmap[x.Header.Revision] = string(x.PrevKv.Key)
		mu.RUnlock()
		// x = x.(*clientv3.PutResponse)

	}

}

type kvresp struct {
	key       string
	reversion int64
}

func putdata(client *clientv3.Client, channelcount int, cc chan *kvresp) {

	sts := []string{"/kindtest/configmaps/namespace/cm2", "/kindtest/configmaps/namespace/cm1", "/kindtest/configmaps/namespace/cm3", "/kindtest/configmaps/namespace/cm4", "/kindtest/configmaps/namespace/cm5", "/kindtest/configmaps/namespace/cm6"}

	count := 0
	b := 5

	for i := 0; i < channelcount; i++ {
		go func() {
			for {
				count++
				k := sts[i]
				c := count / b
				if c == 0 {
					client.Delete(context.TODO(), k)
				}
				resp, err := client.KV.Put(context.TODO(), k, "world1111111111111111kkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxpppppppppppppppppppppppppwwwwwwwwwwwwwwwwwwwwwwwwwwqqqqqqqqqqqqqqqqqqqqqqqq")
				if err != nil {
					log.Fatal("put data failed!", err)
				}
				cc <- &kvresp{
					reversion: resp.Header.Revision,
					key:       k,
				}
				// cc <- resp
				// log.Println("resp:", resp.Header.Revision)
				// time.Sleep(time.Second)
				time.Sleep(200)
			}

		}()
	}
}
