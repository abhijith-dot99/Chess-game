// challenge_request_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../firebase_game_service.dart';
import '../main.dart';

class ChallengeRequestScreen extends StatelessWidget {
  final String challengerName;
  final String challengerUID; // UID of the challenger
  final String opponentUID; // UID of the opponent (current user)
  final String betAmount; //
  final String challengeId;

  ChallengeRequestScreen({
    required this.challengerName,
    required this.challengerUID,
    required this.opponentUID,
    required this.betAmount,
    required this.challengeId,
  });

  // Inside your challenge handling code



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Challenge Request'),
      content: Column(
        children: [
          Text('You have been challenged by $challengerName with a bet of $betAmount.'),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // In ChallengeRequestScreen
              ElevatedButton(
                onPressed: () async {
                  // Accept the challenge
                  // When a challenge is accepted and you're creating a new game
                  String newGameId = await FirebaseGameService.createNewGame(challengerUID, opponentUID, challengeId);


                  // Update the challenge request in Firestore
                  FirebaseFirestore.instance.collection('challengeRequests').doc(challengeId).update({
                    'status': 'accepted',
                    'gameId': newGameId, // The ID of the newly created game
                  });

                  // Navigate to the ChessBoard
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChessBoard(gameId: newGameId),
                    ),
                  );
                },
                child: Text('Accept'),
              ),



              ElevatedButton(
                onPressed: () {
                  // TODO: Reject the challenge
                  Navigator.pop(context, false); // Pass false to indicate the challenge is rejected
                },
                child: Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
