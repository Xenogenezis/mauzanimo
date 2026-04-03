import 'package:flutter/material.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contact Support')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(Icons.support_agent_outlined, size: 80, color: Colors.purple)),
          const SizedBox(height: 16),
          Center(child: Text('We are here to help',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
          const SizedBox(height: 8),
          Center(child: Text('Reach out to us through any of the chann',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.6)))),
          const SizedBox(height: 32),
          _ContactTile(icon: Icons.email_outlined, color: AppTheme.primary,
            title: 'Email Us', subtitle: 'mauzanimo@jcigrandbaie.mu'),
          const SizedBox(height: 12),
          _ContactTile(icon: Icons.phone_outlined, color: Colors.green,
            title: 'Call Us', subtitle: '+230 XXXX XXXX'),
          const SizedBox(height: 12),
          _ContactTile(icon: Icons.chat_outlined, color: Colors.blue,
            title: 'WhatsApp', subtitle: '+230 XXXX XXXX'),
          const SizedBox(height: 12),
          _ContactTile(icon: Icons.location_on_outlined, color: Colors.orange,
            title: 'Find Us', subtitle: 'Grand Baie, Mauritius'),
          const SizedBox(height: 32),
          Text('Business hours',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(12)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Monday friday 900 am 500 pm', style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
              SizedBox(height: 6),
              Text('Saturday 900 am 1200 pm', style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
              SizedBox(height: 6),
              Text('Sunday closed', style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
            ]),
          ),
        ],
      )),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon; final Color color; final String title, subtitle;
  const _ContactTile({required this.icon, required this.color, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
    ]),
  );
}