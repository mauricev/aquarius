import 'package:flutter/material.dart';
import '../models/notes_model.dart';
import '../view_models/tanks_viewmodel.dart';
import 'package:aquarium_manager/views/utility.dart';
import 'package:aquarium_manager/models/tank_model.dart';

class NotesDialogBody extends StatefulWidget {
  final Tank currentTank;
  final TanksViewModel tanksModel;

  const NotesDialogBody(
      {Key? key, required this.tanksModel, required this.currentTank})
      : super(key: key);

  @override
  NotesDialogBodyState createState() => NotesDialogBodyState();
}

class NotesDialogBodyState extends State<NotesDialogBody> {
  // i just moved this field from inside notesItem, 9/3/2023
  final TextEditingController controllerForNotesItem = TextEditingController();

  @override
  void dispose() {
    controllerForNotesItem.dispose();
    super.dispose();
  }

  Widget notesItem(BuildContext context, Notes notes, int index) {

    controllerForNotesItem.text = notes.returnIndexedNoteText(index);

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
              child: const Text("Add New Note"),
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
              myPrint("notes are ${widget.currentTank.notes}");

              return notesItem(context, widget.currentTank.notes, index);
            },
          ),
        ),
      ],
    );
  }
}