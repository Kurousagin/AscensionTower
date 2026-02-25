import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/services/save_service.dart';
import '../providers/game_provider.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

class TitleScreen extends StatefulWidget {
  final VoidCallback onStartGame;
  const TitleScreen({super.key, required this.onStartGame});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        return Scaffold(
          backgroundColor: AppTheme.bg,
          body: ScanlineOverlay(
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTowerArt(),
                        const SizedBox(height: 24),
                        const TerminalText(
                          'THE TOWER OF THE',
                          fontSize: 10,
                          color: AppTheme.textDim,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const TerminalText(
                          'SECOND HUMANITY',
                          fontSize: 20,
                          color: AppTheme.cyan,
                          fontWeight: FontWeight.bold,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const TerminalText(
                          'v1.0 MVP',
                          fontSize: 9,
                          color: AppTheme.textDim,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (_showContent) ...[
                          _buildAsciiDivider(),
                          const SizedBox(height: 16),
                          const TerminalText(
                            'Humanos comuns foram invocados para uma torre\nmisteriosa com 100 andares. Sobreviva. Evolua.\nConstrua uma sociedade. Suba.',
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TerminalButton(
                            label: 'NOVO JOGO',
                            icon: Icons.play_arrow,
                            expanded: true,
                            onPressed: () async {
                              if (!gp.canCreateNewSave()) {
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text(
                                      'Limite de saves atingido',
                                    ),
                                    content: const TerminalText(
                                      'Você atingiu o limite máximo de saves.\nExclua um save para criar um novo.',
                                      color: AppTheme.textPrimary,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const TerminalText(
                                          'OK',
                                          color: AppTheme.textDim,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              gp.newGame();
                              await gp.saveGame();
                              setState(() {});
                              widget.onStartGame();
                            },
                          ),
                          if (gp.anySave) ...[
                            const SizedBox(height: 12),
                            TerminalButton(
                              label: 'CONTINUAR',
                              icon: Icons.folder_open,
                              color: AppTheme.green,
                              expanded: true,
                              onPressed: () async {
                                final slots = SaveService.listSlots();
                                String? selectedSlot = await showDialog<String>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Escolha o save'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: slots
                                          .map(
                                            (slot) => ListTile(
                                              title: TerminalText(
                                                'Save $slot',
                                                fontSize: 10,
                                              ),
                                              onTap: () =>
                                                  Navigator.pop(ctx, slot),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                );
                                if (selectedSlot != null) {
                                  gp.setSlot(selectedSlot);
                                  await gp.loadGame();
                                  widget.onStartGame();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            TerminalButton(
                              label: 'APAGAR SAVE',
                              icon: Icons.delete,
                              color: AppTheme.red,
                              expanded: true,
                              onPressed: () async {
                                final slots = SaveService.listSlots();
                                String? selectedSlot = await showDialog<String>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text(
                                      'Escolha o save para apagar',
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: slots
                                          .map(
                                            (slot) => ListTile(
                                              title: TerminalText(
                                                'Save $slot',
                                                fontSize: 10,
                                              ),
                                              onTap: () =>
                                                  Navigator.pop(ctx, slot),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                );
                                if (selectedSlot != null) {
                                  gp.setSlot(selectedSlot);
                                  _confirmDelete(context, gp);
                                  setState(
                                    () {},
                                  ); // Atualiza a tela após apagar
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 32),
                          _buildCredits(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTowerArt() {
    const art = '''
         /\\
        /  \\
       /    \\
      /  []  \\
     /--------\\
    /   [][]   \\
   /------------\\
  /  [][][][]    \\
 /----------------\\
/  [][][][][][]    \\
|==================|
|   TOWER  v1.0    |
|==================|''';
    return TerminalText(
      art,
      fontSize: 9,
      color: AppTheme.cyan,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAsciiDivider() {
    return const TerminalText(
      '════════════════════════════════',
      fontSize: 10,
      color: AppTheme.border,
      textAlign: TextAlign.center,
    );
  }

  void _confirmDelete(BuildContext context, GameProvider gp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CONFIRMAR'),
        content: const TerminalText(
          'Apagar save permanentemente?\nEsta acao nao pode ser desfeita.',
          color: AppTheme.textPrimary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TerminalText('CANCELAR', color: AppTheme.textDim),
          ),
          TextButton(
            onPressed: () {
              gp.deleteSave();
              Navigator.pop(ctx);
            },
            child: const TerminalText('APAGAR', color: AppTheme.red),
          ),
        ],
      ),
    );
  }

  Widget _buildCredits() {
    return const Column(
      children: [
        TerminalText(
          '// Desenvolvido por Kurousagin and Kira',
          fontSize: 8,
          color: AppTheme.textDim,
          textAlign: TextAlign.center,
        ),
        TerminalText(
          '// Simulacao deterministica + probabilistica',
          fontSize: 8,
          color: AppTheme.textDim,
          textAlign: TextAlign.center,
        ),
        TerminalText(
          '// 100% offline | Dados locais',
          fontSize: 8,
          color: AppTheme.textDim,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
