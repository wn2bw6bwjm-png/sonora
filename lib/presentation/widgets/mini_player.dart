import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sonora/presentation/blocs/player/player_bloc.dart';
import 'package:sonora/presentation/blocs/player/player_event.dart';
import 'package:sonora/presentation/blocs/player/player_state.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Color(0xFF1E1E1E),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.music_note, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'SONORA',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          Icon(Icons.skip_previous, size: 20, color: Colors.white70),
          IconButton(
            icon: Icon(Icons.play_arrow, size: 24, color: Colors.white),
            onPressed: () {},
          ),
          Icon(Icons.skip_next, size: 20, color: Colors.white70),
        ],
      ),
    );
  }