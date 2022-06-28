import 'package:flutter/material.dart';

class StaticStackItem extends StatelessWidget {
  final String gifUrl;
  final double xPos;
  final double yPos;
  final double scale;

  const StaticStackItem(this.gifUrl, this.xPos, this.yPos, this.scale);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: yPos,
      left: xPos,
      child: Column(
        children: [
          Stack(
            children: [
              Transform.scale(
                scale: scale ?? 2.5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: FadeInImage.assetNetwork(
                    placeholder: "assets/icon/sm_giphy.png",
                    image: gifUrl,
                    imageScale: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
