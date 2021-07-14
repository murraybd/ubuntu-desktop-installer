import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:keyboard_info/keyboard_info.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:subiquity_client/subiquity_client.dart';

import '../../keyboard_model.dart';
import '../../routes.dart';
import '../../widgets.dart';
import '../wizard_page.dart';
import 'keyboard_layout_model.dart';

class KeyboardLayoutPage extends StatefulWidget {
  const KeyboardLayoutPage({
    Key? key,
  }) : super(key: key);

  static Widget create(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KeyboardLayoutModel(
        client: Provider.of<SubiquityClient>(context, listen: false),
        keyboardModel: Provider.of<KeyboardModel>(context, listen: false),
      ),
      child: KeyboardLayoutPage(),
    );
  }

  @override
  _KeyboardLayoutPageState createState() => _KeyboardLayoutPageState();
}

class _KeyboardLayoutPageState extends State<KeyboardLayoutPage> {
  final _layoutListScrollController = AutoScrollController();
  final _keyboardVariantListScrollController = AutoScrollController();

  @override
  void initState() {
    super.initState();

    final model = Provider.of<KeyboardLayoutModel>(context, listen: false);
    getKeyboardInfo().then((info) {
      var keyboardModel = Provider.of<KeyboardModel>(context, listen: false);
      setState(() {
        model.selectedLayoutIndex = keyboardModel.layouts.indexWhere((layout) {
          return layout.code == info.layout;
        });
        if (model.selectedLayoutIndex > -1) {
          model.selectedVariantIndex = model.selectedLayout!.variants
                  ?.indexWhere(
                      (variant) => variant.code == (info.variant ?? '')) ??
              -1;
          if (model.selectedVariantIndex > -1) {
            SchedulerBinding.instance!.addPostFrameCallback((_) =>
                _keyboardVariantListScrollController.scrollToIndex(
                    model.selectedVariantIndex,
                    preferPosition: AutoScrollPosition.middle,
                    duration: const Duration(milliseconds: 1)));
          }
        }
        if (model.selectedLayoutIndex > -1) {
          SchedulerBinding.instance!.addPostFrameCallback((_) =>
              _layoutListScrollController.scrollToIndex(
                  model.selectedLayoutIndex,
                  preferPosition: AutoScrollPosition.middle,
                  duration: const Duration(milliseconds: 1)));
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _layoutListScrollController.dispose();
    _keyboardVariantListScrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<KeyboardLayoutModel>(context);
    return Consumer<KeyboardModel>(builder: (context, keyboardModel, child) {
      return LocalizedView(
        builder: (context, lang) => WizardPage(
          title: Text(lang.keyboardLayoutPageTitle),
          header: Text(lang.chooseYourKeyboardLayout),
          content: Column(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RoundedListView.builder(
                        controller: _layoutListScrollController,
                        itemCount: keyboardModel.layouts.length,
                        itemBuilder: (context, index) {
                          return AutoScrollTag(
                            index: index,
                            key: ValueKey(index),
                            controller: _layoutListScrollController,
                            child: ListTile(
                              title: Text(keyboardModel.layouts[index].name!),
                              selected: index == model.selectedLayoutIndex,
                              onTap: () => model.selectLayout(index),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: RoundedListView.builder(
                        controller: _keyboardVariantListScrollController,
                        itemCount: model.selectedLayout != null
                            ? model.selectedLayout!.variants!.length
                            : 0,
                        itemBuilder: (context, index) {
                          return AutoScrollTag(
                            index: index,
                            key: ValueKey(index),
                            controller: _keyboardVariantListScrollController,
                            child: ListTile(
                              title: Text(
                                  model.selectedLayout!.variants![index].name!),
                              selected: index == model.selectedVariantIndex,
                              onTap: () => model.selectVariant(index),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: lang.typeToTest,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  child: Text(lang.detectLayout),
                  onPressed: () {
                    print('TODO: show dialog to detect keyboard layout');
                  },
                ),
              ),
            ],
          ),
          actions: <WizardAction>[
            WizardAction(
              label: lang.backButtonText,
              onActivated: Navigator.of(context).pop,
            ),
            WizardAction(
              label: lang.continueButtonText,
              enabled: (model.selectedLayoutIndex > -1) &&
                  (model.selectedVariantIndex > -1),
              onActivated: () async {
                await model.applyKeyboardSettings();
                Navigator.pushNamed(context, Routes.updatesOtherSoftware);
              },
            ),
          ],
        ),
      );
    });
  }
}
