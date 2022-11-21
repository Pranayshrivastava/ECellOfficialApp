import 'package:ecellapp/models/leader_board.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecellapp/screens/b_quiz/leaderBoard/leaderboard_repository.dart';
import 'package:ecellapp/core/res/colors.dart';
import 'package:ecellapp/core/res/dimens.dart';
import 'package:ecellapp/core/res/strings.dart';


class LeaderCard extends StatelessWidget {
  final Data? Leader;
  final int? rank;

  const LeaderCard({Key? key, this.Leader, this.rank,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double ratio = MediaQuery.of(context).size.aspectRatio;
    String username=" ";
    if(Leader!.username!=null){
      username=Leader!.username;
    }
    String phoneORemail = " ";
    if(APILeaderRepository.UNEmail[Leader!.username]!=null){
      phoneORemail=APILeaderRepository.UNEmail[Leader!.username];
    }
    if(APILeaderRepository.UNEmail[Leader!.username]==null){
      String? ph=" ";
      if(Leader!.phone !=null){
        ph=(Leader!.phone)?.substring(0,5)!;
      }
      phoneORemail = ph!+"XXXXX";
    }
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: D.horizontalPaddingFrame),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    height: ratio > 0.5 ? 120 : 130,
                    width: ratio > 0.5 ? 210 : 230 ,
                    margin: EdgeInsets.only(left: 100),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Leader!.username,
                          style: TextStyle(
                            fontSize: 20,
                            color: C.cardFontColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          phoneORemail,
                          style: TextStyle(fontSize: 17, color: C.cardFontColor),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Score:${Leader!.bquizScore}",
                          style: TextStyle(fontSize: 17, color: C.cardFontColor),
                        ),
                      ],
                    ),
                  ),

                ),
              ),

            ],
          ),
        ),
        Positioned(
          height: ratio > 0.5 ? 150 : 180,
          width: ratio > 0.5 ? 150 : 170,
          child: Stack(
            children: [
              Image.asset(
                S.assetSpeakerCardFrame,
                fit: BoxFit.cover,
                height: 220,
              ),
              Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(bottom: 10,right: 15),
                  child: Text("# $rank",style: TextStyle(fontSize: 40,fontWeight: FontWeight.bold),)
              ),
            ],
          ),
        ),

      ],
    );
  }
}
