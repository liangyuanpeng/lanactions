package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"slices"
	"sort"
	"strconv"
	"strings"

	"github.com/google/go-github/v56/github"
	"golang.org/x/oauth2"

	"github.com/karmada-io/karmada/pkg/sharedcli/klogflag"
	"k8s.io/apimachinery/pkg/util/sets"
	cliflag "k8s.io/component-base/cli/flag"
	"k8s.io/klog/v2"
)

func main() {
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
