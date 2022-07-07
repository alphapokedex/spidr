import 'package:flutter/material.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/services/fileUpload.dart';
import 'package:spidr_app/views/mediaPreview.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/profilePageWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

class BannerScreen extends StatefulWidget {
  final int index;
  final String userId;
  final Function editTag;
  final Function delTag;
  final Function editAboutMe;
  final formKey;
  final TextEditingController quoteController;
  final TextEditingController tagController;

  const BannerScreen(
      {this.index,
      this.userId,
      this.editTag,
      this.delTag,
      this.editAboutMe,
      this.formKey,
      this.quoteController,
      this.tagController});

  @override
  _BannerScreenState createState() => _BannerScreenState();
}

class _BannerScreenState extends State<BannerScreen> {
  PageController pageController;
  bool uploading = false;

  uploadBanner(String imgUrl) {
    DatabaseMethods(uid: Constants.myUserId).uploadUserBanner(imgUrl);
  }

  removeBanner(String imgUrl) {
    DatabaseMethods(uid: Constants.myUserId).removeUserBanner(imgUrl);
  }

  @override
  void initState() {
    pageController = PageController(initialPage: widget.index ?? 0);
    super.initState();
  }

  Widget bannerUploadDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        !uploading
            ? IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
                iconSize: 72,
                onPressed: () async {
                  setState(() {
                    uploading = true;
                  });

                  String imgUrl = await UploadMethods()
                      .pickAndUploadMedia('USER_BANNER', false);

                  setState(() {
                    uploading = false;
                  });

                  if (imgUrl != null) {
                    uploadBanner(imgUrl);
                  }
                },
              )
            : sectionLoadingIndicator(),
        const SizedBox(
          height: 10,
        ),
        const Text(
          'Upload Media',
          style: TextStyle(
            fontSize: 22.5,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const BackButton(
          color: Colors.white,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      body: StreamBuilder(
          stream:
              DatabaseMethods().userCollection.doc(widget.userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data.data() != null) {
              String quote = snapshot.data.data()['quote'];
              List tags = snapshot.data.data()['tags'];
              List banner = snapshot.data.data()['banner'];
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                      controller: pageController,
                      itemCount: widget.formKey != null
                          ? banner == null || banner.isEmpty
                              ? 1
                              : banner.length + 1
                          : banner.length,
                      itemBuilder: (context, index) {
                        int banLength = banner == null || banner.isEmpty
                            ? 0
                            : banner.length;
                        if (index < banLength) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              ImageUrlPreview(
                                fullScreen: true,
                                fileURL: banner[index],
                                heroTag: banner[index],
                              ),
                              widget.delTag != null
                                  ? Container(
                                      margin: EdgeInsets.only(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.1),
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(50)),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              blurRadius: 18),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.cancel_rounded,
                                            color: Colors.white54),
                                        iconSize: 45,
                                        onPressed: () {
                                          removeBanner(banner[index]);
                                        },
                                      ),
                                    )
                                  : const SizedBox.shrink()
                            ],
                          );
                        } else {
                          return bannerUploadDisplay();
                        }
                      }),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.3,
                    width: MediaQuery.of(context).size.width,
                    decoration: mediaViewDec(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 22.5, bottom: 13.5, right: 4.5),
                          child: Row(
                            children: [
                              SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.875,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    widget.editAboutMe != null
                                        ? quote.isEmpty
                                            ? GestureDetector(
                                                onTap: () {
                                                  showTextBoxDialog(
                                                      context: context,
                                                      text: 'About Me',
                                                      textEditingController:
                                                          widget
                                                              .quoteController,
                                                      errorText:
                                                          'Sorry, about me can not be empty',
                                                      editQuote:
                                                          widget.editAboutMe,
                                                      formKey: widget.formKey);
                                                },
                                                child: infoEditBtt(
                                                    context: context,
                                                    text: 'About Me ',
                                                    bgColor: Colors.white,
                                                    fgColor: Colors.black),
                                              )
                                            : Container(
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      infoText(
                                                          text: quote,
                                                          fontSize: 16,
                                                          textColor:
                                                              Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      const SizedBox(
                                                        width: 5,
                                                      ),
                                                      GestureDetector(
                                                          onTap: () {
                                                            showTextBoxDialog(
                                                                context:
                                                                    context,
                                                                text:
                                                                    'About Me',
                                                                textEditingController:
                                                                    widget
                                                                        .quoteController,
                                                                errorText:
                                                                    'Sorry, about me can not be empty',
                                                                editQuote: widget
                                                                    .editAboutMe,
                                                                formKey: widget
                                                                    .formKey);
                                                          },
                                                          child: infoEditIcon())
                                                    ]),
                                              )
                                        : Container(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                infoText(
                                                    text: quote,
                                                    fontSize: 16,
                                                    textColor: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ],
                                            ),
                                          ),
                                    const SizedBox(
                                      height: 9,
                                    ),
                                    widget.delTag != null &&
                                            widget.editTag != null
                                        ? SizedBox(
                                            height: 45,
                                            child: ProfileTagList(
                                              editable: true,
                                              tagController:
                                                  widget.tagController,
                                              tags: tags,
                                              editTag: widget.editTag,
                                              delTag: widget.delTag,
                                              formKey: widget.formKey,
                                              tagNum: tags.length <
                                                      Constants.maxTags
                                                  ? tags.length + 1
                                                  : Constants.maxTags,
                                              boxColor: Colors.white54,
                                              outlineColor: Colors.white,
                                            ))
                                        : tags.isNotEmpty
                                            ? SizedBox(
                                                height: 45,
                                                child: ProfileTagList(
                                                  editable: false,
                                                  tags: tags,
                                                  tagNum: tags.length,
                                                  boxColor: Colors.white54,
                                                  outlineColor: Colors.white,
                                                ))
                                            : const SizedBox.shrink(),
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              );
            } else {
              return screenLoadingIndicator(context);
            }
          }),
    );
  }
}

