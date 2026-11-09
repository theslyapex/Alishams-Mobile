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

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  ActionStatus _status = ActionStatus.idle;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _status = ActionStatus.loading);
    final ok = await ref.read(authProvider.notifier).signIn(
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    if (ok) {
      setState(() => _status = ActionStatus.done);
      await Future<void>.delayed(AppMotion.md);
      if (!mounted) return;
      context.go('/home');
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
        resizeToAvoidBottomInset: true,
        body: StudioBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),
                        MotionSlot(
                          'sign_in.hero',
                          child: Column(
                            children: [
                              SvgPicture.asset(
                                AppAssets.logo,
                                width: 64,
                                height: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ورود به علی‌شمس',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: c.ink),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'حساب استودیو دیجیتال خود را باز کنید',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: c.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        MotionSlot(
                          'sign_in.content',
                          index: 0,
                          child: GlassPanel(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AuthField(
                                    controller: _email,
                                    label: 'ایمیل',
                                    hint: 'name@example.com',
                                    iconPath: AppAssets.iconMail,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.email,
                                    ],
                                    textDirection: TextDirection.ltr,
                                    validator: validateEmail,
                                  ),
                                  const SizedBox(height: 16),
                                  AuthField(
                                    controller: _password,
                                    label: 'رمز عبور',
                                    hint: '••••••••',
                                    iconPath: AppAssets.iconLock,
                                    obscureText: _obscure,
                                    onToggleObscure: () => setState(
                                      () => _obscure = !_obscure,
                                    ),
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    textDirection: TextDirection.ltr,
                                    validator: validatePassword,
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: AuthTextLink(
                                      label: 'رمز عبور را فراموش کرده‌اید؟',
                                      onTap: () =>
                                          context.push('/forgot-password'),
                                    ),
                                  ),
                                  if (auth.error != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      auth.error!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: c.danger),
                                      textAlign: TextAlign.start,
                                    ),
                                  ],
                                  if (auth.notice != null) ...[
                                    const SizedBox(height: 8),
                                    Text(auth.notice!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.success), textAlign: TextAlign.center),
                                  ],
                                  const SizedBox(height: 18),
                                  AuthPrimaryButton(
                                    label: 'ورود',
                                    status: _status,
                                    doneLabel: 'خوش آمدید',
                                    onPressed: _status == ActionStatus.idle
                                        ? _submit
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'حساب ندارید؟',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: c.muted),
                                      ),
                                      AuthTextLink(
                                        label: 'ثبت‌نام',
                                        emphasize: true,
                                        onTap: () => context.push('/sign-up'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
