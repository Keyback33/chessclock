import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../controllers/game_controller.dart';
import '../domain/clock.dart';
import 'dial.dart';
import 'move_button.dart';
import 'settings.dart';

class ClockBoard extends StatefulWidget {
  final GameController controller;
  const ClockBoard({super.key, required this.controller});
  @override
  State<ClockBoard> createState() => _ClockBoardState();
}

class _ClockBoardState extends State<ClockBoard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  GameController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((_) {
      c.frame();
      if (mounted) setState(() {});
    });
    c.addListener(_changed);
    _changed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && c.recovery != null) _recover();
    });
  }

  void _changed() {
    if (c.engine.phase == GamePhase.running) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      _ticker.stop();
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) c.interrupt();
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    _ticker.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _recover() async {
    final recover = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Partida guardada'),
        content: const Text(
          'Podés recuperar el último estado guardado. La partida vuelve en pausa; no incluye tiempo posterior a esa instantánea.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Recuperar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (recover == true) {
      c.recover();
    } else {
      c.discardRecovery();
    }
  }

  Future<void> _reset() async {
    final wasFinished = c.engine.phase == GamePhase.finished;
    c.pause();
    if (wasFinished) {
      c.reset();
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Reiniciar partida?'),
        content: const Text('Se borrarán los tiempos y las jugadas actuales.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) c.reset();
  }

  Future<void> _settings() async {
    final gameInProgress = c.engine.phase != GamePhase.ready;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SettingsPage(controller: c, gameInProgress: gameInProgress),
      ),
    );
    c.silence();
  }

  @override
  Widget build(BuildContext context) {
    final phase = c.engine.phase;
    return PopScope(
      canPop: phase != GamePhase.running,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) c.pause();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (c.notice != null)
                MaterialBanner(
                  content: Text(c.notice!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => c.notice = null),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, bounds) {
                    // Android may ignore axis locks on large displays/multiwindow.
                    // Honor the manual layout there; on phones follow the actual
                    // window while the native orientation transition completes.
                    final wide = bounds.biggest.shortestSide >= 600
                        ? switch (c.engine.config.orientation) {
                            ClockOrientation.automatic =>
                              bounds.maxWidth > bounds.maxHeight,
                            ClockOrientation.portrait => false,
                            ClockOrientation.landscape => true,
                          }
                        : bounds.maxWidth > bounds.maxHeight;
                    Widget panel(int player, int turns) => Expanded(
                      child: RotatedBox(
                        key: ValueKey('player-orientation-$player'),
                        quarterTurns: turns,
                        child: PlayerPanel(controller: c, player: player),
                      ),
                    );
                    final controls = Listener(
                      onPointerDown: (e) => c.pointerDown(e.pointer, null),
                      onPointerUp: (e) => c.pointerUp(e.pointer),
                      onPointerCancel: (e) => c.pointerUp(e.pointer),
                      child: SizedBox(
                        width: wide ? 92 : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!wide)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    c.engine.pauseReason ??
                                        modeLabel(c.engine.config.mode),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xffc6cbd0),
                                    ),
                                  ),
                                ),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (phase == GamePhase.ready)
                                    _primaryControl(
                                      key: const ValueKey('start'),
                                      onPressed: c.start,
                                      icon: Icons.play_arrow,
                                      label: 'Iniciar',
                                      wide: wide,
                                    ),
                                  if (phase == GamePhase.running)
                                    _primaryControl(
                                      key: const ValueKey('pause'),
                                      onPressed: c.pause,
                                      icon: Icons.pause,
                                      label: 'Pausar',
                                      wide: wide,
                                    ),
                                  if (phase == GamePhase.paused)
                                    _primaryControl(
                                      key: const ValueKey('resume'),
                                      onPressed: c.resume,
                                      icon: Icons.play_arrow,
                                      label: 'Continuar',
                                      wide: wide,
                                    ),
                                  if (phase == GamePhase.finished)
                                    IconButton(
                                      tooltip: 'Silenciar alarma',
                                      onPressed: c.silence,
                                      icon: const Icon(Icons.volume_off),
                                    ),
                                  if (phase != GamePhase.running)
                                    IconButton(
                                      key: const ValueKey('settings'),
                                      tooltip: phase == GamePhase.ready
                                          ? 'Configurar partida'
                                          : 'Configuración',
                                      onPressed: _settings,
                                      icon: const Icon(Icons.tune),
                                    ),
                                  if (phase != GamePhase.ready)
                                    IconButton(
                                      key: const ValueKey('reset'),
                                      tooltip: phase == GamePhase.finished
                                          ? 'Nueva partida'
                                          : 'Reiniciar partida',
                                      onPressed: _reset,
                                      icon: const Icon(Icons.restart_alt),
                                    ),
                                ],
                              ),
                              if (wide && c.engine.pauseReason != null)
                                Text(
                                  c.engine.pauseReason!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                    return wide
                        // Android already rotates the window. Extra quarter turns
                        // would cancel that rotation for the clocks themselves.
                        ? Row(children: [panel(1, 2), controls, panel(0, 0)])
                        : Column(
                            children: [panel(1, 2), controls, panel(0, 0)],
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

  Widget _primaryControl({
    required Key key,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool wide,
  }) {
    if (!wide)
      return FilledButton.icon(
        key: key,
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    return FilledButton(
      key: key,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
        ],
      ),
    );
  }
}

