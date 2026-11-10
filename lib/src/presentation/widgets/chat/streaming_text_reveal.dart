import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Fades newly occupied text areas without rebuilding Markdown on animation ticks.
class StreamingTextReveal extends StatefulWidget {
  const StreamingTextReveal({
    super.key,
    required this.revision,
    required this.streaming,
    required this.child,
  });

  final String revision;
  final bool streaming;
  final Widget child;

  @override
  State<StreamingTextReveal> createState() => _StreamingTextRevealState();
}

class _StreamingTextRevealState extends State<StreamingTextReveal>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  bool _initialized = false;
  bool get _enabled =>
      widget.streaming && !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (_enabled) _animation.forward(from: 0);
    } else if (!_enabled) {
      _animation.value = 1;
    }
  }

  @override
  void didUpdateWidget(StreamingTextReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _animation.value = 1;
    } else if (widget.revision != oldWidget.revision) {
      _animation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _RevealPaint(
    animation: _animation,
    revision: widget.revision,
    enabled: _enabled,
    child: widget.child,
  );
}

class _RevealPaint extends SingleChildRenderObjectWidget {
  const _RevealPaint({
    required this.animation,
    required this.revision,
    required this.enabled,
    required super.child,
  });
  final Animation<double> animation;
  final String revision;
  final bool enabled;

  @override
  _RenderReveal createRenderObject(BuildContext context) =>
      _RenderReveal(animation, revision, enabled);

  @override
  void updateRenderObject(BuildContext context, _RenderReveal renderObject) {
    renderObject.update(revision, enabled);
  }
}

class _RenderReveal extends RenderProxyBox {
  _RenderReveal(this.animation, this.revision, this.enabled);
  final Animation<double> animation;
  String revision;
  bool enabled;
  List<Rect> _previousText = [];
  final _innerLayer = LayerHandle<ShaderMaskLayer>();

  @override
  bool get alwaysNeedsCompositing => enabled;

  void update(String next, bool animate) {
    if (enabled && animate && next.startsWith(revision)) {
      if (next != revision) _previousText = _textAreas();
    } else {
      _previousText = [];
    }
    revision = next;
    if (enabled != animate) markNeedsCompositingBitsUpdate();
    enabled = animate;
    markNeedsPaint();
  }

  List<Rect> _textAreas() {
    final areas = <Rect>[];
    void visit(RenderObject object) {
      if (object is RenderParagraph && object.hasSize) {
        final length = object.text.toPlainText().length;
        final offset = object.localToGlobal(Offset.zero, ancestor: this);
        for (final box in object.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: length),
        )) {
          areas.add(box.toRect().shift(offset));
        }
      }
      object.visitChildren(visit);
    }

    if (child != null) visit(child!);
    return areas;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    animation.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    animation.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _innerLayer.layer = null;
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!enabled || animation.value >= 1) {
      layer = null;
      _innerLayer.layer = null;
      super.paint(context, offset);
      return;
    }
    final bounds = Offset.zero & size;
    var regions = [bounds];
    if (_previousText.isNotEmpty) {
      final last = _previousText.reduce((a, b) => a.bottom > b.bottom ? a : b);
      final line = _previousText
          .where((area) => area.top < last.bottom && area.bottom > last.top)
          .fold(last, (a, b) => a.expandToInclude(b));
      // New glyphs extend the last line or occupy rows below it.
      regions =
          [
                Rect.fromLTRB(line.right, line.top, size.width, line.bottom),
                Rect.fromLTRB(0, line.bottom, size.width, size.height),
              ]
              .map((area) => area.intersect(bounds))
              .where((area) => !area.isEmpty)
              .toList();
    }
    if (regions.isEmpty) {
      super.paint(context, offset);
      return;
    }
    final color = Color.fromRGBO(255, 255, 255, animation.value);
    final shader = ui.Gradient.linear(Offset.zero, const Offset(1, 0), [
      color,
      color,
    ]);
    final outer = (layer as ShaderMaskLayer?) ?? ShaderMaskLayer();
    layer = outer;
    outer
      ..shader = shader
      ..maskRect = regions.first.shift(offset)
      ..blendMode = BlendMode.dstIn;
    context.pushLayer(outer, (innerContext, innerOffset) {
      if (regions.length == 1) {
        super.paint(innerContext, innerOffset);
      } else {
        final inner = _innerLayer.layer ?? ShaderMaskLayer();
        _innerLayer.layer = inner;
        inner
          ..shader = shader
          ..maskRect = regions.last.shift(innerOffset)
          ..blendMode = BlendMode.dstIn;
        innerContext.pushLayer(inner, super.paint, innerOffset);
      }
    }, offset);
  }
}
