import 'dart:async';

import 'package:data_connection_checker_nulls/data_connection_checker_nulls.dart';
import 'package:ecellapp/core/res/colors.dart';
import 'package:ecellapp/models/questions.dart';
import 'package:ecellapp/screens/b_quiz/leaderBoard/leaderboard_repository.dart';
import 'package:ecellapp/screens/b_quiz/quiz_success.dart';
import 'package:ecellapp/screens/b_quiz/widgets/question_card.dart';
import 'package:ecellapp/widgets/gradient_text.dart';
import 'package:ecellapp/widgets/raisedButton.dart';
import 'package:ecellapp/widgets/screen_background.dart';
import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/ecell_animation.dart';
import '../../../widgets/reload_on_error.dart';
import '../../../widgets/stateful_wrapper.dart';
import '../../models/global_state.dart';
import '../../models/user.dart';
import 'cubit/quiz_cubit.dart';

class Quiz extends StatefulWidget {
  final String label;

  const Quiz({Key? key, required this.label}) : super(key: key);
  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  @override
  @override
  Widget build(BuildContext context) {
    return StatefulWrapper(
      onInit: () => _getAllQuizes(context),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [C.backgroundTop1, C.backgroundBottom1],
            ),
          ),
          child: BlocBuilder<QuizCubit, QuizState>(
            builder: (context, state) {
              print(state);
              if (state is QuizInitial)
                return _buildLoading(context);
              else if (state is QuizSuccess)
                return Success(
                  QuizList: state.QuizList,
                  label: widget.label,
                );
              else if (state is QuizLoading)
                return _buildLoading(context);
              else
                return ReloadOnErrorWidget(() => _getAllQuizes(context));
            },
          ),
        ),
      ),
    );
  }
}

StreamController<bool> streamController = StreamController<bool>.broadcast();

class Success extends StatefulWidget {
  final List<Questions> QuizList;
  final String? label;

  Success({
    Key? key,
    required this.QuizList,
    this.label,
  }) : super(key: key);

  @override
  State<Success> createState() => _SuccessState();
}

class _SuccessState extends State<Success> {
  final DataConnectionChecker connectionChecker = DataConnectionChecker();
  late StreamSubscription subscription;
  bool hasInternet = false;

  int score = 0;
  int currentQuestion = 1;
  int correctIndex = 0;
  int inputIndex = 0;
  int time = 0;
  final int _duration = 60;
  int pTime = DateTime.now().minute;

