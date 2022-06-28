import  'dart:io';
import  'dart:typed_data';

import  'package:esys_flutter_share/esys_flutter_share.dart';
import  'package:flutter/cupertino.dart';
import  'package:flutter/foundation.dart';



class ShareMethods{

  static shareFile({Map imgObj, Map fileObj, BuildContext context}) async{
    // final res = await http.get(imgObj["imgUrl"]);
    // if(res.statusCode == 404){
    //   showAlertDialog("You can not share an deleted image", context);
    // }else{
    String url = imgObj != null ? imgObj['imgUrl'] : fileObj['fileUrl'];
    String name = imgObj != null ? imgObj['imgName'] : fileObj['fileName'];


      var request = await HttpClient().getUrl(
          Uri.parse(url));
      var response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(
          response);
      await Share.file(
          'Share via', name, bytes, '*/*');
    //}

  }

}