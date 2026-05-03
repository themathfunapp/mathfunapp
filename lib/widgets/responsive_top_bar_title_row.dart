import 'package:flutter/material.dart';

/// Sol [leading] + ortada tek satır, taşmayan başlık + sağda [trailing]
/// veya simetrik [balanceWidth] boşluğu.
///
/// Dar ekran ve büyük erişilebilirlik yazı boyutunda taşmayı önler.
class ResponsiveTopBarTitleRow extends StatelessWidget {
  const ResponsiveTopBarTitleRow({
    super.key,
    required this.leading,
    required this.title,
    required this.titleStyle,
    this.trailing,
    this.balanceWidth = 48,
  });

  final Widget leading;
  final String title;
  final TextStyle titleStyle;
  final Widget? trailing;
  final double balanceWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        trailing ?? SizedBox(width: balanceWidth),
      ],
    );
  }
}
