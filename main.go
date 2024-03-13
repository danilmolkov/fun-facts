package main

import (
	"encoding/json"
	"log"
	"math/rand/v2"
	"net/http"
	"strconv"

	"github.com/go-redis/redis"
)

func receiveJSONHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		r.Response.StatusCode = 405
		return
	}
	client := redis.NewClient(&redis.Options{
		Addr:     "localhost:6379",
		Password: "",
		DB:       0,
	})
	// ctx := context.Background()
	// var, err := client
	factsSize, err := client.LLen("fun-facts").Result()
	if err != nil {
		panic(err)
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

func main() {
	log.Print("Starting server")
	mux := http.NewServeMux()
	fs := http.FileServer(http.Dir("./static"))
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
