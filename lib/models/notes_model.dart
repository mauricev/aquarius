import 'package:appwrite/appwrite.dart';
import '../view_models/session_key.dart';
import 'package:appwrite/models.dart' as models;
import 'package:intl/intl.dart';
import '../views/utility.dart';
import '../views/consts.dart';
import '../models/tank_model.dart';

class Notes {
  final ManageSession manageSession;
  Tank parentTank;
  List<Map<String, dynamic>> notesList =
      []; // each note has a note, a date and tank_fk

  Notes({required this.parentTank, required this.manageSession});

  bool isParentTankIDValid() {
    return parentTank.documentId != null;
  }

  String? returnParentTankID() {
    return parentTank.documentId;
  }

  // we don’t pass an index because only the first note, [0], is “live”
  Map<String, dynamic> prepareNoteMap() {
    Map<String, dynamic> theNoteMap = {
      'note': notesList[0]['note'],
      'date': notesList[0]['date'],
      'tank_fk': notesList[0]['tank_fk'],
    };
    return theNoteMap;
  }

  void postPrepareNoteMap(String documentId) {
    notesList[0]['document id'] = documentId;
  }

  void saveNewNote() async {
    if (isParentTankIDValid()) {
      Map<String, dynamic> theNoteMap = prepareNoteMap();
      models.Document theNoteDocument =
          await manageSession.createDocument(theNoteMap, cNotesCollection);
      postPrepareNoteMap(theNoteDocument.$id);  // BUG, critical step, we assign the notes array item its document id, so we can use that to save future edits
    }
  }

  // this will be called every time during the onchanged event
  void saveExistingNote() async {
    if (isParentTankIDValid()) {
      Map<String, dynamic> theNoteMap = prepareNoteMap();
      manageSession.updateDocument(theNoteMap, cNotesCollection,
          notesList[0]['document id']); // this should be the NOTE's document ID, but how did this value get put into map
    }
  }

  // notes don’t get deleted; they get reassigned to the expiredtanks_collection

  // when we add a note, we are in the dialog and we know the tank this is a part of
  void addNote() {
    if (isParentTankIDValid()) {
      // notes without a valid tank_fk cannot be saved!
      Map<String, dynamic> theNotesMap = {
        'note': "", // when a new note is initially added, it contains no text
        'date': returnTimeNow(),
        'tank_fk': returnParentTankID(),
      };
      notesList.insert(
          0, theNotesMap); // added new items to the beginning of the list
      saveNewNote(); // save the first index; this will append the document id for future saving of this note
    } else {
      myPrint("NOT adding a note, ${returnParentTankID()}");
    }
  }

  // only the first note can be updated
  void updateNoteText(String noteText) {
    Map<String, dynamic> note = notesList.elementAt(0);
    note['note'] = noteText;
    note['date'] = returnTimeNow();
    // need to save note for the first time; will always have a valid tank_fk
    saveExistingNote();
  }

  String? returnCurrentNoteText() {
    if (notesList.isNotEmpty) {
      return notesList[0]['note'];
    }
    return null;
  }

  String returnIndexedNoteText(int index) {
    return notesList[index]['note'];
  }

  String returnIndexedNoteDate(int index) {
    DateTime date =
        DateTime.fromMillisecondsSinceEpoch(notesList[index]['date']);
    return DateFormat.yMMMMd().format(date);
  }

  // we will need to read these notes into the array
  Future<void> loadNotes() async {
    if (isParentTankIDValid()) {
      try {
        notesList.clear(); // in case we have any notes from earlier, clear them

        String? theParentId = returnParentTankID();

        List<String>? notesQuery = [
          Query.equal("tank_fk", theParentId),
        ];

        models.DocumentList theNotesList =
            await manageSession.queryDocument(cNotesCollection, notesQuery);

        for (int theIndex = 0; theIndex < theNotesList.total; theIndex++) {
          models.Document theNote = theNotesList.documents[theIndex];
          Map<String, dynamic> theNotesMap = {
            'document id': theNote.$id, // we need this piece of info to identify which note we are saving during future edits by the user
            'note': theNote.data['note'],
            'date': theNote.data['date'],
            'tank_fk': theParentId,
            // when we save notes, we need to save this so that each note must have its own copy
          };

          // how are we sorting these? // newer items must be added first
          notesList.add(theNotesMap);

          notesList.sort((a, b) => b['date'].compareTo(a['date']));
        }
      } catch (e) {
        myPrint("I CAN’T FIND THE RIGHT TANK, ${e.toString()}");
      }
    }
  }
}
