import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/parent_pin_service.dart';
import '../services/pin_reset_email_service.dart';
import 'parent_panel_screen.dart';

/// Ebeveyn paneli giriş kapısı - PIN veya biyometrik doğrulama
class ParentPinGateScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ParentPinGateScreen({super.key, required this.onBack});

  @override
  State<ParentPinGateScreen> createState() => _ParentPinGateScreenState();
}

class _ParentPinGateScreenState extends State<ParentPinGateScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showSetup = false;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final pinService = Provider.of<ParentPinService>(context, listen: false);
    final hasPin = await pinService.hasPin();
    if (!mounted) return;
    setState(() {
      _showSetup = !hasPin;
      if (pinService.isLocked) {
        _startLockoutTimer();
      }
    });
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    final pinService = Provider.of<ParentPinService>(context, listen: false);
    void tick() {
      if (!mounted) return;
      final remaining = pinService.remainingLockoutSeconds;
      if (remaining <= 0) {
        _lockoutTimer?.cancel();
        setState(() {});
        return;
      }
      setState(() {});
    }
    tick();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndOpen() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() {
        _errorMessage = 'PIN 4 haneli olmalıdır';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final pinService = Provider.of<ParentPinService>(context, listen: false);
    final ok = await pinService.verifyPin(pin);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _pinController.clear();
    });

    if (ok) {
      _openPanel();
    } else {
      if (pinService.isLocked) {
        _startLockoutTimer();
        setState(() {
          _errorMessage = '3 yanlış deneme. ${pinService.lockoutMinutes} dakika kilitlendiniz.';
        });
      } else {
        setState(() {
          _errorMessage =
              'Yanlış PIN. Kalan deneme: ${pinService.maxAttempts - pinService.failedAttempts}';
        });
      }
    }
  }

  Future<void> _tryBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final pinService = Provider.of<ParentPinService>(context, listen: false);
    final ok = await pinService.authenticateWithBiometrics();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (ok) {
      _openPanel();
    } else {
      setState(() {
        _errorMessage = 'Biyometrik doğrulama başarısız';
      });
    }
  }

  void _openPanel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ParentPanelScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openForgotPinFlow() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ForgotPinDialog(
        onSuccess: () {
          Navigator.pop(ctx);
          setState(() {
            _errorMessage = null;
            _pinController.clear();
          });
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
          ),
        ),
        child: SafeArea(
          child: _showSetup
              ? _buildSetupView()
              : _buildVerifyView(),
        ),
      ),
    );
  }

  Widget _buildVerifyView() {
    return Consumer<ParentPinService>(
      builder: (context, pinService, _) {
        final locked = pinService.isLocked;
        final remaining = pinService.remainingLockoutSeconds;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.lock_outline, size: 80, color: Colors.white70),
              const SizedBox(height: 24),
              const Text(
                'Ebeveyn Paneli',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Devam etmek için PIN girin',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (locked) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_clock, size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        'Çok fazla yanlış deneme',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')} sonra tekrar deneyin',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                FutureBuilder<bool>(
                  future: pinService.canUseBiometrics(),
                  builder: (context, snapshot) {
                    if (snapshot.data != true) return const SizedBox();
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _tryBiometric,
                          icon: const Icon(Icons.fingerprint, size: 28),
                          label: const Text('Parmak İzi / Yüz ile Giriş'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'veya PIN ile',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 12,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    errorText: _errorMessage,
                    errorStyle: const TextStyle(color: Colors.amber),
                  ),
                  onSubmitted: (_) => _verifyAndOpen(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _verifyAndOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Giriş Yap'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _openForgotPinFlow,
                  child: Text(
                    'PIN\'i unuttum',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                label: const Text('Geri', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetupView() {
    return _ParentPinSetupView(
      onSuccess: () {
        setState(() {
          _showSetup = false;
          _errorMessage = null;
        });
        _openPanel();
      },
      onBack: widget.onBack,
    );
  }
}

/// PIN kurulum ekranı (ilk kez)
class _ParentPinSetupView extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onBack;

  const _ParentPinSetupView({
    required this.onSuccess,
    required this.onBack,
  });

  @override
  State<_ParentPinSetupView> createState() => _ParentPinSetupViewState();
}

class _ParentPinSetupViewState extends State<_ParentPinSetupView> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  bool _includeSecurityQuestion = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length != 4) {
      setState(() => _errorMessage = 'PIN 4 haneli olmalıdır');
      return;
    }
    if (pin != confirm) {
      setState(() => _errorMessage = 'PIN\'ler eşleşmiyor');
      return;
    }
    if (_includeSecurityQuestion) {
      final q = _questionController.text.trim();
      final a = _answerController.text.trim();
      if (q.isEmpty || a.isEmpty) {
        setState(() => _errorMessage = 'Güvenlik sorusu ve cevabı gerekli');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final pinService = Provider.of<ParentPinService>(context, listen: false);
    final ok = await pinService.setPin(
      pin,
      securityQuestion: _includeSecurityQuestion ? _questionController.text.trim() : null,
      securityAnswer: _includeSecurityQuestion ? _answerController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      widget.onSuccess();
    } else {
      setState(() => _errorMessage = 'Bir hata oluştu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.security, size: 64, color: Colors.white70),
          const SizedBox(height: 24),
          const Text(
            'Ebeveyn Paneli PIN Kurulumu',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Paneli korumak için 4 haneli PIN belirleyin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration('PIN'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration('PIN Tekrar'),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text(
              'Güvenlik sorusu ekle (PIN unutulursa)',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            value: _includeSecurityQuestion,
            onChanged: (v) => setState(() => _includeSecurityQuestion = v),
            activeColor: Colors.green,
          ),
          if (_includeSecurityQuestion) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              decoration: _inputDecoration('Güvenlik sorusu (örn: İlk evcil hayvanım?)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              obscureText: true,
              decoration: _inputDecoration('Cevap'),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.amber),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isLoading ? null : _setupPin,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('PIN Oluştur'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            label: const Text('Geri', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

/// PIN unutuldu - e-posta doğrulama kodu ile sıfırlama
class _ForgotPinDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _ForgotPinDialog({
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<_ForgotPinDialog> createState() => _ForgotPinDialogState();
}

enum _ResetStep { sendCode, enterCode, newPin }

class _ForgotPinDialogState extends State<_ForgotPinDialog> {
  final _codeController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  _ResetStep _step = _ResetStep.sendCode;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userEmail;
  final _pinResetService = PinResetEmailService();

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  void _loadUserEmail() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = auth.email;
    if (email != null && email.isNotEmpty) {
      setState(() => _userEmail = email);
    } else {
      setState(() {
        _errorMessage =
            'E-posta adresi bulunamadı. Lütfen e-posta veya Google ile giriş yapın.';
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    final masked = '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}';
    return '$masked@$domain';
  }

  Future<void> _sendCode() async {
    if (_userEmail == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _pinResetService.requestPinResetCode().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Zaman aşımı'),
      );
      if (!mounted) return;
      setState(() {
        _step = _ResetStep.enterCode;
        _isLoading = false;
        _errorMessage = null;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Kod gönderilemedi. Lütfen tekrar deneyin.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('UNAVAILABLE')
            ? 'Sunucuya ulaşılamıyor. Lütfen internet bağlantınızı kontrol edin.'
            : 'Kod gönderilemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = '6 haneli kodu girin');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _pinResetService.verifyPinResetCode(code).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Zaman aşımı'),
      );
      if (!mounted) return;
      setState(() {
        _step = _ResetStep.newPin;
        _isLoading = false;
        _errorMessage = null;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Kod doğrulanamadı.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Kod doğrulanamadı. Lütfen tekrar deneyin.';
      });
    }
  }

  Future<void> _doResetPin() async {
    final newPin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (newPin.length != 4) {
      setState(() => _errorMessage = 'PIN 4 haneli olmalıdır');
      return;
    }
    if (newPin != confirm) {
      setState(() => _errorMessage = 'PIN\'ler eşleşmiyor');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final pinService = Provider.of<ParentPinService>(context, listen: false);
    final ok = await pinService.resetPinAfterEmailVerification(newPin);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      widget.onSuccess();
    } else {
      setState(() => _errorMessage = 'PIN sıfırlanamadı');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C3E50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('PIN Sıfırla', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == _ResetStep.sendCode) ...[
              if (_userEmail != null) ...[
                Text(
                  'E-posta adresinize doğrulama kodu gönderilecek:',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _maskEmail(_userEmail!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ] else if (_step == _ResetStep.enterCode) ...[
              const Text(
                'E-posta adresinize gönderilen 6 haneli kodu girin:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Doğrulama kodu',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: '000000',
                ),
                style: const TextStyle(color: Colors.white, letterSpacing: 8),
              ),
            ] else ...[
              TextField(
                controller: _newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Yeni PIN',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Yeni PIN Tekrar',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.amber)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('İptal', style: TextStyle(color: Colors.white70)),
        ),
        FilledButton(
          onPressed: _isLoading || (_step == _ResetStep.sendCode && _userEmail == null)
              ? null
              : () {
                  if (_step == _ResetStep.sendCode) {
                    _sendCode();
                  } else if (_step == _ResetStep.enterCode) {
                    _verifyCode();
                  } else {
                    _doResetPin();
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _step == _ResetStep.sendCode
                      ? 'Kod Gönder'
                      : _step == _ResetStep.enterCode
                          ? 'Doğrula'
                          : 'PIN Sıfırla',
                ),
        ),
      ],
    );
  }
}
