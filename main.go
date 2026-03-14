package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	actv1 "act-api/gen/act/v1"
	"act-api/gen/act/v1/actv1connect"

	"connectrpc.com/connect"
	"github.com/rs/cors"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
)

// requireEnv は AGENTS.md のルールに従い、環境変数が未設定の場合は即座にエラーを出して終了します
func requireEnv(key string) string {
	val := os.Getenv(key)
	if val == "" {
		log.Fatalf("FATAL: Environment variable %s is required", key)
	}
	return val
}

type actServer struct{}

func (s *actServer) RunAct(
	ctx context.Context,
	req *connect.Request[actv1.RunActRequest],
	stream *connect.ServerStream[actv1.RunActResponse],
) error {
	log.Printf("RunAct called with session_id: %q, user_input: %q", req.Msg.SessionId, req.Msg.UserInput)

	// モックとして複数回レスポンスをストリーミングする
	responses := []string{
		"Thinking about: " + req.Msg.UserInput,
		"Extracting key concepts...",
		"Here is the generated response.",
	}

	for _, text := range responses {
		time.Sleep(500 * time.Millisecond) // モックの遅延
		if err := stream.Send(&actv1.RunActResponse{Text: text}); err != nil {
			return err
		}
	}
	return nil
}

func main() {
	// 必須環境変数の初期検証
	port := requireEnv("PORT")
	redisAddr := requireEnv("REDIS_ADDR")
	actAdkWorkerURL := requireEnv("ACT_ADK_WORKER_URL")
	gcpProject := requireEnv("GOOGLE_CLOUD_PROJECT")

	log.Printf("Starting Act API Server on port %s", port)
	log.Printf("Config: Redis=%s, WorkerURL=%s, GCP_Project=%s", redisAddr, actAdkWorkerURL, gcpProject)

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	// Connect RPC ハンドラの登録
	path, handler := actv1connect.NewActServiceHandler(&actServer{})
	mux.Handle(path, handler)

	// CORS設定: ブラウザ(Next.js)からのConnect RPC通信を許可
	corsHandler := cors.New(cors.Options{
		AllowedOrigins: []string{"*"}, // 開発用
		AllowedMethods: []string{http.MethodGet, http.MethodPost},
		AllowedHeaders: []string{"*"}, // Connectに必要なヘッダー(Content-Type, Connect-Protocol-Version等)を許可
		ExposedHeaders: []string{"*"},
	}).Handler(mux)

	addr := fmt.Sprintf("0.0.0.0:%s", port)
	// Connect RPC は HTTP/2 を推奨するため h2c を使用してサーバーを起動
	if err := http.ListenAndServe(addr, h2c.NewHandler(corsHandler, &http2.Server{})); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}