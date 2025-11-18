import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/personalization_controller.dart';

class ThemeCustomizationScreen extends StatelessWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final personalizationController = Get.find<PersonalizationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Customization'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              _showResetDialog(context, personalizationController);
            },
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.dark_mode,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Switch between light and dark theme for comfortable viewing',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      return SwitchListTile(
                        value: personalizationController.isDarkMode.value,
                        onChanged: (value) {
                          personalizationController.toggleDarkMode(value);
                        },
                        title: Text(
                          personalizationController.isDarkMode.value
                              ? 'Dark Mode Enabled'
                              : 'Light Mode Enabled',
                        ),
                        subtitle: Text(
                          personalizationController.isDarkMode.value
                              ? 'Easier on the eyes in low light'
                              : 'Bright and clear display',
                        ),
                        secondary: Icon(
                          personalizationController.isDarkMode.value
                              ? Icons.nightlight_round
                              : Icons.wb_sunny,
                          color: personalizationController.isDarkMode.value
                              ? Colors.amber
                              : Colors.orange,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Color Palette Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Primary Color',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose your favorite color to personalize the app',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Current Color Display
                    Obx(() {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              personalizationController.primaryColor,
                              personalizationController.primaryColor
                                  .withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: personalizationController.primaryColor
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Current: ${personalizationController.currentColorName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Color Palette Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1,
                          ),
                      itemCount: personalizationController.colorPalette.length,
                      itemBuilder: (context, index) {
                        return Obx(() {
                          final isSelected =
                              personalizationController
                                  .selectedColorIndex
                                  .value ==
                              index;
                          final color =
                              personalizationController.colorPalette[index];

                          return InkWell(
                            onTap: () {
                              personalizationController.changeColor(index);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: isSelected ? 12 : 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 32,
                                    )
                                  : null,
                            ),
                          );
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Color Names
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: personalizationController.colorNames
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final name = entry.value;

                            return Obx(() {
                              final isSelected =
                                  personalizationController
                                      .selectedColorIndex
                                      .value ==
                                  index;

                              return InkWell(
                                onTap: () {
                                  personalizationController.changeColor(index);
                                },
                                child: Chip(
                                  label: Text(name),
                                  backgroundColor: isSelected
                                      ? personalizationController
                                            .colorPalette[index]
                                      : null,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : null,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  avatar: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                      : null,
                                ),
                              );
                            });
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Font Family Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.font_download,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Font Family',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select your preferred font style for the entire app',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Font Dropdown
                    Obx(() {
                      final selectedIndex =
                          personalizationController.selectedFontIndex.value;
                      final selectedFontValue = personalizationController
                          .fontFamilyValues[selectedIndex];

                      // Get TextStyle based on font
                      TextStyle? getFontStyle(
                        String fontValue, {
                        double? fontSize,
                        FontWeight? fontWeight,
                        Color? color,
                      }) {
                        if (fontValue.isEmpty) {
                          return TextStyle(
                            fontSize: fontSize,
                            fontWeight: fontWeight,
                            color: color,
                          );
                        }

                        switch (fontValue) {
                          case 'Roboto':
                            return GoogleFonts.roboto(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: color,
                            );
                          case 'Poppins':
                            return GoogleFonts.poppins(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: color,
                            );
                          case 'Lato':
                            return GoogleFonts.lato(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: color,
                            );
                          case 'Montserrat':
                            return GoogleFonts.montserrat(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: color,
                            );
                          case 'OpenSans':
                            return GoogleFonts.openSans(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: color,
                            );
                          case 'NotoSans':
                            return GoogleFonts.notoSans(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: color,
                            );
                          case 'Ubuntu':
                            return GoogleFonts.ubuntu(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: color,
                            );
                          default:
                            return TextStyle(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: color,
                            );
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<int>(
                              value: selectedIndex,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              style: getFontStyle(
                                selectedFontValue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              items: List.generate(
                                personalizationController.fontFamilies.length,
                                (index) {
                                  final fontName = personalizationController
                                      .fontFamilies[index];
                                  final fontValue = personalizationController
                                      .fontFamilyValues[index];

                                  return DropdownMenuItem<int>(
                                    value: index,
                                    child: Text(
                                      fontName,
                                      style: getFontStyle(fontValue),
                                    ),
                                  );
                                },
                              ),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  personalizationController.changeFont(
                                    newValue,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Font Preview
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preview',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'The quick brown fox jumps over the lazy dog',
                                  style: getFontStyle(
                                    selectedFontValue,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                                  style: getFontStyle(
                                    selectedFontValue,
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'abcdefghijklmnopqrstuvwxyz',
                                  style: getFontStyle(
                                    selectedFontValue,
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '0123456789',
                                  style: getFontStyle(
                                    selectedFontValue,
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Language Selection Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose your preferred language',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Language Options
                    Obx(() {
                      return Column(
                        children: [
                          RadioListTile<String>(
                            value: 'en',
                            groupValue: personalizationController
                                .selectedLanguage
                                .value,
                            onChanged: (value) {
                              if (value != null) {
                                personalizationController.changeLanguage(value);
                              }
                            },
                            title: const Row(
                              children: [
                                Text('🇺🇸', style: TextStyle(fontSize: 24)),
                                SizedBox(width: 12),
                                Text('English'),
                              ],
                            ),
                            subtitle: const Text('English (United States)'),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            value: 'bn',
                            groupValue: personalizationController
                                .selectedLanguage
                                .value,
                            onChanged: (value) {
                              if (value != null) {
                                personalizationController.changeLanguage(value);
                              }
                            },
                            title: const Row(
                              children: [
                                Text('🇧🇩', style: TextStyle(fontSize: 24)),
                                SizedBox(width: 12),
                                Text('বাংলা'),
                              ],
                            ),
                            subtitle: const Text('Bangla (Bangladesh)'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Preview Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.preview,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'See how your theme looks',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sample UI Elements
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Sample Button'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.star),
                      label: const Text('Outlined Button'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Text Button'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(
    BuildContext context,
    PersonalizationController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Theme'),
        content: const Text(
          'Are you sure you want to reset all theme settings to default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.resetToDefaults();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
