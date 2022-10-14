import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:smooth/src/binding.dart';
import 'package:smooth/src/list_view/controller.dart';

class SmoothShift extends StatefulWidget {
  final ScrollController scrollController;
  final Widget child;

  const SmoothShift({
    super.key,
    required this.scrollController,
    required this.child,
  });

  @override
  State<SmoothShift> createState() => _SmoothShiftState();
}

class _SmoothShiftState extends State<SmoothShift>
    with TickerProviderStateMixin {
  late final List<_SmoothShiftSource> sources;

  @override
  void initState() {
    super.initState();

    sources = [
      _SmoothShiftSourcePointerEvent(this),
      _SmoothShiftSourceBallistic(this),
    ];

    for (final source in sources) {
      source.addListener(_handleRefresh);
    }
  }

  @override
  void didUpdateWidget(covariant SmoothShift oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final source in sources) {
      source.didUpdateWidget(oldWidget);
    }
  }

  @override
  void dispose() {
    for (final source in sources) {
      source.removeListener(_handleRefresh);
      source.dispose();
    }
    super.dispose();
  }

  void _handleRefresh() => setState(() {});

  double get offset => sources.fold(0, (a, b) => a + b.offset);

  @override
  Widget build(BuildContext context) {
    // print('hi $runtimeType build offset=$offset sources=$sources');
    // SimpleLog.instance.log(
    //     'SmoothShift.build offset=$offset currentSmoothFrameTimeStamp=${ServiceLocator.maybeInstance?.preemptStrategy.currentSmoothFrameTimeStamp}');

    return Timeline.timeSync('SmoothShift',
        arguments: <String, Object?>{'offset': offset}, () {
      Widget result = Transform.translate(
        offset: Offset(0, offset),
        transformHitTests: false,
        child: widget.child,
      );

      for (final source in sources) {
        result = source.build(context, result);
      }

      return result;
    });
  }
}

abstract class _SmoothShiftSource extends ChangeNotifier {
  final _SmoothShiftState state;

  _SmoothShiftSource(this.state);

  double get offset;

  void didUpdateWidget(SmoothShift oldWidget) {}

  @override
  void dispose();

  Widget build(BuildContext context, Widget child) => child;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'SmoothShiftSource')}(offset: $offset)';
}

// NOTE about this weird timing, see
// * https://github.com/fzyzcjy/yplusplus/issues/5961#issuecomment-1266944825
// * https://github.com/fzyzcjy/yplusplus/issues/5961#issuecomment-1266978644
// for detailed reasons
// (to do: copy it here)
class _SmoothShiftSourcePointerEvent extends _SmoothShiftSource {
  double? _pointerDownPosition;
  double? _positionWhenCurrStartDrawFrame;
  double? _positionWhenPrevStartDrawFrame;
  double? _currPosition;

  late final _beginFrameEarlyCallbackRegistrar =
      _BeginFrameEarlyCallbackRegistrar(_handleBeginFrameEarlyCallback);

  // double? _positionWhenPrevPrevBuild;
  // double? _positionWhenPrevBuild;

  @override
  double get offset {
    if (_currPosition == null) return 0;

    final mainLayerTreeModeInAuxTreeView = SmoothSchedulerBindingMixin
        .instance.mainLayerTreeModeInAuxTreeView.value;
    // https://github.com/fzyzcjy/yplusplus/issues/5961#issuecomment-1266978644
    final basePosition = mainLayerTreeModeInAuxTreeView.choose(
      currentPlainFrame: _positionWhenCurrStartDrawFrame,
      previousPlainFrame: _positionWhenPrevStartDrawFrame,
    );

    final ans = _currPosition! - (basePosition ?? _pointerDownPosition!);

    final args = {
      'currPosition': _currPosition,
      'mainLayerTreeModeInAuxTreeView': mainLayerTreeModeInAuxTreeView.name,
      'positionWhenCurrStartDrawFrame': _positionWhenCurrStartDrawFrame,
      'positionWhenPrevStartDrawFrame': _positionWhenPrevStartDrawFrame,
      'pointerDownPosition': _pointerDownPosition,
      'basePosition': basePosition,
      'ans': ans,
    };
    Timeline.timeSync(
        'SmoothShift.offsetFromPointerEvent', arguments: args, () {});
    // print('hi $runtimeType get offset $args');

    return ans;
  }

