// challenge_request_screen.dart

import 'package:flutter/material.dart';

class ChallengeRequestScreen extends StatelessWidget {
  final String challengerName;
  final String betAmount;

  ChallengeRequestScreen({required this.challengerName, required this.betAmount});

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
              ElevatedButton(
                onPressed: () {
                  // TODO: Accept the challenge
                  Navigator.pop(context, true); // Pass true to indicate the challenge is accepted
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
