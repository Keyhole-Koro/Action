# Limitations and Roadmap

このページは、Action の現時点での制約と、それをどう位置づけているかを説明する資料です。
どこが意図的な設計で、どこが今後の拡張余地なのかを明確にすることを目的としています。

## 基本姿勢

Action は、複数の入力経路、knowledge graph、Act 実行、Discord integration を同時に扱うシステムです。
そのため、すべてを一度に完全自動化するより、まず壊れにくい境界を作ることを優先しています。

つまり、現在の制約の一部は「まだできていない」のではなく、「整合性と堅牢性を優先した設計判断」です。

## 1. Discord binding は完全自動ではない

### 現在

- workspace owner が install session を作る
- Discord で bot を guild に招待する
- `discord-bot` が guild join を検知する
- candidate が出る
- owner が `Confirm` して binding を確定する

### なぜそうしているか

- 複数 workspace と複数 guild があると誤紐付けのリスクがある
- 完全自動化より、最後の 1 回だけ人間確認を入れる方が安全
- integration state を壊すと、あとから復旧コストが高い

### 今後

- candidate の提示精度向上
- より自然な install completion UX
- 必要なら callback や install metadata を使った自動化の検討

## 2. Add Source は `ActionIngest` とは別入口

### 現在

- large import は `ActionIngest`
- 単発 file 追加は `Add Source`
- `Add Source` は `act-api -> media.received -> A0 -> input.received`

### なぜ分けているか

- UI からの単発追加を軽く保ちたい
- large import の heavy 前処理を、日常的な upload に持ち込みたくない
- ただし内部の canonical event は `input.received` に寄せている

### 今後

- `ActionIngest` と Add Source の責務整理
- 入口が違っても運用上の見え方をより統一する

## 3. graph UI は自由配置と自動配置が混在する

### 現在

- topic graph は persisted graph として表示される
- user act root は手動で位置を持てる
- agent act child は自動レイアウトに寄せている

### なぜそうしているか

- ユーザーが「問いの起点」を置く自由度は残したい
- ただし child まで自由配置にすると tree 構造が崩れやすい
- graph の見通しと操作性のバランスを取っている

### 今後

- group rectangle の整理
- より安定した subtree packing
- 視覚整理の強化

## 4. Act は完全な agent OS ではなく、knowledge graph 前提の実行系

### 現在

- Act は graph context を読みながら follow-up を進める
- 保存済み Discord logs や web grounding を参照できる
- ただし万能な long-running automation ではない

### なぜそうしているか

- まずは knowledge graph を活かす実行体験に集中したい
- agent を過剰に一般化すると、プロダクトの軸がぼやける
- graph と action の接続に集中したい

### 今後

- node candidate resolution の改善
- action decision の改善
- より複雑な tool / task orchestration への拡張

## 5. 一部のローカル開発導線はまだ粗い

### 現在

- compose の `ui` profile は、`act-api` の recreate 運用で制約がある
- emulator や bootstrap 依存がまだ完全には綺麗に分離されていない

### なぜそうなっているか

- 本番構成とローカル構成の両立を優先し、開発フローの整形が一部追いついていない

### 今後

- profile 依存整理
- local dev onboarding の簡素化
- docs と compose 実態のさらなる一致

## 6. なぜこの制約が「弱さ」ではないのか

Action の制約の多くは、プロダクトの軸を守るための制約です。

例:

- Discord binding を完全自動にしない
  - 整合性優先
- Add Source を heavy ingest と分ける
  - 日常 UX 優先
- agent child を自由配置させない
  - graph の意味を守る

つまり、今の制約は「まだ粗いから」だけではなく、「何を壊したくないか」を決めた結果でもあります。

## 7. ロードマップの方向

短期:

- Discord install UX の改善
- graph UI の見やすさ改善
- local dev 導線の整理

中期:

- Add Source と ingest の運用統一
- Act の candidate / decision quality 向上
- graph の表示整理と navigation 強化

長期:

- knowledge graph を前提にした、より強い action runtime
- 外部入力チャネルの追加
- より大きな workspace 運用に耐える観測性と制御性

## Summary

Action には未実装領域もありますが、今の制約の多くは設計上の意図です。
たとえば Discord binding は完全自動にせず confirm を残し、Add Source は heavy ingest から分離し、agent child は graph の意味を壊さないよう自動レイアウトに寄せています。

これは、知識化と行動の接続という核を保ちながら段階的に拡張するための判断です。
