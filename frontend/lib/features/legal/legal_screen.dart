import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';

enum LegalType { terms, privacy, license, healthConsent, commercialLaw }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.type, this.showTabBar = true});
  final String title;
  final LegalType type;
  final bool showTabBar;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.ink,
      appBar: PixelAppBar(title: title, showBack: true),
      bottomNavigationBar: showTabBar ? SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)) : null,
      body: Stack(children: [
        // 本文
        Positioned(top: 0 * sy, left: 0, right: 0, bottom: 0, child: Container(
          color: ButaColors.paper,
          padding: EdgeInsets.all(14 * sx),
          child: SingleChildScrollView(
            child: Text(
              type == LegalType.terms ? _termsText : type == LegalType.privacy ? _privacyText : type == LegalType.healthConsent ? _healthConsentText : type == LegalType.commercialLaw ? _commercialLawText : '',
              style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink, height: 1.8),
            ),
          ),
        )),
      ]),
    );
  }
}

const _termsText = '''だい1じょう（てきよう）
このきやくは「ぶたそだて」（いか
「ほんサービス」）の りようじょうけんを
さだめるものです。ユーザーは
ほんきやくに どういのうえ
ほんサービスを りようするものと
します。

だい2じょう（アカウント）
1. ユーザーは じぶんの アカウントを
てきせつに かんりする ぎむを
おいます。
2. アカウントの ふせいりようにより
しょうじた そんがいについて
うんえいは せきにんを おいません。

だい3じょう（きんしじこう）
ユーザーは いかの こういを
してはなりません。
・ほうれいに いはんする こうい
・ほかの ユーザーへの めいわくこうい
・サーバーに かどな ふかを かける
こうい
・ふせいアクセス または それに
じゅんずる こうい
・うんえいが ふてきせつと はんだん
する こうい

だい4じょう（サービスの ていし）
うんえいは いかの ばあいに
サービスを ていし できます。
・システムの ほしゅう じ
・てんさいちへん とうの ばあい
・そのた うんえいが ひつようと
はんだんした ばあい

だい5じょう（めんせきじこう）
1. うんえいは ほんサービスの
かんぜんせいを ほしょう しません。
2. ユーザーかんの トラブルについて
うんえいは かんよ しません。

だい6じょう（きやくの へんこう）
うんえいは ユーザーへの つうちなく
ほんきやくを へんこう できます。
へんこうごの りようをもって
どういと みなします。

だい7じょう（じゅんきょほう）
ほんきやくは にほんほうに
じゅんきょします。

2024ねん 4がつ 1にち せいてい''';

const _privacyText = '''プライバシーポリシー

さいしゅう こうしんび: 2024ねん 4がつ 1にち

「ぶたそだて」（いか「ほんサービス」）
における こじんじょうほうの
とりあつかいについて いかのとおり
さだめます。

■ しゅうしゅうする じょうほう
・メールアドレス
・ニックネーム
・プロフィール がぞう
・けんこうデータ（たいじゅう、ほすう、
すいみんじかん）
・アプリの りようりれき
・たんまつ じょうほう（OS、バージョン）

■ りよう もくてき
・アカウントの さくせい・かんり
・サービスの ていきょう・かいぜん
・アバターの せいちょう はんてい
・ゲームない ポイントの けいさん
・おしらせの はいしん
・とうけい データの さくせい

■ データの ほかん
・しゅうしゅうした データは
あんごうかして ほかんします
・ほかん きかんは アカウント
さくじょご 30にちかん です

■ だいさんしゃ ていきょう
いかの ばあいを のぞき
だいさんしゃに ていきょう しません。
・ユーザーの どうい がある ばあい
・ほうれいに もとづく ばあい

■ Cookie・トラッキング
ほんサービスでは サービスかいぜんの
ため Cookie を しようします。

■ おこさまの プライバシー
13さい みまんの おこさまからは
ほごしゃの どうい なく じょうほうを
しゅうしゅう しません。

■ ポリシーの へんこう
ほんポリシーは ひつようにおうじて
へんこう されることが あります。
じゅうような へんこうは アプリない
で つうち します。

■ おといあわせ
support@butasodate.example.com''';

