# Logical Components - Unit 3: アバター育成

## コンポーネント構成図

```text
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                            │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ AvatarSprite │  │ AvatarStatus │  │  Evolution   │  │
│  │   Widget     │  │    Page      │  │  Animation   │  │
│  │  (Flame)     │  │              │  │              │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘  │
│         │                  │                             │
│  ┌──────┴──────────────────┴───────┐                    │
│  │        AvatarProvider           │                    │
│  └──────────────┬──────────────────┘                    │
│                 │                                        │
│  ┌──────────────┴──────────────────┐                    │
│  │      AvatarRepository          │                    │
│  └──────────────┬──────────────────┘                    │
│                 │                                        │
│  ┌──────────────┴────────┐  ┌────────────────────────┐  │
│  │  AvatarRemoteSource   │  │  SpriteCacheManager    │  │
│  │  (REST API Client)    │  │  (flutter_cache_mgr)   │  │
│  └──────────────┬────────┘  └───────────┬────────────┘  │
└─────────────────┼───────────────────────┼────────────────┘
                  │                       │
                  ▼                       ▼
┌─────────────────────────┐   ┌─────────────────────┐
│   API Gateway (REST)    │   │        S3           │
│   /avatar/*             │   │  assets/sprites/    │
└────────────┬────────────┘   └─────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│              Lambda (Node.js 20.x)           │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐    │
│  │          AvatarService              │    │
│  │  ┌───────────┐  ┌───────────────┐  │    │
│  │  │ addPoints │  │ deductPoints  │  │    │
│  │  └─────┬─────┘  └───────┬───────┘  │    │
│  │        │                 │          │    │
│  │  ┌─────┴─────────────────┴───────┐  │    │
│  │  │     EvolutionEngine           │  │    │
│  │  │  - calculateLevel()           │  │    │
│  │  │  - checkEvolution()           │  │    │
│  │  │  - checkDevolution()          │  │    │
│  │  │  - recalculateStats()         │  │    │
│  │  │  - checkSkillAcquisition()    │  │    │
│  │  └───────────────────────────────┘  │    │
│  └─────────────────────────────────────┘    │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │     MasterDataCache (in-memory)     │    │
│  │  - evolutionPaths[]                 │    │
│  │  - skills[]                         │    │
│  └─────────────────────────────────────┘    │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│              DynamoDB                         │
├─────────────────────────────────────────────┤
│  ┌───────────────┐  ┌────────────────────┐  │
│  │ Avatar Table  │  │ EvolutionHistory   │  │
│  │ PK: userId    │  │ PK: userId         │  │
│  │               │  │ SK: occurredAt#id  │  │
│  └───────────────┘  └────────────────────┘  │
│                                              │
│  ┌───────────────┐  ┌────────────────────┐  │
│  │ EvolutionPath │  │ Skill Table        │  │
│  │ (Master)      │  │ (Master)           │  │
│  │ PK: pathId    │  │ PK: skillId        │  │
│  └───────────────┘  └────────────────────┘  │
└──────────────────────────────────────────────┘
```

## コンポーネント詳細

### バックエンド

| コンポーネント | 責務 | 技術 |
|--------------|------|------|
| AvatarService | ポイント加算/減算、アバターCRUD | Lambda内サービス層 |
| EvolutionEngine | レベル計算、進化/退化判定、ステータス再計算、スキル判定 | 純粋関数群（副作用なし） |
| MasterDataCache | EvolutionPath/Skillのインメモリキャッシュ | Lambdaグローバル変数 |
| Avatar Handler | REST APIハンドラ（GET /avatar, POST /avatar等） | Lambda エントリポイント |

### フロントエンド

| コンポーネント | 責務 | 技術 |
|--------------|------|------|
| AvatarProvider | アバター状態管理、API呼び出し | Riverpod |
| AvatarRepository | データソース抽象化 | Repository Pattern |
| AvatarRemoteSource | REST API通信 | http / dio |
| SpriteCacheManager | スプライトシートのDL/キャッシュ | flutter_cache_manager |
| AvatarSpriteWidget | ドット絵アニメーション再生 | Flame SpriteAnimationComponent |
| EvolutionAnimation | 進化/退化フルスクリーン演出 | Flutter AnimationController + Flame |

### インフラ

| コンポーネント | 責務 | 技術 |
|--------------|------|------|
| S3 Bucket | スプライトシートアセット保存 | S3 (パブリック読み取り) |
| DynamoDB Tables | アバター/履歴/マスターデータ保存 | DynamoDB オンデマンド |
| API Gateway | REST API エンドポイント | API Gateway (Unit 1/2 と共有) |
| Lambda | ビジネスロジック実行 | Node.js 20.x (Unit 1/2 と共有可) |

## データフロー

### ポイント加算時（通常ケース: 進化なし）

```text
Unit2 API Handler → AvatarService.addPoints()
    → DynamoDB UpdateItem (1回)
    → EvolutionEngine.calculateLevel() (メモリ内)
    → EvolutionEngine.checkEvolution() (メモリ内、MasterDataCache参照)
    → レスポンス返却
```

**DB操作**: 1回（UpdateItem）

### ポイント加算時（進化発生）

```text
Unit2 API Handler → AvatarService.addPoints()
    → DynamoDB UpdateItem (Avatar更新)
    → EvolutionEngine.checkEvolution() → 進化発生
    → DynamoDB UpdateItem (Avatar: pathId, spriteKey, skills更新)
    → DynamoDB PutItem (EvolutionHistory追加)
    → レスポンス返却
```

**DB操作**: 3回（進化はレアイベントなので許容）

### スプライト表示

```text
AvatarProvider → avatar.spriteSheetKey取得
    → SpriteCacheManager.getFile(S3 URL + spriteSheetKey)
    → AvatarSpriteWidget にファイルパス渡し
    → Flame でアニメーション再生
```
