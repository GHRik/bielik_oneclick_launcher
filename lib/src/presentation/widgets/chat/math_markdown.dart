import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_ui/material_ui.dart';

/// Recognizes complete math expressions without rewriting Markdown code spans.
class MathInlineSyntax extends md.InlineSyntax {
  MathInlineSyntax()
    : super(r'\$\$|\$|\\\(|\\\[|\\(?:dfrac|tfrac|frac|sqrt)\b');

  bool _escaped(String source, int index) {
    var backslashes = 0;
    while (index > 0 && source[--index] == r'\') {
      backslashes++;
    }
    return backslashes.isOdd;
  }

  int? _groupEnd(String source, int start, String open, String close) {
    if (start >= source.length || source[start] != open) return null;
    var depth = 0;
    for (var index = start; index < source.length; index++) {
      if (_escaped(source, index)) continue;
      if (source[index] == open) depth++;
      if (source[index] == close && --depth == 0) return index + 1;
    }
    return null;
  }

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final source = parser.source;
    bool literal() {
      parser.addNode(md.Text(match[0]!));
      return true;
    }

    if (_escaped(source, match.start)) return literal();
    final opening = match[0]!;
    var end = match.end;
    late String equation;
    var display = false;
    final closing = switch (opening) {
      r'$' => r'$',
      r'$$' => r'$$',
      r'\(' => r'\)',
      r'\[' => r'\]',
      _ => null,
    };
    if (closing != null) {
      if (opening == r'$' &&
          match.start > 0 &&
          source[match.start - 1] == r'$') {
        return literal();
      }
      var closeAt = source.indexOf(closing, end);
      while (closeAt >= 0 && _escaped(source, closeAt)) {
        closeAt = source.indexOf(closing, closeAt + closing.length);
      }
      if (closeAt < 0) return literal();
      equation = source.substring(end, closeAt);
      if (equation.trim().isEmpty) return literal();
      if (opening == r'$' &&
          (equation.contains('\n') || equation != equation.trim())) {
        return literal();
      }
      end = closeAt + closing.length;
      display = opening == r'$$' || opening == r'\[';
    } else {
      final groups = opening == r'\sqrt' ? 1 : 2;
      for (var group = 0; group < groups; group++) {
        while (end < source.length && source[end].trim().isEmpty) {
          end++;
        }
        final groupEnd = _groupEnd(source, end, '{', '}');
        if (groupEnd == null) return literal();
        end = groupEnd;
      }
      equation = source.substring(match.start, end);
    }
    final element = md.Element.text('math', equation);
    element.attributes['source'] = source.substring(match.start, end);
    element.attributes['display'] = '$display';
    parser.addNode(element);
    parser.consume(end - match.end);
    return true;
  }
}

class MathElementBuilder extends MarkdownElementBuilder {
  MathElementBuilder(this.textStyle);
  final TextStyle textStyle;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Math.tex(
      element.textContent,
      mathStyle: element.attributes['display'] == 'true'
          ? MathStyle.display
          : MathStyle.text,
      textStyle: textStyle,
      textScaleFactor: MediaQuery.textScalerOf(context).scale(1),
      onErrorFallback: (_) => Text(
        element.attributes['source'] ?? element.textContent,
        style: textStyle.copyWith(fontFamily: 'monospace'),
      ),
    ),
  );
}
