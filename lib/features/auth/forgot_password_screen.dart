import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../assets/app_assets.dart';
import '../../motion/motion.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_chrome.dart';
import '../../theme/app_colors.dart';
import '../../ui/glass_panel.dart';
import '../../ui/studio_backdrop.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  ActionStatus _status = ActionStatus.idle;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _status = ActionStatus.loading);
    final ok = await ref.read(authProvider.notifier).sendResetLink(_email.text);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _status = ActionStatus.done;
        _sent = true;
      });
    } else {
      setState(() => _status = ActionStatus.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = ref.watch(authProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return ChromeScope(
      top: c.background,
      bottom: c.background,
      child: Scaffold(
        backgroundColor: c.background,
        body: StudioBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      AppPressable(
                        onTap: () => context.pop(),
                        semanticLabel: 'بازگشت',
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            AppAssets.iconBack,
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              c.ink,
                              BlendMode.srcIn,
                            ),
                            matchTextDirection: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'بازیابی رمز',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MotionSlot(
                          'forgot_password.hero',
                          child: Text(
                            'رمز را بازیابی کنید',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: c.ink),
                          ),
                        ),
                        const SizedBox(height: 8),
                        MotionSlot(
                          'forgot_password.content',
                          index: 0,
                          child: Text(
                            'ایمیل حساب خود را بنویسید تا لینک بازنشانی برایتان ارسال شود.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: c.muted),
                          ),
                        ),
                        const SizedBox(height: 22),
                        GlassPanel(
                          child: _sent
                              ? Column(
                                  children: [
                                    AppDrawCheck(
                                      size: 64,
                                      color: c.success,
                                      delay: AppMotion.xs,
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'لینک ارسال شد',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'اگر ${_email.text.trim()} در سیستم باشد، به‌زودی پیام بازیابی را دریافت می‌کنید.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: c.muted),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 22),
                                    AuthPrimaryButton(
                                      label: 'بازگشت به ورود',
                                      status: ActionStatus.idle,
                                      onPressed: () => context.go('/sign-in'),
                                    ),
                                  ],
                                )
                              : Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      AuthField(
                                        controller: _email,
                                        label: 'ایمیل',
                                        hint: 'name@example.com',
                                        iconPath: AppAssets.iconMail,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        textDirection: TextDirection.ltr,
                                        validator: validateEmail,
                                      ),
                                      if (auth.error != null) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          auth.error!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: c.danger),
                                        ),
                                      ],
                                      const SizedBox(height: 18),
                                      MotionSlot(
                                        'forgot_password.action_1',
                                        onTap: _status == ActionStatus.idle
                                            ? _submit
                                            : null,
                                        child: AuthPrimaryButton(
                                          label: 'ارسال لینک',
                                          status: _status,
                                          doneLabel: 'ارسال شد',
                                          onPressed:
                                              _status == ActionStatus.idle
                                                  ? _submit
                                                  : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
