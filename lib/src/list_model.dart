library model.list_model;

import 'dart:async';

import 'package:my_model/src/model.dart';


/// List to keep data.
///
/// That list may contain sub-models, and point is sub-models must be unique.
///
/// ListModel can't contain nulls. I guess we never should keeps nulls in
/// property lists, so, it's a way to catch a error.
class ListModel<T> implements IModel {
  @override
  Stream<ModelChange> get modelChanges => _changesStream.stream;

  final StreamController<ListModelChange> _changesStream = new StreamController<ListModelChange>.broadcast();

  final List<T> _values = <T>[];

  final Map<IModel, StreamSubscription<ModelChange>> _subs = new Map<IModel, StreamSubscription<ModelChange>>.identity();


  ListModel();

  ListModel.fromIterable(Iterable<T> items) {
    _values.addAll(items);
  }


  operator [] (int key) {
    return _values[key];
  }

  void add(T item) {
    if (item == null) throw new ArgumentError('List should not contains null.');

    if (item is IModel && _values.any((i) => identical(i, item))) throw new StateError('List already contains that Model.');

    if (item is! T) throw new ArgumentError('Adding item is not of subtype of generic type ${T}.');

    _values.add(item);
    if (item is IModel && !_subs.containsKey(item)) {
      _subs[item as IModel] = (item as IModel).modelChanges.listen((ch) => _refireChangeEvent(item, ch));
    }
    _changesStream.add(new AddItemChange(item, _values.length-1));
  }

  void remove(T item) {
    var index = _getIndex(item);
    if (index < 0) return;

    _values.removeAt(index);

    if (item is IModel && _subs.containsKey(item)) {
      _subs.remove(item).cancel();
    }
    _changesStream.add(new RemoveItemChange(item, index));
  }


  void _refireChangeEvent(T item, ModelChange event) {
    var index = _getIndex(item);
    if (index >= 0) _changesStream.add(new ListSubModelChange(index, event));
  }

  int _getIndex(T item) {
    for (var i = 0; i < _values.length; i++) {
      if (identical(_values[i], item)) return i;
    }

    return -1;
  }
}


abstract class ListModelChange extends ModelChange {

}


class AddItemChange<T> extends ListModelChange {
  final T value;
  final int index;

  AddItemChange(this.value, this.index);
}

class RemoveItemChange<T> extends ListModelChange {
  final T value;
  final int index;

  RemoveItemChange(this.value, this.index);
}

class ListSubModelChange extends SubModelChange implements ListModelChange {
  final int index;
  final ModelChange original;

  ListSubModelChange(this.index, this.original);
}