import 'package:able_lints/src/mirror_missing_distinct.dart';
import 'package:able_lints/src/mirror_missing_take_once_false.dart';
import 'package:able_lints/src/then_without_rebuild.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

/// Entry point the analysis server looks for.
final plugin = AbleLintsPlugin();

class AbleLintsPlugin extends Plugin {
  @override
  String get name => 'able_lints';

  @override
  void register(PluginRegistry registry) {
    // Warning rules are on by default; each can be turned off in
    // analysis_options.yaml.
    registry.registerWarningRule(ThenWithoutRebuild());
    registry.registerWarningRule(MirrorMissingTakeOnceFalse());
    registry.registerWarningRule(MirrorMissingDistinct());
  }
}
