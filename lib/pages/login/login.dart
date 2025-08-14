import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hbfu_alex/src/rust/api/simple.dart';
import 'package:hbfu_alex/components/flush_bar.dart';
import 'package:hbfu_alex/components/window_control_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();

  final studentIDController = TextEditingController();
  final vpnPasswordController = TextEditingController();
  final passwordController = TextEditingController();

  bool passwordVisible = false;
  bool vpnPasswordVisible = false;
  bool savePassword = true;
  bool vpnDifferent = false;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStudentID = prefs.getString('studentID') ?? '';
    final savedPassword = prefs.getString('password') ?? '';
    final savedVpnPassword = prefs.getString('vpnPassword') ?? '';

    setState(() {
      studentIDController.text = savedStudentID;
      passwordController.text = savedPassword;
      vpnPasswordController.text = savedVpnPassword;
      savePassword = savedStudentID.isNotEmpty;
    });
  }

  @override
  void dispose() {
    studentIDController.dispose();
    vpnPasswordController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _onLogin(String studentID, String password, String vpnPassword) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await apiLogin(
        username: studentID,
        vpnPassword: vpnPassword,
        oaPassword: password,
      );

      if (!mounted) return;

      showSuccessFlushbar(context, '欢迎，$studentID');
      await Future.delayed(const Duration(milliseconds: 500));
      if (savePassword) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('studentID', studentID);
        await prefs.setString('password', password);
        if (vpnDifferent) {
          await prefs.setString('vpnPassword', vpnPassword);
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('studentID');
        await prefs.remove('password');
        await prefs.remove('vpnPassword');
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      showErrorFlushbar(context, '登录失败');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Icon(Icons.school, size: 72, color: colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          'Hebei Finance University',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStudentIDField() {
    return TextFormField(
      controller: studentIDController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(14),
      ],
      decoration: InputDecoration(
        labelText: 'Student ID',
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "请输入学号";
        }
        if (value.length != 14) {
          return '学号必须是14位数字';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(passwordVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => passwordVisible = !passwordVisible),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入密码';
        }
        return null;
      },
      obscureText: !passwordVisible,
    );
  }

  Widget _buildVpnPasswordField() {
    if (!vpnDifferent) return const SizedBox.shrink();

    return Column(
      children: [
        TextFormField(
          controller: vpnPasswordController,
          decoration: InputDecoration(
            labelText: 'VPN Password',
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                vpnPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => vpnPasswordVisible = !vpnPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入VPN密码';
            }
            return null;
          },
          obscureText: !vpnPasswordVisible,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Remember',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            value: savePassword,
            onChanged: (val) => setState(() => savePassword = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        Expanded(
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'VPN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            value: vpnDifferent,
            onChanged: (val) => setState(() => vpnDifferent = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(ColorScheme colorScheme, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isLoading
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  final studentID = studentIDController.text.trim();
                  final password = passwordController.text.trim();
                  final vpnPassword = vpnDifferent
                      ? vpnPasswordController.text.trim()
                      : password;
                  _onLogin(studentID, password, vpnPassword);
                }
              },
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    final bool isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    return Scaffold(
      body: Column(
        children: [
          if (isDesktop)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withAlpha(51),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hebei Finance University',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                      ),
                    ),
                    const WindowControlButtons(),
                  ],
                ),
              ),
            ),

          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 400 : double.infinity,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(colorScheme),
                        const SizedBox(height: 32),
                        _buildStudentIDField(),
                        const SizedBox(height: 16),
                        _buildVpnPasswordField(),
                        _buildPasswordField(),
                        const SizedBox(height: 6),
                        _buildOptionsRow(),
                        const SizedBox(height: 12),
                        _buildLoginButton(colorScheme, _isLoading),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