// class AboutMe extends StatefulWidget {
//   AboutMe();
//
//   @override
//   _AboutMe createState() => _AboutMe();
// }
//
// class _AboutMe extends State<AboutMe> {
//   String quote = Constants.myQuote;
//   final formKey = GlobalKey<FormState>();
//   TextEditingController quoteController;
//
//   @override
//   void initState() {
//
//     super.initState();
//     quoteController = TextEditingController(text: Constants.myQuote);
//   }
//
//   editAboutMe(String newQuote) {
//     if (formKey.currentState.validate()) {
//       setState(() {
//         quote = quoteController.text;
//       });
//       DatabaseMethods(uid: Constants.myUserId).editUserQuote(newQuote);
//       Navigator.of(context, rootNavigator: true).pop();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: Text("About Me"),
//         ),
//         body: Stack(children: [
//           Container(
//               height: MediaQuery.of(context).size.height,
//               width: MediaQuery.of(context).size.width,
//               child: FittedBox(
//                   //background picture
//                   fit: BoxFit.contain,
//                   child: Center(
//                     child: Image(
//                       image: NetworkImage(
//                           'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'),
//                     ),
//                     // avatarImg(profileImg,MediaQuery.of(context).size.height)
//                   )
//               )
//           ),
//           Positioned.fill(
//             child: Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.orange.withOpacity(0.5),
//                       borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(20),
//                           topRight: Radius.circular(20),
//                           bottomLeft: Radius.circular(20),
//                           bottomRight: Radius.circular(20)),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.5),
//                           spreadRadius: 3,
//                           blurRadius: 2,
//                           offset: Offset(0, 3), // changes position of shadow
//                         ),
//                       ],
//                     ),
//                     height: 150,
//                     width: 350,
//                     margin: EdgeInsets.only(bottom: 40),
//                     child: Column(
//                       //Tags
//                         children: [
//                           Spacer(),
//                           Container(
//                               alignment: Alignment.topLeft,
//                               padding: EdgeInsets.only(left: 10),
//                               width: MediaQuery.of(context).size.width * 0.85,
//                               child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     SizedBox(
//                                       height: 10,
//                                     ),
//                                     Text(
//                                       Constants.myName,
//                                       style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.black),
//                                     ),
//                                     SizedBox(
//                                       height: 5,
//                                     ),
//                                     Text(
//                                       Constants.myEmail,
//                                       style: TextStyle(color: Colors.black),
//                                     ),
//                                     SizedBox(
//                                       height: 10,
//                                     ),
//                                   ])),
//                           SizedBox(height:20),
//                           //About me button
//                           aboutPopout(),
//                           Spacer()
//                         ])),
//             ),
//           ),
//         ])
//     );
//   }
//
//   //About me button
//   Widget aboutPopout (){
//     return
//       quote.isEmpty ? GestureDetector(
//         onTap: () {
//           showTextBoxDialog(
//               context: context,
//               text: "About Me",
//               textEditingController: quoteController,
//               errorText: "Sorry, about me can not be empty",
//               editQuote: editAboutMe,
//               formKey: formKey);
//         },
//         child: infoEditBtt(context, "About Me "),
//       ) : Container(
//         padding: EdgeInsets.symmetric(horizontal: 20),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             infoText(quote),
//             GestureDetector(
//                 onTap: () {
//                   showTextBoxDialog(
//                       context: context,
//                       text: "About Me",
//                       textEditingController:
//                       quoteController,
//                       errorText:
//                       "Sorry, about me can not be empty",
//                       editQuote: editAboutMe,
//                       formKey: formKey
//                   );
//                 },
//                 child: infoEditIcon()
//             )
//           ],
//         ),
//       );
//   }
// }
