import 'package:flutter/material.dart';
import '../model/aquarium_manager_notes_model.dart';
import '../model/aquarium_manager_tanks_model.dart';

class NotesDialogBody extends StatefulWidget {
  final Tank currentTank;
  final MyAquariumManagerTanksModel tanksModel;

  const NotesDialogBody(
      {Key? key, required this.tanksModel, required this.currentTank})
      : super(key: key);

  @override
  _NotesDialogBodyState createState() => _NotesDialogBodyState();
}

class _NotesDialogBodyState extends State<NotesDialogBody> {
  Widget notesItem(BuildContext context, Notes notes, int index) {
    TextEditingController controllerForNotesItem = TextEditingController();

    controllerForNotesItem.text = notes.returnIndexedNoteText(index);

    print("i am in notes item for index, ${index}");
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                enabled: (index == 0)
                    ? true
                    : false, //only the current (first) note field is editable
                readOnly: (index == 0) ? false : true,
                controller: controllerForNotesItem,
                onChanged: (value) {
                  notes.updateNoteText(value);
                  widget.tanksModel
                      .callNotifyListeners(); // we need to update the notes display in the parent folder
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(notes.returnIndexedNoteDate(index)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              child: Text("Add New Note"),
              onPressed: () {
                setState(() {
                  widget.currentTank.notes
                      .addNote(); // also saves the empty note; by this time, we know the tank_fk.
                });
              },
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.currentTank.notes.notesList.length,
            itemBuilder: (BuildContext context, int index) {
              print("notes are ${widget.currentTank.notes}");

              return notesItem(context, widget.currentTank.notes, index);
            },
          ),
        ),
      ],
    );
  }
}