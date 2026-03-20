# Glossary

このページは、Action の docs を初めて読む人向けの用語集です。
特に、graph, Organize, Act, ingest 周辺で意味が分かれやすい言葉を短く整理しています。

## A

### Act

整理済み知識を使って、ユーザーの問いに応答したり次の行動を進めたりする実行層です。
主な構成は `frontend`, `act-api`, `act-adk-worker` です。

### Act node

graph 上で Act のやり取りを表す node です。
user act node を起点に、agent act node が枝分かれしていきます。

### Add Source

frontend から単発の file を追加する入口です。
`ActionIngest` とは別入口ですが、最終的には Organize の pipeline に入ります。

## C

### Canonical event

内部で「この形にそろえてから後段に流す」と決めた event のことです。
Action では `input.received` が重要な canonical event です。

## D

### Discord integration

Discord guild を workspace に接続し、会話を継続的に取り込む仕組みです。
`discord-bot` が message を受け取り、保存し、Organize へ流します。

### Draft

topic や node の更新途中で使う中間表現です。
最終的な graph 更新の前段にある作業データと考えると分かりやすいです。

## G

### Graph

Action が整理した知識構造のことです。
topic や node の関係として表現され、Act はこの graph を参照しながら動きます。

### Grounding

Act 実行時に、モデルが外部情報や追加情報を参照して回答の根拠を補うことです。
Action では web grounding や保存済み Discord ログ参照がここに関わります。

## I

### Ingest

入力データを Organize に渡せる形へ整える入口処理です。
Action では large import 用の `ActionIngest` と、単発 file 用の `Add Source` があります。

### `input.received`

Organize 内部で使う重要な event です。
「A1 が処理できる正規化済み入力が来た」という意味で使います。

## K

### Knowledge graph

Action が最終的に育てていく知識構造のことです。
単なる検索インデックスではなく、topic や node の関係を持つ graph として扱います。

## M

### `media.received`

raw file や media が到着したことを表す event です。
Add Source の upload 完了後などに発行され、A0 が text 抽出を行います。

## N

### Node

graph を構成する知識単位です。
topic 配下の具体的な内容や evidence のまとまりとして扱われます。

## O

### Organize

入力情報を knowledge graph として整理する層です。
atom 抽出、topic 判定、draft 更新、outline 更新、node 更新を担当します。

### Outline

知識を束ねた構造の見取り図です。
draft や node 更新とあわせて、graph を見やすく保つために使います。

## T

### Topic

知識を束ねる上位のまとまりです。
会話や資料から抽出された内容が、どの topic に属するかを Organize が判断します。

## W

### Workspace

Action における作業単位です。
graph、integration、Act の実行、member 管理などは workspace 単位で扱います。
