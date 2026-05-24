import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/features/home/home_screen.dart';

enum LegalType { terms, privacy, license, healthConsent, commercialLaw }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.type});
  final String title;
  final LegalType type;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.ink,
      body: Stack(children: [
        // 本文
        Positioned(top: 48 * sy, left: 0, right: 0, bottom: 56 * sy, child: Container(
          color: ButaColors.paper,
          padding: EdgeInsets.all(14 * sx),
          child: SingleChildScrollView(
            child: Text(
              type == LegalType.terms ? _termsText : type == LegalType.privacy ? _privacyText : type == LegalType.healthConsent ? _healthConsentText : type == LegalType.commercialLaw ? _commercialLawText : '',
              style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink, height: 1.8),
            ),
          ),
        )),
        // ヘッダー
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(
          color: ButaColors.ink,
          padding: EdgeInsets.symmetric(horizontal: 14 * sx),
          child: Row(children: [
            GestureDetector(onTap: () => context.pop(), child: const Text('◀', style: TextStyle(fontSize: 16, color: ButaColors.paper))),
            SizedBox(width: 14 * sx),
            Text(title, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper)),
          ]),
        )),
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      ]),
    );
  }
}

const _termsText = '''だい1じょう（もくてき）
このきやくは「ぶたそだて」の
りようじょうけんを さだめます。

だい2じょう（りよう）
ユーザーは このアプリを
たのしく つかってください。

だい3じょう（きんし）
ほかのユーザーへの めいわく
こういは きんしです。

だい4じょう（めんせき）
うんえいは サービスの
ていしに ついて せきにんを
おいません。''';

const _privacyText = '''1. しゅうしゅうする じょうほう
メールアドレス、ニックネーム、
けんこうデータ（にゅうりょくぶん）

2. りようもくてき
アカウントかんり、
サービスていきょう

3. だいさんしゃていきょう
ユーザーの どういなく
だいさんしゃに ていきょう
しません。

4. おといあわせ
buta@example.com''';

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
Copyright (c) 2018 ��

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

「ぶたそだて」では いかの
ヘルスデータを しゅとくします。

■ しゅとく こうもく
・たいじゅう
・ほすう
・すいみん じかん

■ りよう もくてき
・アバターの せいちょう はんてい
・ゲーム ないの ポイント けいさん
・ユーザーの けんこう けいこう ぶんせき

■ データの ほかん
しゅとくした データは
あんごうかして ほかんされます。

■ だいさんしゃ ていきょう
ヘルスデータを だいさんしゃに
ていきょう することは ありません。

■ どうい の てっかい
せってい がめんから いつでも
れんけいを かいじょ できます。''';

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

■ でんわばんごう
03-0000-0000
（おといあわせは メールにて）

■ メールアドレス
support@butasodate.example.com

■ はんばい かかく
アプリないに ひょうじされた
かかく（ぜいこみ）

■ しはらい ほうほう
Apple App Store / Google Play
けっさい

■ ひきわたし じき
こうにゅうご そくじ りよう かのう

■ へんぴん・キャンセル
デジタル コンテンツの ため
へんぴんは おうけ できません。''';
