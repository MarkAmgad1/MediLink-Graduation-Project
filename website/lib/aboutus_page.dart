import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key, required this.setLocale});
  final Function(Locale) setLocale;

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  final List<Map<String, String>> teamMembers = [
    {
      'name': 'Joycie Gerges',
      'role': 'UI/UX',
    }
    ,{
      'name': 'Mark Amgad George',
      'role': 'Mobile App Developer & System Coordinator',
    },
    {
      'name': 'Marwan Mahmoud',
      'role': 'ID Verification & AI',
    },
    {
      'name': 'Samir Saeed',
      'role': 'Survey Logic & AI',
    },
    {
      'name': 'Mohamed El Sayed Ayoub',
      'role': 'AI Integration',
    },
    {
      'name': 'Abdelghany Mohamed',
      'role': 'Website',
    },
  ];

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.aboutUs),
        backgroundColor: Color.fromRGBO(136, 151, 108, 1),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            localization.aboutTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localization.aboutDescription,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Text(
            localization.ourMission,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localization.ourMissionDesc,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Text(
            localization.teamMembers,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...teamMembers.map(
            (member) => Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(member['name']!),
                subtitle: Text(member['role']!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
