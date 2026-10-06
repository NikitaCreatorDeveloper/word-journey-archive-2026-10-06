import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'match_flow_controller.dart';
import '../training/widgets/match_flow_tile.dart';

const matchFlowLabRoute = '/match-flow-lab';

// This bootstrap intentionally creates no TrainerData, database or services.
class MatchFlowLabApp extends StatelessWidget {
  const MatchFlowLabApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MATCH FLOW LAB',
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8C83F7),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
    ),
    home: const MatchFlowLabScreen(),
  );
}

class MatchFlowLabScreen extends StatefulWidget {
  const MatchFlowLabScreen({super.key, this.controller});
  final MatchFlowController? controller;
  @override
  State<MatchFlowLabScreen> createState() => _MatchFlowLabScreenState();
}

class _MatchFlowLabScreenState extends State<MatchFlowLabScreen>
    with WidgetsBindingObserver {
  late final _flow = widget.controller ?? MatchFlowController();
  final _overlay = ValueNotifier(true);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _flow.setPaused(state != AppLifecycleState.resumed);
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) _flow.dispose();
    _overlay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF111827),
    appBar: AppBar(
      backgroundColor: const Color(0xFF111827),
      foregroundColor: const Color(0xFFF4F5FF),
      title: const Text('MATCH FLOW LAB', style: TextStyle(fontSize: 19)),
      leading: IconButton(
        tooltip: 'Закрыть Lab',
        enableFeedback: false,
        icon: const Icon(Icons.close),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context);
          } else {
            SystemNavigator.pop();
          }
        },
      ),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: _overlay,
          builder: (context, enabled, _) => IconButton(
            key: const ValueKey('lab-overlay-toggle'),
            enableFeedback: false,
            tooltip: 'Показать slot / generation / state',
            onPressed: () => _overlay.value = !enabled,
            icon: Icon(enabled ? Icons.bug_report : Icons.bug_report_outlined),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
        child: Column(
          children: [
            const Text(
              'Тестовые слова · 5 пар',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gap = 10.0;
                  final height = ((constraints.maxHeight - 4 * gap) / 5)
                      .clamp(64.0, 104.0)
                      .toDouble();
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var row = 0; row < 5; row++) ...[
                            if (row > 0) SizedBox(height: gap),
                            SizedBox(
                              height: height,
                              child: Row(
                                children: [
                                  for (final left in [true, false]) ...[
                                    if (!left) const SizedBox(width: 10),
                                    Expanded(
                                      child: _LabSlot(
                                        key: ValueKey(
                                          'lab-slot-${left ? 'L' : 'R'}${row + 1}',
                                        ),
                                        flow: _flow,
                                        slot: (left: left, row: row),
                                        overlay: _overlay,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LabSlot extends StatelessWidget {
  const _LabSlot({
    super.key,
    required this.flow,
    required this.slot,
    required this.overlay,
  });
  final MatchFlowController flow;
  final LabSlotId slot;
  final ValueListenable<bool> overlay;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<LabSlotState>(
    valueListenable: flow.stateOf(slot),
    builder: (context, state, _) => MatchFlowTile(
      text: state.content.text,
      visual: state.visual,
      selected: state.selected,
      enabled: state.interactive,
      maxLines: 2,
      textKey: ValueKey('lab-text-${labSlotLabel(slot)}'),
      onPressed: () => flow.select(slot, state.content.generation),
      debugLabel: ValueListenableBuilder<bool>(
        valueListenable: overlay,
        builder: (context, visible, _) => visible
            ? Text(
                '${labSlotLabel(slot)} · g${state.content.generation} · ${state.visual.state.name}',
                key: ValueKey('lab-debug-${labSlotLabel(slot)}'),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              )
            : const SizedBox.shrink(),
      ),
    ),
  );
}
