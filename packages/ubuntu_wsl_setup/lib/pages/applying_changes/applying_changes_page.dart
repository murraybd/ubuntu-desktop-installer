import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subiquity_client/subiquity_client.dart';
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:ubuntu_wizard/constants.dart';
import 'package:ubuntu_wizard/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'applying_changes_model.dart';

/// WSL Advanced setup page.
///
/// See also:
/// * [AdvancedSetupModel]
class ApplyingChangesPage extends StatefulWidget {
  /// Use [create] instead.
  @visibleForTesting
  const ApplyingChangesPage({
    super.key,
  });

  /// Creates an instance with [AdvancedSetupModel].
  static Widget create(BuildContext context) {
    final monitor = getService<SubiquityStatusMonitor>();
    final client = getService<SubiquityClient>();
    return ChangeNotifierProvider(
      create: (_) => ApplyingChangesModel(client, monitor),
      child: const ApplyingChangesPage(),
    );
  }

  @override
  State<ApplyingChangesPage> createState() => _ApplyingChangesPageState();
}

class _ApplyingChangesPageState extends State<ApplyingChangesPage> {
  @override
  void initState() {
    super.initState();
    final model = Provider.of<ApplyingChangesModel>(context, listen: false);
    model.init(onDoneTransition: () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Wizard.of(context).hasNext) {
          Wizard.of(context).next();
        } else {
          model.reboot(immediate: false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);
    return WizardPage(
      title: Text(lang.setupCompleteTitle),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: kContentSpacing),
          Text(lang.applyingChanges),
          const SizedBox(height: kContentSpacing),
          Text(
            lang.applyingChangesDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
