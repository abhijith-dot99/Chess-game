import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:mychessapp/pages/login_register_page.dart';
import 'package:mychessapp/pages/userprofiledetails.dart';
import 'package:mychessapp/splash.dart';
import 'dart:async';

import 'package:mychessapp/splash.dart';
import 'package:mychessapp/userprofiledetails.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: const FirebaseOptions(apiKey: "AIzaSyA5LntFnqarzEsZoDAx8WuO98rnLaZjFzA", appId: "1:820296910788:web:00ca69115e86ddd8cd8691", messagingSenderId: "820296910788", projectId: "chessapp-68652"));
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({Key? key}) : super(key: key);

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
      theme: ThemeData(primarySwatch: primaryBlack), // Use the custom primaryBlack MaterialColor
      home: ChessSplashScreen(),
      debugShowCheckedModeBanner: false,
      // Change
      routes: {
        '/user_profile_details': (context) => const UserProfileDetailsPage(),
        '/login_register': (context) => LoginRegisterPage(),
        // other routes...
      },
    );
  }
}

class ChessBoard extends StatefulWidget {
  final String gameId;

  ChessBoard({Key? key, required this.gameId}) : super(key: key);

  @override
  _ChessBoardState createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  final game = chess.Chess();
  Timer? _timer;
  int _whiteTimeRemaining = 600; // 10 minutes in seconds
  int _blackTimeRemaining = 600; // 10 minutes in seconds
  //final bool _isWhiteTurn = true; // Track turns. White goes first.
  List<String> whiteCapturedPieces = [];
  List<String> blackCapturedPieces = [];
  String? lastMoveFrom;
  String? lastMoveTo;
  String? selectedSquare;
  List<String> legalMovesForSelected = [];

  String getPieceAsset(chess.PieceType type, chess.Color? color) {
    String assetPath;
    String pieceColor = color == chess.Color.WHITE ? 'white' : 'black';
    switch (type) {
      case chess.PieceType.PAWN:
        assetPath = 'assets/chess_pieces/$pieceColor/pawn.png';
        break;
      case chess.PieceType.KNIGHT:
        assetPath = 'assets/chess_pieces/$pieceColor/knight.png';
        break;
      case chess.PieceType.BISHOP:
        assetPath = 'assets/chess_pieces/$pieceColor/bishop.png';
        break;
      case chess.PieceType.ROOK:
        assetPath = 'assets/chess_pieces/$pieceColor/rook.png';
        break;
      case chess.PieceType.QUEEN:
        assetPath = 'assets/chess_pieces/$pieceColor/queen.png';
        break;
      case chess.PieceType.KING:
        assetPath = 'assets/chess_pieces/$pieceColor/king.png';
        break;
      default:
        assetPath = ''; // Return an empty string for any other cases (shouldn't occur)
    }
    return assetPath;
  }

  // Widget to display a chess piece
  Widget displayPiece(chess.Piece? piece) {
    if (piece != null) {
      return Image.asset(getPieceAsset(piece.type, piece.color));
    }
    return Container(); // Return an empty container if no piece is present
  }

  String _getRowLabel(int index) {
    // Label the rows from 1 to 8 starting from the bottom
    return '${1 + index}';
  }

