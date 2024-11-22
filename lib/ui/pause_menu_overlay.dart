import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/game_config.dart';
import '../game/states/game_state.dart';

class PauseMenuOverlay extends StatefulWidget {
  static const String id = 'pause_menu';
  final GameState gameState;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final Vector2 size;

  const PauseMenuOverlay({
    super.key,
    required this.gameState,
    required this.onResume,
    required this.onRestart,
    required this.size,
  });

  @override
  State<PauseMenuOverlay> createState() => _PauseMenuOverlayState();
}

class _PauseMenuOverlayState extends State<PauseMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  double _sfxVolume = 1.0;
  double _musicVolume = 1.0;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sfxVolume = prefs.getDouble('sfx_volume') ?? 1.0;
      _musicVolume = prefs.getDouble('music_volume') ?? 1.0;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', _sfxVolume);
    await prefs.setDouble('music_volume', _musicVolume);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: widget.size.x * 0.8,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: GameConfig.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: GameConfig.primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PAUSED',
                        style: GameConfig.titleStyle.copyWith(
                          fontSize: 48,
                          color: GameConfig.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSettingSlider(
                        'SFX Volume',
                        _sfxVolume,
                        (value) {
                          setState(() => _sfxVolume = value);
                          _saveSettings();
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildSettingSlider(
                        'Music Volume',
                        _musicVolume,
                        (value) {
                          setState(() => _musicVolume = value);
                          _saveSettings();
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildSettingSwitch(
                        'Vibration',
                        _vibrationEnabled,
                        (value) {
                          setState(() => _vibrationEnabled = value);
                          _saveSettings();
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMenuButton(
                            'RESUME',
                            GameConfig.primaryColor,
                            widget.onResume,
                          ),
                          _buildMenuButton(
                            'RESTART',
                            GameConfig.secondaryColor,
                            widget.onRestart,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GameConfig.subtitleStyle.copyWith(
            fontSize: 20,
            color: GameConfig.primaryColor,
          ),
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: GameConfig.primaryColor,
          inactiveColor: GameConfig.primaryColor.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildSettingSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GameConfig.subtitleStyle.copyWith(
            fontSize: 20,
            color: GameConfig.primaryColor,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: GameConfig.primaryColor,
          activeTrackColor: GameConfig.primaryColor.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildMenuButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
