import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/game_controller.dart';
import '../domain/clock.dart';

String modeLabel(ClockMode mode) => switch (mode) {
  ClockMode.perMove => 'Por jugada',
  ClockMode.total => 'Tiempo total',
  ClockMode.stopwatch => 'Cronómetro',
};

class SettingsPage extends StatefulWidget {
  final GameController controller;
  final bool gameInProgress;
  const SettingsPage({
    super.key,
    required this.controller,
    this.gameInProgress = false,
  });
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _form = GlobalKey<FormState>();
  late ClockMode mode;
  late bool equal, sound, vibration;
  late int first;
  late List<TextEditingController> names, minutes, seconds;
  @override
  void initState() {
    super.initState();
    final c = widget.controller.engine.config;
    mode = c.mode;
    equal = c.equalLimits;
    sound = c.sound;
    vibration = c.vibration;
    first = c.firstPlayer;
    names = c.names.map((n) => TextEditingController(text: n)).toList();
    minutes = c.limitsMs
        .map((m) => TextEditingController(text: '${m ~/ 60000}'))
        .toList();
    seconds = c.limitsMs
        .map((m) => TextEditingController(text: '${m ~/ 1000 % 60}'))
        .toList();
  }

  @override
  void dispose() {
    for (final c in [...names, ...minutes, ...seconds]) {
      c.dispose();
    }
    super.dispose();
  }

  int limit(int i) =>
      ((int.tryParse(minutes[i].text) ?? -1000) * 60 +
          (int.tryParse(seconds[i].text) ?? -1000)) *
      1000;
  String? validate(String? value, int i, bool isSeconds) {
    final v = int.tryParse(value ?? '');
    if (v == null || v < 0 || (isSeconds && v > 59))
      return isSeconds ? '0 a 59' : '0 a 180';
    if (limit(i) < 1000 || limit(i) > 10800000) return '1 s a 180 min';
    return null;
  }

  void save() {
    if (!widget.gameInProgress && mode != ClockMode.stopwatch) {
      for (var i = 0; i < (equal ? 1 : 2); i++) {
        if (validate(minutes[i].text, i, false) != null ||
            validate(seconds[i].text, i, true) != null) {
          _form.currentState!.validate();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ingresá minutos y segundos válidos: de 1 segundo a 180 minutos.',
              ),
            ),
          );
          return;
        }
      }
    }
    if (!_form.currentState!.validate()) return;
    if (widget.gameInProgress) {
      widget.controller.audio(sound, vibration);
    } else {
      final limits = mode == ClockMode.stopwatch
          ? widget.controller.engine.config.limitsMs
          : [limit(0), equal ? limit(0) : limit(1)];
      widget.controller.configure(
        ClockConfig(
          mode: mode,
          limitsMs: equal ? [limits[0], limits[0]] : limits,
          names: [
            for (var i = 0; i < 2; i++)
              names[i].text.trim().isEmpty
                  ? 'Jugador ${i + 1}'
                  : names[i].text.trim(),
          ],
          firstPlayer: first,
          equalLimits: equal,
          sound: sound,
          vibration: vibration,
          orientation: widget.controller.engine.config.orientation,
        ),
      );
    }
    widget.controller.silence();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.gameInProgress ? 'Configuración' : 'Preparar partida'),
    ),
    body: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<ClockOrientation>(
              key: const ValueKey('orientation-setting'),
              initialValue: widget.controller.engine.config.orientation,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Orientación'),
              items: const [
                DropdownMenuItem(
                  value: ClockOrientation.automatic,
                  child: Text('Automática'),
                ),
                DropdownMenuItem(
                  value: ClockOrientation.portrait,
                  child: Text('Vertical'),
                ),
                DropdownMenuItem(
                  value: ClockOrientation.landscape,
                  child: Text('Horizontal'),
                ),
              ],
              onChanged: (value) {
                if (value != null) widget.controller.setOrientation(value);
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Automática sigue el giro del teléfono. Vertical y Horizontal fijan la disposición. Se aplica al elegirla y se guarda. Los paneles siempre quedan enfrentados.',
            ),
            const SizedBox(height: 24),
            if (!widget.gameInProgress) ...[
              const Text(
                'chessclock',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('Un teléfono. Dos jugadores. Cada segundo cuenta.'),
              const SizedBox(height: 24),
              DropdownButtonFormField<ClockMode>(
                initialValue: mode,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Modo de reloj'),
                items: [
                  for (final m in ClockMode.values)
                    DropdownMenuItem(value: m, child: Text(modeLabel(m))),
                ],
                onChanged: (m) => setState(() {
                  mode = m!;
                }),
              ),
              const SizedBox(height: 12),
              Text(switch (mode) {
                ClockMode.perMove =>
                  'El límite se renueva al comenzar cada turno. El sobrante no se acumula.',
                ClockMode.total =>
                  'Cada participante usa su reserva a lo largo de toda la partida.',
                ClockMode.stopwatch =>
                  'Cada jugada cuenta desde cero, sin límite ni alarma de vencimiento.',
              }),
              if (mode != ClockMode.stopwatch) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mismo tiempo para ambos'),
                  value: equal,
                  onChanged: (v) => setState(() {
                    equal = v;
                  }),
                ),
                for (var i = 0; i < (equal ? 1 : 2); i++) ...[
                  const SizedBox(height: 12),
                  Text(
                    equal
                        ? 'Tiempo por participante'
                        : 'Tiempo · Jugador ${i + 1}',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('minutes-$i'),
                          controller: minutes[i],
                          decoration: const InputDecoration(
                            labelText: 'Minutos',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) => validate(v, i, false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('seconds-$i'),
                          controller: seconds[i],
                          decoration: const InputDecoration(
                            labelText: 'Segundos',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) => validate(v, i, true),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s
                          in mode == ClockMode.perMove
                              ? [15, 30, 60, 120]
                              : [60, 180, 300, 600])
                        ActionChip(
                          label: Text(s < 60 ? '$s s' : '${s ~/ 60} min'),
                          onPressed: () => setState(() {
                            minutes[i].text = '${s ~/ 60}';
                            seconds[i].text = '${s % 60}';
                          }),
                        ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 20),
              for (var i = 0; i < 2; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: names[i],
                    maxLength: 24,
                    decoration: InputDecoration(
                      labelText: 'Nombre · Jugador ${i + 1}',
                    ),
                  ),
                ),
              DropdownButtonFormField<int>(
                initialValue: first,
                decoration: const InputDecoration(labelText: 'Empieza'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Jugador 1')),
                  DropdownMenuItem(value: 1, child: Text('Jugador 2')),
                ],
                onChanged: (v) => first = v!,
              ),
              const SizedBox(height: 20),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sonido de alarma'),
              subtitle: const Text('Usa el volumen de alarma del dispositivo'),
              value: sound,
              onChanged: (v) => setState(() => sound = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vibración'),
              value: vibration,
              onChanged: (v) => setState(() => vibration = v),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      widget.controller.testAlarm(sound, vibration),
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('Probar alarma'),
                ),
                TextButton(
                  onPressed: widget.controller.silence,
                  child: const Text('Silenciar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('save-settings'),
              onPressed: save,
              child: const Text('Guardar'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Apoyá el teléfono entre ambos. Tocá tu panel al completar una jugada. El panel en espera no cambia el turno. Una interrupción pausa la partida; para retomarla, tocá Continuar.',
            ),
          ],
        ),
      ),
    ),
  );
}