  void _handleBeginFrameEarlyCallback() {
    if (!state.mounted) return;

    _positionWhenPrevStartDrawFrame = _positionWhenCurrStartDrawFrame;
    _positionWhenCurrStartDrawFrame = _currPosition;
    notifyListeners();

    Timeline.timeSync(
      'SmoothShift.StartDrawFrameCallback.after',
      arguments: <String, Object?>{
        'currPosition': _currPosition,
        'positionWhenCurrStartDrawFrame': _positionWhenCurrStartDrawFrame,
        'positionWhenPrevStartDrawFrame': _positionWhenPrevStartDrawFrame,
        'pointerDownPosition': _pointerDownPosition,
      },
      () {},
    );
  }

  void _handlePointerDown(PointerDownEvent e) {
    _pointerDownPosition = e.localPosition.dy;
    notifyListeners();
  }

  void _handlePointerMove(PointerMoveEvent e) {
    // SimpleLog.instance
    //     .log('SmoothShift.handlePointerMove position=${e.localPosition.dy}');
    // print(
    //     'hi $runtimeType _handlePointerMove e.localPosition=${e.localPosition.dy} e=$e');

    Timeline.timeSync(
      'SmoothShift.handlePointerMove',
      arguments: <String, Object?>{
        'eventPosition': e.localPosition.dy,
      },
      () {},
    );

    _currPosition = e.localPosition.dy;
    notifyListeners();
  }

  void _handlePointerUpOrCancel(PointerEvent e) {
    _pointerDownPosition = null;
    _positionWhenCurrStartDrawFrame = null;
    _positionWhenPrevStartDrawFrame = null;
    // _positionWhenPrevPrevBuild = null;
    // _positionWhenPrevBuild = null;
    _currPosition = null;
    notifyListeners();
  }

  // remove in #6071
  // // #6052
  // void _maybePseudoMoveOnBuild() {
  //   if (_currPosition == null) return;
  //
  //   // no pointer events
  //   if (_positionWhenPrevBuild == _currPosition) {
  //     // very naive interpolation...
  //     final double interpolatedShift;
  //
  //     if (_positionWhenPrevBuild != null &&
  //         _positionWhenPrevPrevBuild != null) {
  //       interpolatedShift =
  //           _positionWhenPrevBuild! - _positionWhenPrevPrevBuild!;
  //     } else {
  //       interpolatedShift = 0.0;
  //     }
  //
  //     _currPosition = _currPosition! + interpolatedShift;
  //   }
  //
  //   _positionWhenPrevPrevBuild = _positionWhenPrevBuild;
  //   _positionWhenPrevBuild = _currPosition;
  // }

  _SmoothShiftSourcePointerEvent(super.state) {
    SmoothSchedulerBindingMixin.instance.mainLayerTreeModeInAuxTreeView
        .addListener(notifyListeners);
  }

  @override
  void dispose() {
    SmoothSchedulerBindingMixin.instance.mainLayerTreeModeInAuxTreeView
        .removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget build(BuildContext context, Widget child) {
    _beginFrameEarlyCallbackRegistrar.maybeRegister();
    // _maybePseudoMoveOnBuild();

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

class _SmoothShiftSourceBallistic extends _SmoothShiftSource {
  @override
  double offset = 0;

  Ticker? _ticker;
  SmoothScrollPositionWithSingleContext? _scrollPosition;
  double? _lastBeforeBeginFrameSimulationOffset;

  late final _beginFrameEarlyCallbackRegistrar =
      _BeginFrameEarlyCallbackRegistrar(_handleBeginFrameEarlyCallback);

  _SmoothShiftSourceBallistic(super.state) {
    // https://github.com/fzyzcjy/yplusplus/issues/5918#issuecomment-1266553640
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!state.mounted) return;
      _scrollPosition = SmoothScrollPositionWithSingleContext.of(
          state.widget.scrollController);
      _scrollPosition!.lastSimulationInfo
          .addListener(_handleLastSimulationChanged);
    });
  }

  @override
  void didUpdateWidget(SmoothShift oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(oldWidget.scrollController == state.widget.scrollController,
        'for simplicity, not yet implemented change of `scrollController`');
    assert(
        SmoothScrollPositionWithSingleContext.of(
                state.widget.scrollController) ==
            _scrollPosition,
        'for simplicity, SmoothScrollPositionWithSingleContext cannot yet be changed');
  }

