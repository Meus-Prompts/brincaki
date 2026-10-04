// lib/games/termo/logic/evaluate.dart

enum LetterResult { correct, present, absent }

/// Cores de uma tentativa, pela regra oficial: verdes primeiro; amarelas só
/// enquanto sobrar a letra na resposta.
List<LetterResult> evaluateGuess(String guess, String answer) {
  final result = List.filled(guess.length, LetterResult.absent);
  final remaining = <String, int>{};
  for (var i = 0; i < answer.length; i++) {
    if (guess[i] == answer[i]) {
      result[i] = LetterResult.correct;
    } else {
      remaining[answer[i]] = (remaining[answer[i]] ?? 0) + 1;
    }
  }
  for (var i = 0; i < guess.length; i++) {
    if (result[i] == LetterResult.correct) continue;
    final left = remaining[guess[i]] ?? 0;
    if (left > 0) {
      result[i] = LetterResult.present;
      remaining[guess[i]] = left - 1;
    }
  }
  return result;
}
