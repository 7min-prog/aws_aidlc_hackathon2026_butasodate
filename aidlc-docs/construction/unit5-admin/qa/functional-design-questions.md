# Unit 5: 管理画面 (FR-7) — Functional Design Questions

## Question 1: 管理者の認証方式
管理画面にログインする管理者の認証方式はどうしますか？

- A) 既存のCognito User Poolに管理者グループを作って認証
- B) 管理画面専用の別のCognito User Poolを作成
- C) Basic認証（ID/パスワード固定）でシンプルに
- D) その他

[Answer]:C

---

## Question 2: UIフレームワーク
管理画面のデザイン・UIフレームワークの希望はありますか？

- A) MUI (Material UI) — Googleっぽいデザイン
- B) Ant Design — 管理画面向けで定番
- C) shadcn/ui — モダンで軽量
- D) 特にこだわりなし（おまかせ）

[Answer]:A
---

## Question 3: 操作ログ
管理画面で操作した履歴（誰がいつ何をしたか）のログは必要ですか？

- A) はい、操作ログを残したい
- B) いいえ、ハッカソンなので不要

[Answer]:A

---
