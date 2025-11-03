# SleepFromHistory

**SleepFromHistory** は、Chrome の閲覧履歴から自動的に就寝・起床時刻を推定し、日々の睡眠パターンを記録するアプリケーションである。  
Chrome拡張が履歴データを定期的に分析し、その結果をGo/Echo製バックエンドへ送信して記録・可視化する。

---


## 💤 背景と目的

睡眠記録は、**継続の手間**が最大の障害である。  
既存のウェアラブル端末やスマホアプリは、手元に端末を置く・装着する・就寝時刻を設定するなどの操作が必要になる。  
だが、生活習慣が乱れた時ほど装着や操作を忘れ、**まさに測りたい日ほどデータが欠落する**という問題がある。

SleepFromHistory は、この逆説を解消するために、**「なにもしないこと」自体をデータに変える**発想から生まれた。  
Chrome の閲覧履歴には「人が活動していた痕跡」と「何もしていない時間（空白）」が自然に現れる。  
この空白こそが、最も手軽な就寝のシグナルである。

---

## 🧠 なぜ Chrome の閲覧履歴なのか

- **ゼロ操作で測れる**  
  手動入力もボタン操作も不要。拡張機能が自動で履歴を走査する。  

- **ウェアラブル非依存**  
  PC 中心の生活でも利用可能。充電忘れや装着忘れが存在しない。  

- **乱れに強い**  
  夜更かしした日や不規則なスケジュールでも、最終閲覧時刻と翌朝の最初の閲覧時刻が残る限り推定できる。  

## ターゲット
- 寝る直前までPCで何かをし、朝もPCで活動を始めるタイプ。
- シンプルに**「夜の最後の履歴」→「翌朝の最初の履歴」**が日々ほぼ連続している人。

---

## 🧩 技術構成

| 分類 | 使用技術 |
|------|-----------|
| 言語 | Go 1.25 |
| フレームワーク | Echo v4 |
| データベース | MySQL 8.4 |
| DB接続 | 標準 `database/sql` パッケージ |
| スキーマ管理 | Atlas |
| コンテナ | Docker |
| フロント | Chrome Extension (Manifest V3, JavaScript) |

---

## 🚀 セットアップ

### 1. リポジトリ取得
```bash
git clone https://github.com/htomoya16/SleepFromHistory.git SleepFromHistory
cd SleepFromHistory
```

### 2. プロジェクトを起動(開発環境)
#### 初回
```bash
# Dockerコンテナを起動
docker-compose up --build

# バックグラウンドで起動する場合
docker-compose up -d --build
```

#### 初回以降
```bash
# Dockerコンテナを起動
docker compose --profile dev up

# バックグラウンドで起動する場合
docker compose --profile dev up -d
```

#### 止め方
```bash
docker compose --profile dev down
```

### 3. プロジェクトを起動(本番環境)
#### 初回
```bash
# Dockerコンテナを起動
docker compose --profile prod up --build

# バックグラウンドで起動する場合
docker compose --profile prod up -d --build
```

#### 初回以降
```bash
# Dockerコンテナを起動
docker compose --profile prod up

# バックグラウンドで起動する場合
docker compose --profile prod up -d
```

#### 止め方
```bash
docker compose --profile dev down
```


## 💡 Chrome 拡張の使い方

### 拡張の読み込み

1. Chrome を開く  
2. アドレスバーに `chrome://extensions/` と入力  
3. 右上の「デベロッパーモード」を **ON** にする  
4. 「パッケージ化されていない拡張機能を読み込む」をクリック  
5. `chrome-extension` フォルダを選択  

これで拡張が読み込まれる。