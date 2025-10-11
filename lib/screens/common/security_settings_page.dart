import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';


class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool _biometricEnabled = false;
  bool _loading = true;
  bool _biometricAvailable = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadSecuritySettings();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _biometricAvailable = isAvailable && isDeviceSupported;
      });
    } catch (e) {
      setState(() => _biometricAvailable = false);
    }
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _biometricEnabled = data['biometricEnabled'] ?? false;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }



  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      try {
        final isAuthenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric login',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        
        if (isAuthenticated) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({'biometricEnabled': true});
          
          setState(() => _biometricEnabled = true);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric authentication enabled')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'biometricEnabled': false});
      
      setState(() => _biometricEnabled = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication disabled')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textDark,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_biometricAvailable)
                          ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.fingerprint,
                                color: _primary,
                              ),
                            ),
                            title: const Text(
                              'Biometric Authentication',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                            subtitle: Text(
                              _biometricEnabled 
                                  ? 'Enabled - Use fingerprint/face ID to login'
                                  : 'Disabled - Quick login with biometrics',
                              style: TextStyle(
                                color: _textDark.withOpacity(0.7),
                              ),
                            ),
                            trailing: Switch(
                              value: _biometricEnabled,
                              onChanged: _toggleBiometric,
                              activeColor: _primary,
                            ),
                          ),

                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: _primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'About Authentication Methods',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Biometric login uses fingerprint or face ID\n'
                          '• Adds an extra layer of security to your account\n'
                          '• Protects against unauthorized access',
                          style: TextStyle(
                            color: _textDark.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
    );
  }
}