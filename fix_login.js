const fs = require('fs');
let content = fs.readFileSync('lib/screens/auth/login_screen.dart', 'utf8');

content = content.replace(
  "import 'package:stray_pets_mu/screens/admin/admin_dashboard.dart';",
  "import 'package:stray_pets_mu/screens/admin/admin_dashboard.dart';\nimport 'package:stray_pets_mu/screens/auth/register_screen.dart';"
);

content = content.replace(
  "              ),\n            ],\n          ),\n        ),\n      ),\n    );\n  }\n}",
  "              ),\n              const SizedBox(height: 16),\n              Center(\n                child: GestureDetector(\n                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),\n                  child: RichText(text: TextSpan(\n                    text: 'Don\\'t have an account? ',\n                    style: TextStyle(color: AppTheme.textDark.withOpacity(0.6)),\n                    children: const [TextSpan(text: 'Sign Up',\n                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))],\n                  )),\n                ),\n              ),\n            ],\n          ),\n        ),\n      ),\n    );\n  }\n}"
);

fs.writeFileSync('lib/screens/auth/login_screen.dart', content);
console.log('Done!');
