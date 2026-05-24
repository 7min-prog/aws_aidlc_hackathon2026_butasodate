import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/features/home/home_screen.dart';

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
      body: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(
          color: ButaColors.ink,
          padding: EdgeInsets.symmetric(horizontal: 14 * sx),
          child: Row(children: [
            GestureDetector(onTap: () => context.pop(), child: const Text('◀', style: TextStyle(fontSize: 16, color: ButaColors.paper))),
            SizedBox(width: 14 * sx),
            Text('ライセンス', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper)),
          ]),
        )),
        Positioned(top: 48 * sy, left: 0, right: 0, bottom: 56 * sy, child: Container(
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
                        Text('▶', style: TextStyle(fontSize: 12, color: ButaColors.ink)),
                      ]),
                    ),
                  );
                },
              ),
        )),
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      ]),
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
      body: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(
          color: ButaColors.ink,
          padding: EdgeInsets.symmetric(horizontal: 14 * sx),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: const Text('◀', style: TextStyle(fontSize: 16, color: ButaColors.paper))),
            SizedBox(width: 14 * sx),
            Expanded(child: Text(data.name, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.paper), overflow: TextOverflow.ellipsis)),
          ]),
        )),
        Positioned(top: 48 * sy, left: 0, right: 0, bottom: 0, child: Container(
          color: ButaColors.paper,
          padding: EdgeInsets.all(14 * sx),
          child: SingleChildScrollView(
            child: Text(data.texts.join('\n\n---\n\n'), style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink, height: 1.6)),
          ),
        )),
      ]),
    );
  }
}

class _LicenseData {
  final String name;
  final List<String> texts;
  _LicenseData(this.name, this.texts);
}
