import 'package:flutter/material.dart';

class DynamicStackItem extends StatefulWidget {
  final String gifUrl;

  DynamicStackItem(this.gifUrl);
  double xPos = 100;
  double yPos = 150;
  double scale = 3.75;
  bool deleted = false;

  @override
  _DynamicStackItemState createState() => _DynamicStackItemState();
}

class _DynamicStackItemState extends State<DynamicStackItem> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.yPos,
      left: widget.xPos,
      child: GestureDetector(
          onPanUpdate: (tapInfo) {
            setState(() {
              widget.xPos += tapInfo.delta.dx;
              widget.yPos += tapInfo.delta.dy;
            });
          },
          child: !widget.deleted
              ? Column(
                  children: [
                    Stack(
                      children: [
                        Transform.scale(
                          scale: widget.scale,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/icon/sm_giphy.png',
                              image: widget.gifUrl,
                              imageScale: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: 100,
                      child: Slider(
                        min: 2.5,
                        max: 7.5,
                        value: widget.scale,
                        activeColor: Colors.orange,
                        inactiveColor: Colors.black54,
                        onChanged: (newScale) {
                          setState(() {
                            widget.scale = newScale;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          widget.deleted = true;
                        });
                      },
                    ),
                  ],
                )
              : const SizedBox.shrink()),
    );
  }
}