class PlayerPanel extends StatelessWidget {
  final GameController controller;
  final int player;
  const PlayerPanel({
    super.key,
    required this.controller,
    required this.player,
  });
  @override
  Widget build(BuildContext context) {
    final e = controller.engine;
    final active = e.phase == GamePhase.running && e.activePlayer == player;
    final expired = e.expiredPlayer == player;
    final finished = e.phase == GamePhase.finished;
    final accent = player == 0
        ? const Color(0xffefba63)
        : const Color(0xff8ac9ec);
    final us = e.valueUs(player);
    final text = formatClock(
      us,
      countdown: e.config.mode != ClockMode.stopwatch,
    );
    final status = expired
        ? 'TIEMPO AGOTADO'
        : finished
        ? 'PARTIDA FINALIZADA'
        : active
        ? 'TU TURNO'
        : e.phase == GamePhase.ready
        ? (e.activePlayer == player ? 'EMPIEZA' : 'PREPARADO')
        : e.phase == GamePhase.paused
        ? 'EN PAUSA'
        : e.config.mode == ClockMode.stopwatch
        ? 'ÚLTIMA JUGADA'
        : 'EN ESPERA';
    final fraction = e.config.mode == ClockMode.stopwatch
        ? (us % 60000000) / 60000000
        : us / (e.config.limitsMs[player] * 1000);
    return Semantics(
      label:
          '${e.config.names[player]}. $status. $text. ${e.moves[player]} jugadas.'
          '${active ? ' Terminar jugada.' : ''}',
      button: active,
      liveRegion: false,
      onTap: active ? () => controller.press(player) : null,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => controller.pointerDown(event.pointer, player),
        onPointerUp: (event) => controller.pointerUp(event.pointer),
        onPointerCancel: (event) => controller.pointerUp(event.pointer),
        child: AnimatedContainer(
          key: ValueKey('panel-$player'),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 90),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff343c45), Color(0xff20262d)],
            ),
            border: Border.all(
              color: expired
                  ? const Color(0xffff8f83)
                  : active
                  ? accent
                  : const Color(0xff535d67),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xaa000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              // Keep the dial large; the footer adapts to short windows and
              // enlarged text without moving the time away from its plunger.
              final buttonWidth = math
                  .min(148.0, math.min(box.maxWidth * .44, box.maxHeight * .48))
                  .clamp(64.0, 148.0);
              final footerHeight = buttonWidth / MoveButton.aspectRatio;
              return Column(
                children: [
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.config.names[player],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${e.moves[player]} jug.',
                          style: const TextStyle(
                            color: Color(0xffc6cbd0),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CustomPaint(
                            key: ValueKey('dial-$player'),
                            painter: ClockDial(
                              fraction: fraction,
                              accent: accent,
                              expired: expired,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: footerHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _readout(text, status, expired)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: buttonWidth,
                          height: footerHeight,
                          child: finished
                              ? Center(
                                  child:
                                      buttonWidth <
                                          116 *
                                              MediaQuery.textScalerOf(
                                                context,
                                              ).scale(1)
                                      ? IconButton(
                                          tooltip: 'Silenciar alarma',
                                          onPressed: controller.silence,
                                          icon: const Icon(Icons.volume_off),
                                        )
                                      : OutlinedButton.icon(
                                          onPressed: controller.silence,
                                          icon: const Icon(
                                            Icons.volume_off,
                                            size: 20,
                                          ),
                                          label: const Text('Silenciar'),
                                        ),
                                )
                              : ExcludeSemantics(
                                  child: MoveButton(
                                    key: ValueKey('move-button-$player'),
                                    raised: e.activePlayer == player,
                                    player: player,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _readout(String text, String status, bool expired) => ExcludeSemantics(
    child: FittedBox(
      key: ValueKey('readout-$player'),
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            key: ValueKey('time-$player'),
            style: const TextStyle(
              fontSize: 62,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: Color(0xfff7f0e2),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            key: ValueKey('status-$player'),
            maxLines: 1,
            style: TextStyle(
              color: expired
                  ? const Color(0xffffa399)
                  : const Color(0xfff2ead8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}
