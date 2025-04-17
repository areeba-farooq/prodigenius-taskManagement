import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskgenius/state/theme_provider.dart';

class ThemeSwitch extends StatelessWidget {
  final bool showLabel;
  
  const ThemeSwitch({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            isDarkMode ? 'Dark Mode' : 'Light Mode',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 12),
        ],
        GestureDetector(
          onTap: () {
            themeProvider.toggleTheme();
          },
          child: Container(
            width: 50,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDarkMode 
                ? const Color(0xFF3E3E3E) 
                : Colors.grey.shade300,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  left: isDarkMode ? 22 : 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode 
                        ? Colors.blue
                        : Colors.white,
                    ),
                    child: Center(
                      child: Icon(
                        isDarkMode 
                          ? Icons.dark_mode 
                          : Icons.light_mode,
                        size: 16,
                        color: isDarkMode 
                          ? Colors.white 
                          : Colors.amber,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}