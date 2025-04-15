import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:taskgenius/screens/splash_screen.dart';
import 'package:taskgenius/services/notification_service.dart';
import 'package:taskgenius/state/auth_provider.dart';
import 'package:taskgenius/state/task_provider.dart';
import 'package:taskgenius/utils/theme_switch.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _enableReminders = true;
  bool _enableDeadlineAlerts = true;
  bool _enableDailyDigest = true;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableReminders = prefs.getBool('enable_reminders') ?? true;
      _enableDeadlineAlerts = prefs.getBool('enable_deadline_alerts') ?? true;
      _enableDailyDigest = prefs.getBool('enable_daily_digest') ?? true;
    });
  }

  // Call this in initState
  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  void _showNotificationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Notification Settings'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Task Reminders'),
                      subtitle: const Text('Get notified before tasks are due'),
                      value: _enableReminders,
                      onChanged: (value) async {
                        setState(() {
                          _enableReminders = value;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('enable_reminders', value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Deadline Alerts'),
                      subtitle: const Text('Get notified when tasks are due'),
                      value: _enableDeadlineAlerts,
                      onChanged: (value) async {
                        setState(() {
                          _enableDeadlineAlerts = value;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('enable_deadline_alerts', value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Daily Task Digest'),
                      subtitle: const Text(
                        'Get a morning summary of your tasks',
                      ),
                      value: _enableDailyDigest,
                      onChanged: (value) async {
                        setState(() {
                          _enableDailyDigest = value;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('enable_daily_digest', value);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final user = authProvider.currentUser;

    // Calculate stats
    final totalTasks = taskProvider.tasks.length;
    final completedTasks =
        taskProvider.tasks.where((task) => task.isCompleted).length;
    final highPriorityTasks =
        taskProvider.tasks
            .where((task) => task.priority == 'High' && !task.isCompleted)
            .length;

    // Calculate completion percentage
    final completionPercentage =
        totalTasks > 0
            ? (completedTasks / totalTasks * 100).toStringAsFixed(1)
            : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, authProvider),
          ),
        ],
      ),
      body:
          user == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User profile card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // User avatar with update option
                            GestureDetector(
                              onTap:
                                  () => _showProfilePictureOptions(
                                    context,
                                    authProvider,
                                  ),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.2),
                                    backgroundImage:
                                        user.photoUrl != null
                                            ? NetworkImage(user.photoUrl!)
                                            : null,
                                    child:
                                        user.photoUrl == null
                                            ? Text(
                                              user.name
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 36,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                            : null,
                                  ),
                                  if (_isUploading)
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor,
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // User info
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Edit profile button
                            OutlinedButton.icon(
                              onPressed:
                                  () => _showEditProfileDialog(
                                    context,
                                    authProvider,
                                    user,
                                  ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit Profile'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Task statistics section
                    const Text(
                      'Task Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Completion rate card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Completion Rate',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 20,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value:
                                          totalTasks > 0
                                              ? completedTasks / totalTasks
                                              : 0,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getCompletionColor(
                                          double.parse(completionPercentage),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '$completionPercentage%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1.0, 1.0),
                                            blurRadius: 3.0,
                                            color: Color.fromARGB(100, 0, 0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Statistics cards
                    Row(
                      children: [
                        // Total tasks card
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.assignment,
                            Colors.blue,
                            totalTasks.toString(),
                            'Total Tasks',
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Completed tasks card
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.task_alt,
                            Colors.green,
                            completedTasks.toString(),
                            'Completed',
                          ),
                        ),
                        const SizedBox(width: 16),

                        // High priority tasks card
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.priority_high,
                            Colors.red,
                            highPriorityTasks.toString(),
                            'High Priority',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Settings section
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Settings cards
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSettingsItem(
                            context,
                            Icons.notifications_active,
                            'Test Notification',
                            'Send a test notification immediately',
                            () {
                              NotificationService.instance
                                  .showTestNotification();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test notification sent!'),
                                ),
                              );
                            },
                          ),
                          _buildSettingsItem(
                            context,
                            Icons.notifications,
                            'Notifications',
                            'Configure your notification preferences',
                            () {
                              _showNotificationSettingsDialog(context);
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsItem(
                            context,
                            Icons.color_lens,
                            'Appearance',
                            'Switch between light and dark theme',
                            () {},
                            trailing: const ThemeSwitch(showLabel: false),
                          ),
                          const Divider(height: 1),
                          _buildSettingsItem(
                            context,
                            Icons.lock,
                            'Change Password',
                            'Update your account password',
                            () => _showChangePasswordDialog(
                              context,
                              authProvider,
                            ),
                          ),
                          const Divider(height: 1),
                          _buildSettingsItem(
                            context,
                            Icons.help_outline,
                            'Help & Support',
                            'Get help with using Task Genius',
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Help & support coming soon!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmLogout(context, authProvider),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App version
                    const Center(
                      child: Text(
                        'Task Genius v1.0.0',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Show profile picture options
  void _showProfilePictureOptions(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateProfilePicture(
                    ImageSource.gallery,
                    authProvider,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateProfilePicture(ImageSource.camera, authProvider);
                },
              ),
              if (authProvider.currentUser?.photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove current photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() {
                      _isUploading = true;
                    });

                    // Remove profile picture
                    await authProvider.updateProfile(photoUrl: '');

                    setState(() {
                      _isUploading = false;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Update profile picture
  Future<void> _updateProfilePicture(
    ImageSource source,
    AuthProvider authProvider,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        // Upload to Firebase Storage
        final File imageFile = File(pickedFile.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${authProvider.currentUser!.id}.jpg');

        // Upload file
        final uploadTask = storageRef.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Get download URL after upload completes
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update user profile with new photo URL
        await authProvider.updateProfile(photoUrl: downloadUrl);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // Show edit profile dialog
  void _showEditProfileDialog(
    BuildContext context,
    AuthProvider authProvider,
    User user,
  ) {
    _nameController.text = user.name;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name cannot be empty')),
                  );
                  return;
                }

                Navigator.pop(context);

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) =>
                          const Center(child: CircularProgressIndicator()),
                );

                try {
                  // Update profile
                  final success = await authProvider.updateProfile(
                    name: _nameController.text.trim(),
                  );

                  // Close loading dialog
                  if (context.mounted) Navigator.pop(context);

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully'),
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to update profile: ${authProvider.error}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update profile: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Show change password dialog
  void _showChangePasswordDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    // Reset password controllers
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Validate passwords
                if (_currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Current password is required'),
                    ),
                  );
                  return;
                }

                if (_newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New password is required')),
                  );
                  return;
                }

                if (_newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'New password must be at least 6 characters',
                      ),
                    ),
                  );
                  return;
                }

                if (_newPasswordController.text !=
                    _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }

                Navigator.pop(context);

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) =>
                          const Center(child: CircularProgressIndicator()),
                );

                try {
                  // Change password
                  final success = await authProvider.changePassword(
                    _currentPasswordController.text,
                    _newPasswordController.text,
                  );

                  // Close loading dialog
                  if (context.mounted) Navigator.pop(context);

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to change password: ${authProvider.error}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to change password: $e')),
                    );
                  }
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  // Confirm logout dialog
  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await authProvider.logout();

                  // Navigate to splash screen
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const SplashScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // Helper method to build a statistic card
  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    Color color,
    String count,
    String label,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a settings item
  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      onTap: onTap,
    );
  }

  // Get color based on completion percentage
  Color _getCompletionColor(double percentage) {
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.red.shade400;
    }
  }
}
