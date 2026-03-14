import { createPromiseClient } from "@connectrpc/connect";
import { createConnectTransport } from "@connectrpc/connect-web";
import { ActService } from "../gen/act/v1/act_connect";

// AGENTS.md ルール: 環境変数の fallback 禁止
const baseUrl = process.env.NEXT_PUBLIC_ACT_API_BASE_URL;
if (!baseUrl) {
  throw new Error("FATAL: NEXT_PUBLIC_ACT_API_BASE_URL is required");
}

// Connect-Web トランスポートの初期化
const transport = createConnectTransport({
  baseUrl,
});

export const actClient = createPromiseClient(ActService, transport);