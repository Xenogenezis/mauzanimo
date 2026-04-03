const fs = require('fs');
let content = fs.readFileSync('lib/screens/auth/login_screen.dart', 'utf8');

content = content.replace(
  "              const SizedBox(height: 24),",
  "              const SizedBox(height: 8),\n              Align(\n                alignment: Alignment.centerRight,\n                child: GestureDetector(\n                  onTap: () => _forgotPassword(context),\n                  child: const Text('Forgot Password?',\n                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500, fontSize: 13)),\n                ),\n              ),\n              const SizedBox(height: 16),"
);

content = content.replace(
  "  Future<void> _login() async {",
  "  Future<void> _forgotPassword(BuildContext context) async {\n    if (_emailController.text.isEmpty) {\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(content: Text('Please enter your email address first')));\n      return;\n    }\n    try {\n      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());\n      if (!context.mounted) return;\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(content: Text('Password reset email sent. Check your inbox!')));\n    } on FirebaseAuthException catch (e) {\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(content: Text(e.message ?? 'Something went wrong')));\n    }\n  }\n\n  Future<void> _login() async {"
);

fs.writeFileSync('lib/screens/auth/login_screen.dart', content);
console.log('Done!');