const _licenseText = '''このアプリは いかの
オープンソース ライブラリを
しようしています。

━━━━━━━━━━━━━━━━━━
flutter_riverpod (3.3.1)
MIT License
Copyright (c) 2020 Remi Rousselet

━━━━━━━━━━━━━━━━━━
go_router (14.8.0)
BSD 3-Clause License
Copyright 2013 The Flutter Authors

━━━━━━━━━━━━━━━━━━
dio (5.8.0)
MIT License
Copyright (c) 2018 February

━━━━━━━━━━━━━━━━━━
flutter_svg (2.0.17)
MIT License
Copyright (c) 2018 Dan Field

━━━━━━━━━━━━━━━━━━
shared_preferences (2.5.0)
BSD 3-Clause License
Copyright 2013 The Flutter Authors

━━━━━━━━━━━━━━━━━━
flutter_secure_storage (10.2.0)
BSD 3-Clause License
Copyright (c) 2017 German Saprykin

━━━━━━━━━━━━━━━━━━
cached_network_image (3.4.1)
MIT License
Copyright (c) 2018 Baseflow

━━━━━━━━━━━━━━━━━━
connectivity_plus (6.1.4)
BSD 3-Clause License
Copyright 2017 The Chromium Authors

━━━━━━━━━━━━━━━━━━
carousel_slider (5.0.0)
MIT License
Copyright (c) 2019 serenader''';


const _healthConsentText = '''ヘルスデータ りよう どうい

さいしゅう こうしんび: 2024ねん 4がつ 1にち

「ぶたそだて」では ユーザーの
けんこうじょうたいに もとづいて
アバターを せいちょう させるため
いかの ヘルスデータを しゅとく
します。

■ しゅとく こうもく
・たいじゅう（まいにちの きろく）
・ほすう（まいにちの ごうけい）
・すいみん じかん（しゅうしん・きしょう）

■ りよう もくてき
・アバターの せいちょう はんてい
ほすうが おおいと すばやさ UP
すいみんが じゅうぶんだと HP UP
・ゲーム ないの ポイント けいさん
きろくを つけると ポイント かくとく
・ユーザーの けんこう けいこう ぶんせき
しゅうかん・げっかんの グラフ ひょうじ

■ データの ほかん
・しゅとくした データは AES-256で
あんごうかして ほかんされます
・サーバーは AWS とうきょう リージョン
に せっちされています

■ だいさんしゃ ていきょう
ヘルスデータを だいさんしゃに
ていきょう することは いっさい
ありません。

■ どうい の てっかい
せってい がめん ＞ ヘルスデータ
から いつでも れんけいを
かいじょ できます。
かいじょご、ほかんデータは
30にち いないに さくじょ されます。

■ おといあわせ
support@butasodate.example.com''';

const _commercialLawText = '''とくてい しょうとりひきほう に
もとづく ひょうじ

■ はんばいぎょうしゃ
かぶしきがいしゃ ぶたそだて

■ うんえい せきにんしゃ
ぶた たろう

■ しょざいち
〒100-0001
とうきょうと ちよだく
ちよだ 1-1-1
ぶたそだて ビル 3F

■ でんわばんごう
03-0000-0000
（じゅでん じかん: へいじつ 10:00〜17:00）
※おといあわせは メールにて
おねがいします

■ メールアドレス
support@butasodate.example.com

■ はんばい かかく
アプリないに ひょうじされた
かかく（ぜいこみ）
・ぶたの おやつ パック: 120えん
・プレミアム パス（げっかく）: 480えん
・ほうせき セット: 250えん〜3,000えん

■ しはらい ほうほう
・Apple App Store けっさい
・Google Play けっさい
※かくプラットフォームの きていに
じゅんじます

■ ひきわたし じき
こうにゅうご そくじ りよう かのう

■ へんぴん・キャンセル
デジタル コンテンツの せいしつじょう
こうにゅうご の へんぴん・へんきんは
おうけ できません。
ただし いかの ばあいは のぞきます。
・しょうひんが せいじょうに
ていきょう されなかった ばあい

■ どうさ かんきょう
・iOS 16.0 いじょう
・Android 10.0 いじょう

2024ねん 4がつ 1にち せいてい''';
