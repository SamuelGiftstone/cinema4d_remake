/// Simple Command-pattern interface backing the Edit > Undo/Redo stack.
/// Each command knows how to apply and reverse itself; [AppState] just
/// keeps two stacks of these and calls [undo]/[redo].
abstract class Command {
  void undo();
  void redo();
}

/// A generic command built from two closures — enough to cover object
/// add/delete/transform without a dedicated class for each case.
class ClosureCommand implements Command {
  final void Function() _undo;
  final void Function() _redo;

  ClosureCommand({required void Function() undo, required void Function() redo})
      : _undo = undo,
        _redo = redo;

  @override
  void undo() => _undo();

  @override
  void redo() => _redo();
}