  String _getColumnLabel(int index) {
    return String.fromCharCode(97 + index); // ASCII 'a' starts at 97
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (timer) {
      setState(() {
        if (game.turn == chess.Color.WHITE) {
          if (_whiteTimeRemaining > 0) {
            _whiteTimeRemaining--;
          } else {
            timer.cancel();
            _handleTimeout(chess.Color.WHITE);
          }
        } else {
          if (_blackTimeRemaining > 0) {
            _blackTimeRemaining--;
          } else {
            timer.cancel();
            _handleTimeout(chess.Color.BLACK);
          }
        }
      });
    });
  }

  void _handleTimeout(chess.Color color) {
    // Logic for handling timer timeout
    String winner = color == chess.Color.WHITE ? "Black" : "White";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Out'),
        content: Text('$winner wins by timeout!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                game.reset();
                whiteCapturedPieces.clear();
                blackCapturedPieces.clear();
                _whiteTimeRemaining = 600; // Reset the timer
                _blackTimeRemaining = 600; // Reset the timer
                _startTimer(); // Restart the timer for the new game
              });
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _onMoveMade() {
    // Logic for when a move is made
    game.move({"from": selectedSquare!, "to": lastMoveTo});

    if (game.in_checkmate) {
      // Handle checkmate
    } else if (game.in_draw) {
      // Handle draw
    } else {
      _switchTimer(); // Switch the timer to the other player
    }
  }

  void _switchTimer() {
    // Switch the timer to the other player
    _timer?.cancel(); // Cancel the previous timer
    _startTimer(); // Start a new timer for the next player
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  Widget _buildPlayerArea(List<String> capturedPieces, bool isTop) {
    return Container(
      color: Colors.grey[200], // Just for visibility, adjust the color as needed
      height: 50, // Adjust the height as needed
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Timer and captured pieces area
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: capturedPieces.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Image.asset(
                    capturedPieces[index],
                    fit: BoxFit.cover,
                    height: 50, // Half the square size, adjust as needed
                  ),
                );
              },
            ),
          ),
          // Timer display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(
              isTop ? _formatTime(_blackTimeRemaining) : _formatTime(_whiteTimeRemaining),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14, // Adjust font size as needed
              ),
            ),
          ),
          // Placeholder for circle, replace with actual circle widget if needed
          Container(
            width: 50, // Adjust width as needed
            height: 50, // Adjust height as needed
            decoration: const BoxDecoration(
              color: Colors.black, // Circle color
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Au-Ki Chess',
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Align items to the center
        children: [
          _buildPlayerArea(blackCapturedPieces, true),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8,),
                    itemCount: 64,
                    itemBuilder: (context, index) {
                      final int file = index % 8;
                      final int rank = 7 - index ~/ 8;
                      final squareName = '${String.fromCharCode(97 + file)}${rank + 1}';
                      final piece = game.get(squareName);

                      Color colorA = const Color(0xFFA09B9B);
                      Color colorB = const Color(0xFFEFE8E8);

                      // Determine the color of the square
                      var squareColor = (file + rank) % 2 == 0 ? colorA : colorB;

                      // Determine the color for the label (opposite of the square)
                      Color labelColor = squareColor == colorA ? colorB : colorA;

                      // Declare a border variable
                      Border? border;

                      // Define a variable to check if the square is a legal move
                      bool isLegalMove = legalMovesForSelected.contains(squareName);

                      // Check if the square is the starting or ending position of the last move
                      bool isLastMoveSquare = squareName == lastMoveFrom || squareName == lastMoveTo;
                      if (isLastMoveSquare) {
                        squareColor = Colors.lightBlue.withOpacity(0.3); // Adjust the color and opacity as needed
                      }



                      return GestureDetector(
                        onTap: () {
                          print('Square tapped: $squareName');
                          print('Selected square: $selectedSquare');
                          print('Legal moves: ${legalMovesForSelected.isNotEmpty}');
                          setState(() {
                            //if (game.get(squareName)?.color == game.turn) {
                            if (piece != null && piece.color == game.turn) {
                              // Select the piece at the tapped square
                              selectedSquare = squareName;
                              var moves = game.generate_moves();
                              legalMovesForSelected = moves
                                  .where((move) => move.fromAlgebraic == selectedSquare)
                                  .map((move) => move.toAlgebraic)
                                  .toList();
                              print('Piece selected at $selectedSquare. Legal moves: $legalMovesForSelected');

                              // If no legal moves, deselect the piece
                              if (legalMovesForSelected.isEmpty) {
                                selectedSquare = null;
                              }
                            }
                            // If no square is selected and there is a piece on the current square
                            else if (selectedSquare != null &&
                                legalMovesForSelected.contains(squareName)) {
                              final pieceBeforeMove = game.get(squareName);
                              // Execute the move
                              game.move({
                                "from": selectedSquare!,
                                "to": squareName
                              });
                              // Update last move
                              lastMoveFrom = selectedSquare;
                              lastMoveTo = squareName;

                              // After move, check if the move was a capture
                              if (pieceBeforeMove != null &&
                                  pieceBeforeMove.color != game
                                      .get(selectedSquare!)
                                      ?.color) {
                                final capturedPiece = getPieceAsset(
                                    pieceBeforeMove.type,
                                    pieceBeforeMove.color);
                                if (game.turn == chess.Color.BLACK) {
                                  whiteCapturedPieces.add(capturedPiece);
                                } else {
                                  blackCapturedPieces.add(capturedPiece);
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
                                  status =
                                  'Draw due to insufficient material!';
                                } else {
                                  status = 'Unexpected game status';
                                }

                                // Show dialog for checkmate or draw
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      AlertDialog(
                                        title: const Text('Game Over'),
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
                                            child: const Text('Restart'),
                                          ),
                                        ],
                                      ),
                                );
                              } else if (game.in_check) {
                                // Show alert dialog if the player is in check
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      AlertDialog(
                                        title: const Text('Check!'),
                                        content: Text(
                                            game.turn == chess.Color.WHITE
                                                ? 'White is in check!'
                                                : 'Black is in check!'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                              } else {
                                _switchTimer(); // Switch the timer for the next player
                              }

                              selectedSquare = null;
                              legalMovesForSelected = [];
                            } else
                            if (selectedSquare == null && piece != null) {
                              selectedSquare = squareName;
                              var moves = game.generate_moves();
                              legalMovesForSelected = moves
                                  .where((move) =>
                              move.fromAlgebraic == selectedSquare)
                                  .map((move) => move.toAlgebraic)
                                  .toList();
                            }
                            //}
                          });
                          print('Updated game state: ${game.fen}');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: squareColor,
                            border: border,
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: displayPiece(piece),
                              ),

                              // Add a circle for legal moves
                              if (isLegalMove)
                                Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 10, // Adjust the size of the circle
                                    height: 10, // Adjust the size of the circle
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5), // Adjust the color and opacity as needed
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),

                              // Add row labels
                              if (file == 0)
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Text(_getRowLabel(rank),
                                      style: TextStyle(color: labelColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                              // Add column labels
                              if (rank == 0)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Text(_getColumnLabel(file), style: TextStyle(color: labelColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    //itemCount: 64,
                  ),
                ),
              ),
            ),
          ),
          _buildPlayerArea(whiteCapturedPieces, false), // Bottom area for white player
        ],
      ),
    );
  }
}
