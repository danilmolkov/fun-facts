package main

import (
	"encoding/json"
	"flag"
	"log"
	"math/rand/v2"
	"net/http"
	"strconv"

	"github.com/go-redis/redis"
)

var client *redis.Client

func receiveJSONHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, http.StatusText(http.StatusMethodNotAllowed), http.StatusMethodNotAllowed)
		return
	}
	// ctx := context.Background()
	// var, err := client
	factsSize, err := client.LLen("fun-facts").Result()
	if err != nil {
		log.Print("Can't connect to redis!")
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}
	currentFactIndex := rand.Int64N(factsSize)
	val, err := client.Get(strconv.FormatInt(currentFactIndex, 10)).Result()
	if err != nil {
		panic(err)
	}
	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	type Message struct {
		Num  int64  `json:"number"`
		Fact string `json:"fact"`
	}
	b, err := json.Marshal(Message{currentFactIndex + 1 /* index to number */, val})
	if err != nil {
		panic(err)
	}
	w.Write(b)
}

func StartRedis(redisAddress *string) {
	log.Printf("Connecting to Redis on %s ", *redisAddress)
	client = redis.NewClient(&redis.Options{
		Addr:     *redisAddress,
		Password: "",
		DB:       0,
	})
	if client == nil {
		log.Fatal("Could not connect to Redis")
	}
}

func main() {
	log.Print("Starting server")
	redisAddress := flag.String("redisAddress", "localhost:6379", "Address to Redis Server")
	flag.Parse()
	StartRedis(redisAddress)
	mux := http.NewServeMux()
	fs := http.FileServer(http.Dir("/var/funfacts/static"))
	// routes
	mux.HandleFunc("/api/v1/randomFact", receiveJSONHandler)
	mux.Handle("/", fs)
	log.Print("Server started")

	// Bind to a port and pass our router in
	err := http.ListenAndServe(":80", mux)

	if err != nil {
		log.Fatal(err)
	}

}
