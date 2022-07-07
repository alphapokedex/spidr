import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:giphy_get/giphy_get.dart';

BoxShadow circleShadow = BoxShadow(
    color: Colors.grey.withOpacity(0.5), blurRadius: 4.5, spreadRadius: 1.5);

hashTagFromDec(int tagLength, bool validHashTag) {
  return InputDecoration(
      hintText: 'Add a group name',
      labelText: 'Circle Name',
      icon: const Icon(Icons.tag, color: Colors.orange),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(
          color: Colors.black,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(
          color: Colors.orange,
          width: 2.0,
        ),
      ),
      suffix: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$tagLength/18',
            style: const TextStyle(fontSize: 14),
          ),
          Icon(
            validHashTag ? Icons.check_circle : Icons.cancel_rounded,
            color: validHashTag ? Colors.orange : Colors.red,
          ),
        ],
      ));
}

previewInputDec(
    {String hintText,
    bool valid,
    TextEditingController textEtController,
    int maxLength,
    icon,
    fillColor,
    fontColor,
    outlineColor,
    borderSide}) {
  return InputDecoration(
      icon: Icon(icon, color: outlineColor),
      filled: true,
      fillColor: fillColor,
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        // borderSide: BorderSide(color: outlineColor),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        // borderSide: BorderSide(color: outlineColor),
        borderSide: borderSide,
      ),
      hintText: hintText,
      hintStyle: TextStyle(
          fontSize: 14.0, color: fontColor, fontStyle: FontStyle.italic),
      suffix: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (maxLength == null) {
                String link = textEtController.text;
                String url = extractUrl(link);
                openUrl(url);
              }
            },
            child: Icon(
                valid
                    ? maxLength != null
                        ? Icons.check_circle
                        : Icons.open_in_new_rounded
                    : Icons.cancel_rounded,
                color: valid ? Colors.orange : Colors.red),
          ),
          Text(maxLength != null
              ? '${textEtController.text.length}/$maxLength'
              : '\u221e')
        ],
      ));
}

msgInputDec({
  BuildContext context,
  String hintText,
  String groupChatId,
  String personalChatId,
  bool friend,
  String contactId,
  bool disabled,
  bool gif = false,
  hintColor = Colors.black54,
  fillColor = Colors.white,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
        fontSize: 14.0, color: hintColor, fontStyle: FontStyle.italic),
    filled: true,
    fillColor: fillColor,
    suffixIcon: gif
        ? IconButton(
            icon: const Icon(Icons.gif),
            onPressed: disabled == null || !disabled
                ? () async {
                    GiphyGif gif = await GiphyGet.getGif(
                        context: context,
                        apiKey: Constants.giphyAPIKey,
                        tabColor: Colors.orange,
                        searchText: 'Search GIPHY');
                    if (gif != null) {
                      if (gif.images.original.webp != null) {
                        Map imgObj = {
                          'imgUrl': gif.images.original.webp,
                          'imgName': gif.title,
                          'gif': gif.isSticker == 0,
                          'sticker': gif.isSticker == 1
                        };
                        DateTime now = DateTime.now();

                        if (groupChatId != null) {
                          DatabaseMethods().addConversationMessages(
                            groupChatId: groupChatId,
                            message: '',
                            username: Constants.myName,
                            userId: Constants.myUserId,
                            time: now.microsecondsSinceEpoch,
                            imgObj: imgObj,
                          );
                        } else {
                          DatabaseMethods(uid: Constants.myUserId)
                              .addPersonalMessage(
                                  personalChatId: personalChatId,
                                  text: '',
                                  userName: Constants.myName,
                                  sendTime: now.microsecondsSinceEpoch,
                                  imgMap: imgObj,
                                  contactId: contactId,
                                  friend: friend);
                        }
                      } else {
                        Fluttertoast.showToast(
                            msg: 'Sorry, this gif is corrupted',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.SNACKBAR,
                            timeInSecForIosWeb: 3,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            fontSize: 14.0);
                      }
                    }
                  }
                : null,
          )
        : null,
    contentPadding:
        const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25.0),
      borderSide: const BorderSide(
        color: Colors.orange,
        width: 2.0,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25.0),
      borderSide: const BorderSide(
        color: Colors.orange,
      ),
    ),
  );
}

BoxDecoration shadowEffect(double radius) {
  return BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.5),
        blurRadius: 5,
        offset: const Offset(0, 3), // changes position of shadow
      ),
    ],
  );
}

BoxDecoration chatBubbleDec(bool isSendByMe, bool bubbleDisplay) {
  if (bubbleDisplay) {
    return BoxDecoration(
        gradient: LinearGradient(
          colors: isSendByMe
              ? [const Color(0xffff914d), const Color(0xffff914d)]
              : [
                  const Color(0xff000000),
                  const Color(0xff000000),
                ],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(30)));
  } else {
    return null;
  }
}

BoxDecoration mediaViewDec() {
  return BoxDecoration(
      gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.75), Colors.black.withOpacity(0)],
          end: Alignment.topCenter,
          begin: Alignment.bottomCenter));
}
