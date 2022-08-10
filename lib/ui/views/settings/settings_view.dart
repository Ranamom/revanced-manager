import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:revanced_manager/ui/views/settings/settings_viewmodel.dart';
import 'package:stacked/stacked.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SettingsViewModel>.reactive(
      viewModelBuilder: () => SettingsViewModel(),
      builder: (context, SettingsViewModel model, child) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: <Widget>[
                I18nText(
                  'settingsView.widgetTitle',
                  child: Text(
                    '',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                ),
                ListTile(
                  title: I18nText('settingsView.themeLabel'),
                  subtitle: I18nText('settingsView.themeHint'),
                  trailing: Switch(
                    value: model.isDarkMode,
                    onChanged: (value) {
                      model.toggleTheme();
                    },
                  ),
                  onTap: () {
                    model.toggleTheme;
                  },
                ),
                ListTile(
                  title: I18nText('settingsView.dynamicColorsLabel'),
                  subtitle: I18nText('settingsView.dynamicColorsHint'),
                  trailing: Switch(
                    value: model.isDynamicColors,
                    onChanged: (value) {
                      model.toggleDynamicColors();
                    },
                  ),
                  onTap: () {
                    model.toggleDynamicColors();
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      I18nText(
                        'settingsView.languageLabel',
                        child: const Text(
                          '',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      DropdownButton(
                        value: 'en',
                        items: const [
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: 'fr',
                            child: Text('French'),
                          ),
                        ],
                        onChanged: (value) {
                          value = value;
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: I18nText('settingsView.aboutLabel'),
                ),
                ListTile(
                  title: I18nText('settingsView.contributorsLabel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
