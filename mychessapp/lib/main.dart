import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chess/chess.dart' as chess;
import 'package:mychessapp/splash.dart';  // Make sure this path is correct

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: const FirebaseOptions(
    apiKey: "AIzaSyA5LntFnqarzEsZoDAx8WuO98rnLaZjFzA",
    appId: "1:820296910788:web:00ca69115e86ddd8cd8691",
    messagingSenderId: "820296910788",
    projectId: "chessapp-68652"
  ));
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    MaterialColor primaryBlack = const MaterialColor(0xFF000000, {
      50: Color(0xFF000000),
      100: Color(0xFF000000),
      200: Color(0xFF000000),
      300: Color(0xFF000000),
      400: Color(0xFF000000),
      500: Color(0xFF000000),
      600: Color(0xFF000000),
      700: Color(0xFF000000),
      800: Color(0xFF000000),
      900: Color(0xFF000000),
    });

    return MaterialApp(
      title: 'Chess Game',
      theme: ThemeData(primarySwatch: primaryBlack),
      home: const ChessSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChessBoard extends StatefulWidget {
  const ChessBoard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChessBoardState createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> with WidgetsBindingObserver {
  final game = chess.Chess();
  // ... rest of your chess game state variables ...

  
  List<String> whiteCapturedPieces = [];
  List<String> blackCapturedPieces = [];

  // State properties
  String? selectedSquare;
  List<String> legalMovesForSelected = [];

  String getPieceAbbreviation(chess.PieceType type) {
    switch (type) {
      case chess.PieceType.PAWN:
        return '♙';  
      case chess.PieceType.KNIGHT:
        return '♘';
      case chess.PieceType.BISHOP:
        return '♗';
      case chess.PieceType.ROOK:
        return '♖';
      case chess.PieceType.QUEEN:
        return '♕';
      case chess.PieceType.KING:
        return '♔';
      default:
        return ''; // Return an empty string for any other cases (shouldn't occur)
    }
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _updateUserOnlineStatus(true); // Set the user online when the app starts
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _updateUserOnlineStatus(false); // Set the user offline when the app is closed
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (FirebaseAuth.instance.currentUser != null) {
      if (state == AppLifecycleState.paused) {
        _updateUserOnlineStatus(false); // Set offline when app is in background
      } else if (state == AppLifecycleState.resumed) {
        _updateUserOnlineStatus(true); // Set online when app is in foreground
      }
    }
  }

  void _updateUserOnlineStatus(bool isOnline) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'isOnline': isOnline});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // Remove the app bar
      body: GridView.builder(
        itemCount: 64,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        itemBuilder: (context, index) {
          // ... your existing GridView builder logic ...



           final int file = index % 8;
          final int rank = 7 - index ~/ 8;
          final squareName = '${String.fromCharCode(97 + file)}${rank + 1}';
          final piece = game.get(squareName);
          var backgroundColor = (file + rank) % 2 == 0
              ? Color.fromARGB(255, 203, 208, 198)
              : Color.fromARGB(255, 99, 97, 95);

          // Declare a border variable
          Border? border;

          // Highlight legal moves
          if (legalMovesForSelected.contains(squareName)) {
            backgroundColor = Colors.green.withOpacity(0.3);
            border = Border.all(
                color: const Color.fromARGB(255, 132, 136, 141), width: 3.0);

            // If the move results in a capture, highlight the square with orange color
            if (game.get(squareName) != null) {
              backgroundColor = Colors.orange.withOpacity(0.5);
            }
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                // If no square is selected and there is a piece on the current square
                if (selectedSquare == null && piece != null) {
                  // Select the piece and get legal moves for it
                  selectedSquare = squareName;
                  var moves = game.generate_moves();
                  legalMovesForSelected = moves
                      .where((move) => move.fromAlgebraic == selectedSquare)
                      .map((move) => move.toAlgebraic)
                      .toList();
                } else if (selectedSquare != null) {
                  // If a square is selected and the move is legal
                  if (legalMovesForSelected.contains(squareName)) {
                    // Save the piece at the destination before the move
                    final pieceBeforeMove = game.get(squareName);

                    // Execute the move
                    game.move({"from": selectedSquare!, "to": squareName});

                    // After move, check if the move was a capture
                    if (pieceBeforeMove != null &&
                        piece?.color != pieceBeforeMove.color) {
                      // If the move was a capture, add the captured piece to the list
                      final capturedPiece =
                          getPieceAbbreviation(pieceBeforeMove.type);
                      if (game.turn == chess.Color.WHITE) {
                        // If it's white's turn after the move, black's piece was captured
                        blackCapturedPieces.add(capturedPiece);
                      } else {
                        // If it's black's turn after the move, white's piece was captured
                        whiteCapturedPieces.add(capturedPiece);
                      }
                    }

                    // Check for check or checkmate
                    if (game.in_checkmate ||
                        game.in_stalemate ||
                        game.in_threefold_repetition ||
                        game.insufficient_material) {
                      String status;
                      if (game.in_checkmate) {
                        status = game.turn == chess.Color.WHITE
                            ? 'Black wins by checkmate!'
                            : 'White wins by checkmate!';
                      } else if (game.in_stalemate) {
                        status = 'Draw by stalemate!';
                      } else if (game.in_threefold_repetition) {
                        status = 'Draw by threefold repetition!';
                      } else if (game.insufficient_material) {
                        status = 'Draw due to insufficient material!';
                      } else {
                        status = 'Unexpected game status';
                      }

                      // Show dialog for checkmate or draw
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Game Over'),
                          content: Text(status),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  game.reset();
                                  whiteCapturedPieces.clear();
                                  blackCapturedPieces.clear();
                                });
                              },
                              child: Text('Restart'),
                            ),
                          ],
                        ),
                      );
                    } else if (game.in_check) {
                      // Show alert dialog if the player is in check
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Check!'),
                          content: Text(game.turn == chess.Color.WHITE
                              ? 'White is in check!'
                              : 'Black is in check!'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  // Reset selected square and legal moves
                  selectedSquare = null;
                  legalMovesForSelected = [];
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: border, // Add the border to the container decoration
              ),
              child: Center(
                child:
                    Text(piece != null ? getPieceAbbreviation(piece.type) : '',
                        style: TextStyle(
                          fontSize: 34.0,
                          color: piece?.color == chess.Color.WHITE
                              ? const Color.fromARGB(255, 250, 247, 247)
                              : const Color.fromARGB(255, 9, 2, 2),
                        )),
              ),
            ),
          );
        },
      ),
    );
  }
}
