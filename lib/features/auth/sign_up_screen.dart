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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  ActionStatus _status = ActionStatus.idle;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _status = ActionStatus.loading);
    final ok = await ref.read(authProvider.notifier).signUp(
          name: _name.text,
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
                          'ساخت حساب',
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
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'به استودیو بپیوندید',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: c.ink),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'نام و ایمیل خود را وارد کنید تا سفارش‌ها و باشگاه مشتریان در دسترس باشد.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: c.muted),
                        ),
                        const SizedBox(height: 22),
                        MotionSlot(
                          'sign_up.surface',
                          child: GlassPanel(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AuthField(
                                    controller: _name,
                                    label: 'نام و نام خانوادگی',
                                    hint: 'مثلاً سارا محمدی',
                                    iconPath: AppAssets.iconUser,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    validator: validateName,
                                  ),
                                  const SizedBox(height: 16),
                                  AuthField(
                                    controller: _email,
                                    label: 'ایمیل',
                                    hint: 'name@example.com',
                                    iconPath: AppAssets.iconMail,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    textDirection: TextDirection.ltr,
                                    validator: validateEmail,
                                  ),
                                  const SizedBox(height: 16),
                                  AuthField(
                                    controller: _password,
                                    label: 'رمز عبور',
                                    hint: 'حداقل ۶ کاراکتر',
                                    iconPath: AppAssets.iconLock,
                                    obscureText: _obscure,
                                    onToggleObscure: () => setState(
                                      () => _obscure = !_obscure,
                                    ),
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    textDirection: TextDirection.ltr,
                                    validator: validatePassword,
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
                                  if (auth.notice != null) ...[
                                    const SizedBox(height: 10),
                                    Text(auth.notice!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.success)),
                                  ],
                                  const SizedBox(height: 18),
                                  MotionSlot(
                                    'sign_up.action_1',
                                    onTap: _status == ActionStatus.idle
                                        ? _submit
                                        : null,
                                    child: AuthPrimaryButton(
                                      label: 'ثبت‌نام',
                                      status: _status,
                                      doneLabel: 'حساب ساخته شد',
                                      onPressed: _status == ActionStatus.idle
                                          ? _submit
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'قبلاً حساب دارید؟',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: c.muted),
                                      ),
                                      AuthTextLink(
                                        label: 'ورود',
                                        emphasize: true,
                                        onTap: () => context.go('/sign-in'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
