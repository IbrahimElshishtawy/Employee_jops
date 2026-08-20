import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../controllers/auth_controller.dart';

/// Login Screen for HR Portal
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: EnvConfig.enableMockData ? 'admin@cyberwise.test' : '');
  final _passwordController = TextEditingController(text: EnvConfig.enableMockData ? 'password123' : '');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authCtrl = context.read<AuthController>();
      final success = await authCtrl.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (success && mounted) {
        context.go(RouteNames.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo & Branding
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 42,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space20),
                      Text(
                        AppStrings.loginTitle,
                        style: AppTypography.heading2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        AppStrings.loginSubtitle,
                        style: AppTypography.subtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.space24),

                      // Error message if any
                      if (authCtrl.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.space12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authCtrl.errorMessage!,
                                  style: AppTypography.captionBold.copyWith(color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // Email Field
                      HrTextField(
                        label: AppStrings.email,
                        hint: 'hr.admin@cyberwise.internal',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        validator: Validator.email,
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Password Field
                      HrTextField(
                        label: AppStrings.password,
                        hint: '••••••••',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (v) => Validator.minLength(v, 6, 'Password must be at least 6 characters'),
                      ),
                      const SizedBox(height: AppDimensions.space24),

                      // Submit Button
                      HrButton(
                        label: AppStrings.signIn,
                        onPressed: _handleSubmit,
                        isLoading: authCtrl.isLoading,
                      ),

                      if (EnvConfig.enableMockData) ...[
                        const SizedBox(height: AppDimensions.space16),
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.space8),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                          child: Text(
                            AppStrings.mockLoginNote,
                            style: AppTypography.caption.copyWith(color: const Color(0xFFD97706)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
