import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';

class LicenseListScreen extends StatefulWidget {
  const LicenseListScreen({super.key});
  @override
  State<LicenseListScreen> createState() => _LicenseListScreenState();
}

class _LicenseListScreenState extends State<LicenseListScreen> {
  List<_LicenseData>? _licenses;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    final map = <String, List<String>>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final pkg in entry.packages) {
        map.putIfAbsent(pkg, () => []);
        map[pkg]!.add(entry.paragraphs.map((p) => p.text).join('\n'));
      }
    }
    final list = map.entries.map((e) => _LicenseData(e.key, e.value)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (mounted) setState(() => _licenses = list);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.ink,
      appBar: const PixelAppBar(title: 'ライセンス', showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      body: Container(
        color: ButaColors.paper,
        child: _licenses == null
          ? const Center(child: Text('よみこみちゅう...', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)))
          : ListView.separated(
              padding: EdgeInsets.all(14 * sx),
              itemCount: _licenses!.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: ButaColors.ink.withValues(alpha: 0.2)),
              itemBuilder: (context, i) {
                final lic = _licenses![i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _LicenseDetailScreen(data: lic))),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12 * sy),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(lic.name, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
                        Text('${lic.texts.length} license(s)', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.gray)),
                      ])),
                      SvgPicture.asset('assets/pixel-art/icons/play.svg', width: 12, height: 12),
                    ]),
                  ),
                );
              },
            ),
      ),
    );
  }
}

class _LicenseDetailScreen extends StatelessWidget {
  const _LicenseDetailScreen({required this.data});
  final _LicenseData data;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.ink,
      appBar: PixelAppBar(title: data.name, showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      body: Container(
        color: ButaColors.paper,
        padding: EdgeInsets.all(14 * sx),
        child: SingleChildScrollView(
          child: Text(data.texts.join('\n\n---\n\n'), style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink, height: 1.6)),
        ),
      ),
    );
  }
}

class _LicenseData {
  final String name;
  final List<String> texts;
  _LicenseData(this.name, this.texts);
}
