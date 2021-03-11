import 'dart:convert';

import 'package:editor/constants.dart';
import 'package:editor/runtime_toolbar.dart';
import 'package:editor/widgets/toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class EditorToolbar extends StatefulWidget {
  final Layout layout;
  final Function(String) onSnippet;

  const EditorToolbar({Key key, this.layout, this.onSnippet}) : super(key: key);

  @override
  _EditorToolbarState createState() => _EditorToolbarState();
}

class _EditorToolbarState extends State<EditorToolbar> {
  String snippetFname; // Default file
  List<String> snippetList;
  final pathMap = <String, String>{};

  @override
  void initState() {
    super.initState();
    loadManifest();
  }

  Future loadManifest() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final manifestMap = json.decode(manifestContent);
    snippetList = manifestMap.keys
        .where((String key) => key.contains('snippets/'))
        .toList();
    pathMap.clear();
    snippetList.forEach((el) {
      pathMap[fname(el)] = el;
    });
    // Set first snippet
    await setSnippet("fibonacci");  // Default file
  }

  Future setSnippet(String fname) async {
    setState(() => snippetFname = fname);
    final source = await rootBundle.loadString(pathMap[snippetFname]);
    widget.onSnippet(source);
  }

  String fname(String path) {
    final split = path.split("/");
    return split.last.replaceAll("_", " ").replaceAll(".lox", "");
  }

  Widget buildDropdown() {
    final dropdown = DropdownButton<String>(
      value: snippetFname,
      items: pathMap.keys.map((String value) {
        return new DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
        );
      }).toList(),
      onChanged: setSnippet,
      iconEnabledColor: Colors.white,
      dropdownColor: Colors.black87,
      underline: SizedBox.shrink(),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: dropdown,
    );
  }

  Future _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final github = IconButton(
      padding: EdgeInsets.only(left: 8.0),
      icon: Icon(FontAwesome5Brands.github, color: Colors.white),
      onPressed: () =>
          _launchInBrowser("https://github.com/BertrandBev/dlox"),
    );

    final snippets = buildDropdown();

    final toggleBtn = ToggleButton(
      leftIcon: MaterialCommunityIcons.code_tags,
      leftEnabled: widget.layout.showEditor,
      leftToggle: widget.layout.toggleEditor,
      rightIcon: MaterialCommunityIcons.matrix,
      rightEnabled: widget.layout.showCompiler,
      rightToggle: widget.layout.toggleCompiler,
    );

    final row = Row(
      children: [
        github,
        snippets,
        Spacer(),
        toggleBtn,
      ],
    );
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: Colors.grey.shade700, width: 0.5),
        ),
        color: ColorTheme.sidebar,
      ),
      child: row,
    );
  }
}