  @override
  void initState() {
    super.initState();
    APILeaderRepository _apiLeaderRepository =
        APILeaderRepository(label: widget.label!);

    User user = context.read<GlobalState>().user!;
    subscription = connectionChecker.onStatusChange.listen((status) {
      final hasInternet = status == DataConnectionStatus.connected;
      print("hasInternet=$hasInternet");
      if (!hasInternet) {
        score -= penalty(pTime, score);
        _apiLeaderRepository.uploadScore(score, user);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: ((context) =>
                QuizSuccessScreen(score: (score).toDouble()))));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Connection Lost'),
          backgroundColor: Colors.red,
        ));
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    subscription.cancel();
  }

  final PageController _pageController = PageController(initialPage: 0);
  final CountDownController _countDownController = CountDownController();
  Future<bool> _onBackPressed() async {
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Do you really want to close the Quiz?"),
            actions: [
              BackButton(
                text: "No",
                onpressed: () {
                  Navigator.pop(context, false);
                },
              ),
              BackButton(
                text: "Yes",
                onpressed: () {
                  APILeaderRepository _apiLeaderRepository =
                      APILeaderRepository(label: widget.label!);

                  User user = context.read<GlobalState>().user!;
                  Navigator.pop(context, true);
                  score -= penalty(pTime, score);
                  _apiLeaderRepository.uploadScore(score, user);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: ((context) =>
                          QuizSuccessScreen(score: (score).toDouble()))));
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    APILeaderRepository _apiLeaderRepository =
        APILeaderRepository(label: widget.label!);
    User user = context.read<GlobalState>().user!;
    double ratio = MediaQuery.of(context).size.aspectRatio;
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    double heightFactor = height / 1000;

    void callBack(int x, int y) {
      setState(() {
        inputIndex = x;
        correctIndex = y;

        print("$inputIndex $correctIndex");
      });
    }

    List<Widget> QuizContentList = [];
    widget.QuizList.forEach((element) => QuizContentList.add(QuestionCard(
          quiz: element,
          callBack: callBack,
          stream: streamController.stream,
        )));
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Stack(children: [
        ScreenBackground(elementId: 0),
        Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 30.0,
              ),
              GradientText("BQUIZ",
                  gradient: LinearGradient(
                    colors: [
                      C.bQuizGradient1,
                      C.bQuizGradient2,
                      C.bQuizGradient5,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )),
              SizedBox(
                height: height * 0.05,
              ),
              Container(
                height: height * 0.75,
                margin: EdgeInsets.symmetric(horizontal: width * 0.05),
                padding: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(20, 20),
                          blurRadius: 3,
                          spreadRadius: -10)
                    ]),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: Colors.black54),
                                  child: Icon(
                                    Icons.question_mark_outlined,
                                    color: Colors.white,
                                    size: 15,
                                  )),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                "$currentQuestion/${widget.QuizList.length}",
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          CircularCountDownTimer(
                            duration: _duration,
                            initialDuration: 0,
                            controller: _countDownController,
                            width: MediaQuery.of(context).size.width / 10,
                            height: MediaQuery.of(context).size.height / 10,
                            ringColor: Colors.grey[300]!,
                            fillColor: Colors.purpleAccent[100]!,
                            strokeWidth: 3.0,
                            strokeCap: StrokeCap.round,
                            textStyle: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            textFormat: CountdownTextFormat.S,
                            isReverse: true,
                            isReverseAnimation: false,
                            isTimerTextShown: true,
                            autoStart: true,
                            onStart: () {
                              debugPrint('Countdown Started');
                            },
                            onComplete: () {
                              time = int.parse(
                                  _countDownController.getTime().toString());
                              debugPrint('Countdown Ended');
                              if (_pageController.page !=
                                  QuizContentList.length - 1) {
                                _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut);

                                Future.delayed(Duration(milliseconds: 300), () {
                                  _countDownController.restart(
                                      duration: _duration);
                                });
                              } else {
                                print("time:$time");
                                print("$inputIndex---$correctIndex");
                                if (inputIndex != 0 &&
                                    correctIndex != 0 &&
                                    inputIndex == correctIndex) {
                                  streamController.add(true);
                                  score += calcScore(time);
                                  score -= penalty(pTime, score);
                                  print("Score:$score");
                                } else {
                                  streamController.add(false);
                                }
                                _apiLeaderRepository.uploadScore(score, user);
                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: ((context) =>
                                            QuizSuccessScreen(
                                                score: (score).toDouble()))));
                                _countDownController.pause();
                              }
                              if (_pageController.page !=
                                  QuizContentList.length - 1) {
                                setState(() {
                                  currentQuestion += 1;
                                  print("time:$time");
                                  print("$inputIndex---$correctIndex");
                                  if (inputIndex != 0 &&
                                      correctIndex != 0 &&
                                      inputIndex == correctIndex) {
                                    streamController.add(true);
                                    score += calcScore(time);
                                    print("Score:$score");
                                  } else {
                                    streamController.add(false);
                                  }
                                });
                              }
                              ;
                            },
                          ),
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              "Score: $score",
                              style: TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView(
                          physics: NeverScrollableScrollPhysics(),
                          controller: _pageController,
                          scrollDirection: Axis.horizontal,
                          children: QuizContentList),
                    ),
                  ],
                ),
              ),
            ]),
        Positioned(
          right: 15.0,
          bottom: 15.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  C.bQuizGradient1,
                  C.bQuizGradient2,
                  C.bQuizGradient3,
                  C.bQuizGradient4,
                  C.bQuizGradient5,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            child: LegacyFlatButtonShape(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              color: Colors.transparent,
              onPressed: () {
                time = int.parse(_countDownController.getTime().toString());
                if (_pageController.page != QuizContentList.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );

                  Future.delayed(Duration(milliseconds: 300), () {
                    _countDownController.restart(duration: _duration);
                  });
                } else {
                  print("Last Question update after pressing next");
                  print("time:$time");
                  print("$inputIndex---$correctIndex");
                  if (inputIndex != 0 &&
                      correctIndex != 0 &&
                      inputIndex == correctIndex) {
                    streamController.add(true);
                    score += calcScore(time);
                    score -= penalty(pTime, score);
                    print("Score:$score");
                  } else {
                    streamController.add(false);
                  }
                  _apiLeaderRepository.uploadScore(score, user);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: ((context) =>
                          QuizSuccessScreen(score: (score).toDouble()))));
                  _countDownController.pause();
                }
                if (_pageController.page != QuizContentList.length - 1) {
                  setState(() {
                    currentQuestion += 1;
                    print("SetState");
                    print("time:$time");
                    print("$inputIndex---$correctIndex");
                    if (inputIndex != 0 &&
                        correctIndex != 0 &&
                        inputIndex == correctIndex) {
                      streamController.add(true);
                      score += calcScore(time);
                      print("Score:$score");
                    } else {
                      streamController.add(false);
                    }
                  });
                }
                ;
              },
              child: Container(
                height: 30,
                width: 120,
                alignment: Alignment.center,
                child: Text(
                  "NEXT",
                  style: TextStyle(
                    letterSpacing: 0.75,
                    color: C.primaryUnHighlightedColor,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

Widget _buildLoading(BuildContext context) {
  double width = MediaQuery.of(context).size.width;
  return Center(child: ECellLogoAnimation(size: width / 2));
}

void _getAllQuizes(BuildContext context) {
  final cubit = context.read<QuizCubit>();
  cubit.getQuizList();
}

int calcScore(int time) {
  int score = (10 + (time + 60) * 10);
  print("SCORE===$score");
  return score;
}

int penalty(int penaltyTime, int prescore) {
  int minus = 0;
  if (penaltyTime < 5) {
    minus = 0;
  } else if (penaltyTime >= 5 && penaltyTime < 10) {
    minus = 5;
  } else if (penaltyTime >= 10 && penaltyTime < 15) {
    minus = 10;
  } else if (penaltyTime >= 15 && penaltyTime < 20) {
    minus = 15;
  } else if (penaltyTime >= 20) {
    minus = 20;
  }
  return minus;
}

class BackButton extends StatelessWidget {
  final String text;
  final Function onpressed;
  const BackButton({Key? key, required this.text, required this.onpressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            C.bQuizGradient1,
            C.bQuizGradient2,
            C.bQuizGradient3,
            C.bQuizGradient4,
            C.bQuizGradient5,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: LegacyRaisedButton(
          onPressed: onpressed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          color: Colors.transparent,
          child: Text(
            text,
            style: TextStyle(
              letterSpacing: 0.75,
              color: C.primaryUnHighlightedColor,
              fontSize: 26,
            ),
          )),
    );
  }
}
