import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/widgets/widget.dart';

class AboutSpidrScreen extends StatelessWidget {
  const AboutSpidrScreen({Key key}) : super(key: key);

  launchSite(String url) {
    FlutterWebBrowser.openWebPage(
      url: url,
      customTabsOptions: const CustomTabsOptions(
        colorScheme: CustomTabsColorScheme.dark,
        defaultColorSchemeParams: CustomTabsColorSchemeParams(
          toolbarColor: Colors.orange,
          secondaryToolbarColor: Colors.orangeAccent,
          navigationBarColor: Colors.black,
        ),
        shareState: CustomTabsShareState.on,
        instantAppsEnabled: true,
        showTitle: true,
        urlBarHidingEnabled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Icon(Icons.info_rounded),
        elevation: 0.0,
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Image.asset(
                  'assets/icon/appIcon.png',
                  height: 91,
                  width: 91,
                  fit: BoxFit.contain,
                ),
                const Text('Spidr',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                const Text('Version 1.1.0',
                    style: TextStyle(color: Colors.black)),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(30)),
                            color: Colors.white,
                            boxShadow: [circleShadow]),
                        child: ListTile(
                            title: const Text('Terms and Conditions',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black)),
                            trailing: iconContainer(
                              icon: Icons.chevron_right_rounded,
                              contColor: Colors.black,
                              horPad: 5,
                              verPad: 5,
                            ),
                            onTap: () {
                              launchSite(
                                  'https://www.iubenda.com/terms-and-conditions/80156886');
                            }),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(30)),
                            color: Colors.white,
                            boxShadow: [circleShadow]),
                        child: ListTile(
                            title: const Text("What's New",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black)),
                            trailing: iconContainer(
                              icon: Icons.chevron_right_rounded,
                              contColor: Colors.black,
                              horPad: 5,
                              verPad: 5,
                            ),
                            onTap: () {
                              launchSite('https://www.spidrapp.com/');
                            }),
                      ),
                    ],
                  ),
                  Column(
                    children: const [
                      Text('Copyright \u00a9 2021-2031 Brane',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('All Rights Reserved',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
