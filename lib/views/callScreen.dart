import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/globals.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/utils/agora_const.dart';
import 'package:spidr_app/widgets/widget.dart';

class CallScreen extends StatefulWidget {
  final String groupId;
  final String personalChatId;
  final bool anon;
  final ClientRole role;

  const CallScreen({
    Key key,
    this.groupId,
    this.personalChatId,
    this.anon,
    this.role,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  List activeUsers = [];
  List mutedUsers = [];
  String selUid;
  String loudUid;

  Map users = {};
  String myUid = '';
  bool muted = false;
  bool deafen = false;
  RtcEngine _engine;

  DocumentReference chatDofRef;

  @override
  void dispose() {
    // destroy sdk
    _engine.leaveChannel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    chatDofRef = widget.groupId != null
        ? DatabaseMethods().groupChatCollection.doc(widget.groupId)
        : DatabaseMethods().personalChatCollection.doc(widget.personalChatId);
    initialize();
  }

  Future<void> initialize() async {
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    // await _engine.enableWebSdkInteroperability(true);
    // VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    // configuration.dimensions = VideoDimensions(1920, 1080);
    // await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(
        AgoraConst.Token, widget.groupId ?? widget.personalChatId, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(AgoraConst.APP_ID);
    await _engine.enableAudioVolumeIndication(200, 3, false);
    // await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role);
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        debugPrint(code.name);
      },
      audioVolumeIndication:
          (List<AudioVolumeInfo> audInfoList, int totalVolume) {
        List tmp = [];
        for (AudioVolumeInfo audInfo in audInfoList) {
          if (audInfo.volume > 0) {
            String uid = audInfo.uid == 0 ? myUid : '${audInfo.uid}';
            tmp.add(uid);
          }
        }
        if (mounted) {
          setState(() {
            activeUsers = tmp;
          });
        }
      },
      userMuteAudio: (int uid, bool mute) {
        setState(() {
          if (mute) {
            mutedUsers.add('$uid');
          } else {
            mutedUsers.remove('$uid');
          }
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        Globals.inCall = true;
        myUid = '$uid';
        setState(() {
          selUid = myUid;
        });
        users[myUid] = {'userId': Constants.myUserId};
        chatDofRef.update({'inCallUsers': users});
      },
      leaveChannel: (stats) {
        Globals.inCall = false;
        users.remove(myUid);
        chatDofRef.update({
          'inCallUsers': users,
          'loudUser': loudUid == myUid ? '' : loudUid
        });
        _engine.destroy();
      },
      userJoined: (uid, elapsed) {},
      userOffline: (uid, elapsed) {
        users.remove(uid);
        chatDofRef.update({'inCallUsers': users});
      },
    ));
  }

  Widget selectedCaller() {
    return selUid != null && users[selUid] != null
        ? Expanded(
            child: callerTile(
                uid: selUid, avatarSize: 48, fontSize: 18, iconSize: 27))
        : const SizedBox.shrink();
  }

  Widget callerTile(
      {String uid,
      double avatarSize = 24,
      double fontSize,
      double iconSize = 18}) {
    String userId = users[uid]['userId'];
    bool mute = uid == myUid ? muted : mutedUsers.contains(uid);
    bool active = activeUsers.contains(uid) ? !mute : false;

    return GestureDetector(
      onTap: () {
        setState(() {
          selUid = uid;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                            const BoxShadow(
                                color: Colors.orange,
                                blurRadius: 4.5,
                                spreadRadius: 1.5)
                          ]
                        : null,
                  ),
                  child: userProfile(
                      userId: userId,
                      anon: widget.anon,
                      size: avatarSize,
                      toProfile: false)),
              mute
                  ? Icon(
                      Icons.mic_off_rounded,
                      color: Colors.white,
                      size: iconSize,
                    )
                  : const SizedBox.shrink()
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          !widget.anon
              ? userName(
                  userId: userId,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                  color: Colors.white)
              : const SizedBox.shrink()
        ],
      ),
    );
  }

  Widget callerList() {
    return users.isNotEmpty
        ? Container(
            alignment: Alignment.center,
            height: MediaQuery.of(context).size.height * 0.25,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: users.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                String uid = users.keys.elementAt(index);
                return uid != selUid
                    ? callerTile(uid: uid)
                    : const SizedBox.shrink();
              },
            ),
          )
        : const SizedBox.shrink();
  }

  Widget toolbar() {
    if (widget.role == ClientRole.Audience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      height: MediaQuery.of(context).size.height * 0.25,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.black54,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: Colors.white,
              size: 18.0,
            ),
          ),
          RawMaterialButton(
            onPressed: _onCallEnd,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 27.0,
            ),
          ),
          RawMaterialButton(
            onPressed: _onToggleAudio,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.black54,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              deafen ? Icons.headset_off : Icons.headset,
              color: Colors.white,
              size: 18.0,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(
          color: Colors.white,
        ),
        elevation: 0.0,
      ),
      body: StreamBuilder(
          stream: chatDofRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data.data() != null) {
              users = snapshot.data.data()['inCallUsers'] ?? {};
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [selectedCaller(), callerList(), toolbar()],
            );
          }),
    );
  }

  void _onCallEnd() {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onToggleAudio() {
    setState(() {
      deafen = !deafen;
    });
    _engine.muteAllRemoteAudioStreams(deafen);
  }

  void _turnOnCamera() {
    _engine.enableVideo();
  }

  void _turnOffCamera() {
    _engine.disableVideo();
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }
}
