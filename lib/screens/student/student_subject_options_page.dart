import 'package:flutter/material.dart';
import 'package:unified_campus/screens/student/student_queries_page.dart';
import 'package:unified_campus/screens/student/student_submissions_page.dart';

class StudentSubjectOptionsPage extends StatelessWidget {
  final String subject;
  final String department;
  final String year;

  const StudentSubjectOptionsPage({
    super.key,
    required this.subject,
    required this.department,
    required this.year,
  });

  // Dark theme constants
  static const Color _primary = Color(0xFF00D4AA);
  static const Color _primaryDark = Color(0xFF00B894);
  static const Color _background = Color(0xFF0A0A0A);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _surfaceVariant = Color(0xFF2A2A2A);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFB0B0B0);
  static const Color _textTertiary = Color(0xFF808080);
  static const Color _accentBlue = Color(0xFF4A90E2);
  static const Color _accentPurple = Color(0xFF9B59B6);
  static const Color _accentOrange = Color(0xFFE67E22);
  static const Color _accentGreen = Color(0xFF27AE60);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                fontSize: 20,
              ),
            ),
            Text(
              '$year • $department',
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary, _primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Choose an option",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              "What would you like to do?",
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Options Section
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Available Options',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Assignments & Practicals Option
            _OptionCard(
              title: "Assignments & Practicals",
              subtitle:
                  "View and submit your assignments, practicals, and projects",
              icon: Icons.assignment_rounded,
              color: _accentBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentSubmissionsPage(
                      subject: subject,
                      department: department,
                      year: year,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Queries Option
            _OptionCard(
              title: "Ask Questions",
              subtitle: "Post queries and view answers from professors",
              icon: Icons.help_outline_rounded,
              color: _accentOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentQueriesPage(
                      subject: subject,
                      department: department,
                      year: year,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget for option cards
class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFB0B0B0),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
