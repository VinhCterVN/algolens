import 'package:algolens/core/theme/app_theme.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_form_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

const authMuted = Color(0xFF5E5E5E);
const authPanel = Color(0xFFF3F3F3);
const authInk = Color(0xFF1A1C1C);

TextStyle mono([double size = 11]) => TextStyle(fontFamily: 'JetBrainsMono', fontSize: size, color: authMuted);

class FigmaIcon extends StatelessWidget {
  const FigmaIcon(this.name, {super.key, this.color, this.width, this.height});

  final String name;
  final Color? color;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      'assets/auth/$name.svg',
      excludeFromSemantics: true,
      colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
    // Scale the wrapper when needed; preserve the exported SVG root geometry.
    return width == null && height == null
        ? icon
        : SizedBox(
            width: width,
            height: height,
            child: FittedBox(fit: BoxFit.contain, child: icon),
          );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.assetPrefix,
    required this.backAsset,
    required this.userAsset,
    required this.child,
    this.onBack,
    this.topPadding = 16,
  });

  final String title, assetPrefix, backAsset, userAsset;
  final Widget child;
  final VoidCallback? onBack;
  final double topPadding;

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.light,
    child: Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 56,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: onBack ?? SystemNavigator.pop,
          icon: FigmaIcon('${assetPrefix}_$backAsset'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
              child: const Text(
                'λ',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Account help',
            onPressed: () => showAuthHelp(context),
            icon: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: FigmaIcon('${assetPrefix}_$userAsset'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(16, topPadding, 16, 48), child: child),
          ),
        ),
      ),
    ),
  );
}

void showAuthHelp(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Your AlgoLens account'),
    content: const Text(
      'Sign in with your email or an enabled identity provider. Educator access is approved by an administrator. If you use a university identity provider, recover your password through that provider.',
    ),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
  ),
);

class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.child,
    this.padding = 24,
    this.background = Colors.white,
    this.shadow = false,
  });

  final Widget child;
  final double padding;
  final Color background;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
      boxShadow: shadow ? [const BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))] : null,
    ),
    child: child,
  );
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.password = false,
    this.visible = false,
    this.onToggle,
    this.prefix,
    this.suffix,
    this.trailing,
    this.onChanged,
    this.email = false,
    this.enabled = true,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final bool password, visible, email, enabled;
  final VoidCallback? onToggle;
  final Widget? prefix, suffix, trailing;
  final ValueChanged<String>? onChanged, onSubmitted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          ?trailing,
        ],
      ),
      const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: password && !visible,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.done,
        autocorrect: !password && !email,
        enableSuggestions: !password,
        autofillHints: email
            ? [AutofillHints.email]
            : password
            ? [AutofillHints.password]
            : [AutofillHints.name],
        style: const TextStyle(fontSize: 14),
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefix == null ? null : Center(widthFactor: 1, child: prefix),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 44),
          suffixIcon: password
              ? IconButton(
                  tooltip: visible ? 'Hide password' : 'Show password',
                  onPressed: enabled ? onToggle : null,
                  icon: suffix ?? Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                )
              : suffix == null
              ? null
              : Center(widthFactor: 1, child: suffix),
          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 44),
        ),
      ),
    ],
  );
}

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.secondary = false,
    this.leading,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy, secondary;
  final Widget? leading, trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        backgroundColor: secondary ? authPanel : Colors.black,
        foregroundColor: secondary ? authInk : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
    ),
  );
}

class AuthFeedback extends StatelessWidget {
  const AuthFeedback(this.model, {super.key});

  final AuthFormViewModel model;

  @override
  Widget build(BuildContext context) {
    final text = model.error ?? model.message;
    return text == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: authPanel, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  text,
                  style: TextStyle(fontSize: 13, color: model.error == null ? authInk : const Color(0xFF9C2020)),
                ),
              ),
            ),
          );
  }
}

class SessionCheckbox extends StatelessWidget {
  const SessionCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
    this.checkAsset,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget child;
  final String? checkAsset;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: value,
    child: InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value ? Colors.black : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value
                  ? checkAsset == null
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : FigmaIcon(checkAsset!, width: 11.188, height: 8.531)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class CodeInput extends StatefulWidget {
  const CodeInput({super.key, required this.onChanged, this.enabled = true});

  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());

  void _change(int index, String value) {
    if (value.length > 1) {
      final start = value.length == 6 ? 0 : index;
      for (var i = 0; i < value.length && start + i < 6; i++) {
        _controllers[start + i].text = value[i];
      }
      _focus[(start + value.length).clamp(0, 5)].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _focus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 6; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _controllers[i],
            focusNode: _focus[i],
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            autofillHints: i == 0 ? [AutofillHints.oneTimeCode] : null,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            textAlign: TextAlign.center,
            style: mono(14).copyWith(color: authInk),
            decoration: InputDecoration(
              hintText: '·',
              semanticCounterText: 'Code digit ${i + 1}',
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
            ),
            onChanged: (value) => _change(i, value),
          ),
        ),
      ],
    ],
  );
}

class StatusStrip extends StatelessWidget {
  const StatusStrip({super.key, required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: authPanel, borderRadius: BorderRadius.circular(6)),
    child: Row(
      children: [
        const Icon(Icons.circle, size: 6),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: mono(10).copyWith(color: authInk)),
        ),
        Text(value, style: mono(10)),
      ],
    ),
  );
}
