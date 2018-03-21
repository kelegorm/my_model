library model.map_model;

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:my_model/src/model.dart';
import 'package:my_model/src/utils/compare.dart';

/// TODO rid of that class. Nobody else should implement it.
abstract class IMapModel extends IModel {
  Iterable<String> get keys;

  operator []= (String key, newValue);

  operator [] (String key);

  Map toJson();
}


/// Kind of Map with changes stream.
///
/// Keeps values in Map.
///
/// Also it notifies in stream about values internal changes if
/// they are [MapModel] too, so you can catch any model change in one
/// place.
///
/// It has not initial values, all values should be set through []=
/// operator. It automatically subscribes to all values which extends
/// [MapModel].
class MapModel implements IMapModel {

  Iterable<String> get keys => _values.keys;

  /// Stream with all model changes.
  ///
  /// Includes sub changes, means property is Model too and it that stream we
  /// can get Subchanges — which is a property own changes.
  Stream<ModelChange> get modelChanges => _changesStream.stream;

  Stream<ModelPropertyChange> get propertyChanges => modelChanges
      .where((ch) => ch is ModelPropertyChange)
      .map<ModelPropertyChange>((ch) => ch as ModelPropertyChange);

  final StreamController<ModelChange> _changesStream = new StreamController<ModelChange>.broadcast();

  /// Subscriptions to properties in case they are too [AnnotatedModel].
  final Map<String, StreamSubscription<ModelChange>> _submodelSubs = <String, StreamSubscription<ModelChange>>{};

  final Map<String, Object> _values = <String, Object>{};


  MapModel();

  /// assumes that JSON is serialized from this class
  /// does not check existence of properties
  ///
  /// Rarely used ctor: used only in:
  /// * BorderWrapper
  /// * LayoutOptions
  /// * LegendOptions
  ///
  /// Don't forget never set fields directly, only through []=.
  ///
  /// todo do we need make here deep map converting to Model?
  MapModel.fromMap(Map json) {
    /// [throws] on non-matched properties
    json.forEach((k, v) { this[k] = v; });
  }


  operator [] (String key) {
    return _values[key];
  }

  operator []= (String key, newValue) {
    var oldValue = this[key];
    if (!equals(oldValue, newValue)) {
      deleteValue(key);
      setValue(key, newValue);
      updateValueSubscribe(key, newValue);
      fireChange(new ModelPropertyChange(key, oldValue, newValue));
    }
  }

  operator ==(Object other) {
    if ( this.runtimeType != other.runtimeType ) return false;

    if (other is MapModel) {
      try {
        // todo make cacheable or remake with hashcode.
        // TODO reimplement it with general deep map equality function.
        return toJson().toString() == other.toJson().toString();
      } catch (ex) {
        print(ex);
      }
    } else {
      return false;
    }
  }

  void addAll(Map<String, Object> values) {
    values.forEach((key, val) {
      this[key] = val;
    });
  }

  /// Once again, it keeps not default values only.
  ///
  /// based on [] above
  ///
  /// TODO [un]serializer with saving class name to init and factory fromJson
  Map toJson() => _getComparableMap();


  /// Removes value from vault and unsubscribes from it.
  ///
  /// Do not call it, just override if you need.
  @protected
  void deleteValue(String key) {
    _values.remove(key);
  }

  /// Fire change event.
  ///
  /// Subclasses haven't access to stream controller,
  /// so there is method to add events into stream.
  @protected
  void fireChange(ModelChange change) {
    _changesStream.add(change);
  }

  /// Adds new value into vault.
  ///
  /// Do not call it, just override if you need.
  @protected
  void setValue(String key, value) {
    _values[key] = value;
  }

  /// Removes old subscription and makes one new.
  @protected
  void updateValueSubscribe(String key, newValue) {
    _submodelSubs.remove(key)?.cancel();
    if (newValue is MapModel) _listenProperty(key, newValue);
  }


  /// Used to compare Models to check difference.
  ///
  /// TODO may be to remake it at all, make just compare in == operator key by key?
  ///
  /// TODO cache calculations.
  Map _getComparableMap() => new Map.fromIterable(
      keys.where((propName) => this[propName] != null),
      key: (k) => k,
      value: (k) => this[k]
  );

  /// Listens values to its internal changes.
  void _listenProperty(String propertyName, MapModel value) {
    _submodelSubs[propertyName] = value.modelChanges.listen((change) {
      _changesStream.add(new SubModelChange(propertyName, change));
    });
  }
}


abstract class _MapModelChange extends ModelChange {
  final String key;

  _MapModelChange(this.key);
}


/// That class describes change which was in model itself.
///
/// It means model[key] now returns new value.
class ModelPropertyChange extends _MapModelChange {
  final Object newValue;

  /// Needed to compatibility with Observable.
  final Object oldValue;

  ModelPropertyChange(String key, this.oldValue, this.newValue) : super(key);
}


/// This class describes changes which was in property.
///
/// Model[key] returns same object, but some internal field of
/// object was changed.
class SubModelChange extends _MapModelChange {
  final String path;

  final ModelPropertyChange originalChange;

  /// [key] is a property name, which has internal change.
  ///
  /// [change] is one we got from the property. It may be just
  /// [ModelChange] or even other [SubModelChange].
  SubModelChange(String key, _MapModelChange change)
      : this.path = _calcPath(key, change),
        originalChange = change is SubModelChange ? change.originalChange : change,
        super(key);


  static String _calcPath(String name, _MapModelChange change) {
    return change is SubModelChange
        ? '$name.${change.path}' : '$name${change.key}';
  }
}