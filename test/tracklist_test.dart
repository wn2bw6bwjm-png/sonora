import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/domain/entities/track.dart';

void main() {
  filenameTests();
  test('parseTracklist reads titles and optional durations', () {
    final t = parseTracklist('One 3:10\n\n  Two  \nThree Part 12:05');
    expect(t.map((e) => e.title), ['One', 'Two', 'Three Part']);
    expect(t[0].durationMs, 190000);
    expect(t[1].durationMs, isNull);
    expect(t[2].durationMs, 725000);
  });

  test('parseGenres trims and drops empties', () {
    expect(parseGenres(' Jazz, ,Ambient ,'), ['Jazz', 'Ambient']);
  });
}

void filenameTests() {
  test('titleFromFilename cleans file names', () {
    expect(titleFromFilename('01 - Song_Name.mp3'), 'Song Name');
    expect(titleFromFilename('Track.mp3'), 'Track');
    expect(titleFromFilename('1984 live.flac'), '1984 live');
    expect(titleFromFilename('07. Another One.m4a'), 'Another One');
  });
}
