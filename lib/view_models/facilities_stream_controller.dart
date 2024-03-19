import 'dart:async';

// I can’t believe we are allowed globals in this fashion
// perhaps this should be in some class or something
final StreamController<String> facilityStreamController = StreamController<String>.broadcast();