  @override
  void dispose() {
    _scrollPosition?.lastSimulationInfo
        .removeListener(_handleLastSimulationChanged);
    _ticker?.dispose();
    super.dispose();
  }

  void _handleBeginFrameEarlyCallback() {
    if (!state.mounted) return;

    _lastBeforeBeginFrameSimulationOffset =
        _scrollPosition?.lastSimulationInfo.value?.realSimulation.lastX;
    notifyListeners();
  }

  void _handleLastSimulationChanged() {
    _ticker?.dispose();

    // re-create ticker, because the [Simulation] wants zero timestamp
    _ticker = state.createTicker(_tick)..start();
  }

  void _tick(Duration selfTickerElapsed) {
    final newOffset = _computeOffsetFromBallisticOnTick(selfTickerElapsed);
    if (newOffset != null) {
      offset = newOffset;
      notifyListeners();
    }
  }

  // NOTE need to gracefully handle early returns
  // see https://github.com/fzyzcjy/yplusplus/issues/6190#issuecomment-1278516607
  double? _computeOffsetFromBallisticOnTick(Duration selfTickerElapsed) {
    final lastSimulationInfo = _scrollPosition!.lastSimulationInfo.value;
    if (lastSimulationInfo == null) return null;

    // [selfTickerElapsed] is the time delta relative to [_ticker.startTime]
    // thus [tickTimeStamp] is absolute [AdjustedFrameTimeStamp]
    final tickTimeStamp = _ticker!.startTime! + selfTickerElapsed;
    // [simulationRelativeTime] is the time delta relative to
    // [ballisticScrollActivityTicker]. In other words, it is the time that the
    // real [ListView]'s [BallisticScrollActivity] has.
    final ballisticTickerStartTime =
        lastSimulationInfo.ballisticScrollActivityTicker.startTime;
    if (ballisticTickerStartTime == null) return null;
    final simulationRelativeTime = tickTimeStamp - ballisticTickerStartTime;

    final smoothOffset = lastSimulationInfo.clonedSimulation
        .x(simulationRelativeTime.inMicroseconds / 1000000);

    final mainLayerTreeModeInAuxTreeView = SmoothSchedulerBindingMixin
        .instance.mainLayerTreeModeInAuxTreeView.value;
    final plainOffset = mainLayerTreeModeInAuxTreeView.choose(
      currentPlainFrame: lastSimulationInfo.realSimulation.lastX,
      previousPlainFrame: _lastBeforeBeginFrameSimulationOffset,
    );
    if (plainOffset == null) return null;

    final ans = -(smoothOffset - plainOffset);

    final info = 'ans=$ans '
        'smoothOffset=$smoothOffset '
        'plainOffset=$plainOffset '
        'realSimulation.lastX=${lastSimulationInfo.realSimulation.lastX} '
        'realSimulation.lastTime=${lastSimulationInfo.realSimulation.lastTime} '
        'lastBeforeBeginFrameSimulationOffset=$_lastBeforeBeginFrameSimulationOffset '
        'mainLayerTreeModeInAuxTreeView=$mainLayerTreeModeInAuxTreeView '
        'selfTickerElapsed=$selfTickerElapsed '
        'tickTimeStamp=$tickTimeStamp '
        'ballisticTickerStartTime=$ballisticTickerStartTime '
        'simulationRelativeTime=$simulationRelativeTime '
        'realSimulation=${lastSimulationInfo.realSimulation} ';
    // print('hi $runtimeType._computeOffsetFromBallisticOnTick $info';
    Timeline.timeSync(
        'SmoothShift.computeOffsetFromBallisticOnTick',
        arguments: <String, Object?>{'info': info},
        () {});

    return ans;
  }

  @override
  Widget build(BuildContext context, Widget child) {
    _beginFrameEarlyCallbackRegistrar.maybeRegister();
    return child;
  }
}

class _BeginFrameEarlyCallbackRegistrar {
  final VoidCallback f;

  var _hasPendingCallback = false;

  _BeginFrameEarlyCallbackRegistrar(this.f);

  void maybeRegister() {
    if (_hasPendingCallback) return;
    _hasPendingCallback = true;
    SmoothSchedulerBindingMixin.instance.addBeginFrameEarlyCallback(() {
      _hasPendingCallback = false;
      f();
    });
  }
}
