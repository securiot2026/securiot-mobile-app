import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/error_localizer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/language_switcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    await auth.login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.appTitle),
        actions: const [LanguageSwitcher()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Wordmark(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.loginTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.ink.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (auth.sessionExpired) ...[
                      _InlineNotice(text: l10n.sessionExpired),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (auth.loginError != null) ...[
                      _InlineNotice(text: l10n.messageFor(auth.loginError!), isError: true),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l10n.emailLabel),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return l10n.t('validationEmailRequired');
                        if (!v.contains('@') || !v.contains('.')) {
                          return l10n.t('validationEmailInvalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(l10n),
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        suffixIcon: Semantics(
                          button: true,
                          label: _obscurePassword ? l10n.passwordLabel : l10n.passwordLabel,
                          child: IconButton(
                            constraints: const BoxConstraints(
                              minWidth: AppSpacing.minTouchTarget,
                              minHeight: AppSpacing.minTouchTarget,
                            ),
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) return l10n.t('validationPasswordRequired');
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: auth.isSubmitting ? null : () => _submit(l10n),
                      child: auth.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.signInButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.shield_outlined, color: AppColors.accent, size: 30),
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.destructive : AppColors.ink;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.info_outline, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text, style: TextStyle(color: color))),
          ],
        ),
      ),
    );
  }
}
