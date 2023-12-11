import 'package:flutter/material.dart';
import '../models/notes_model.dart';
import '../view_models/tanks_viewmodel.dart';
import '../models/tank_model.dart';

class NotesDialogBody extends StatefulWidget {
  final Tank currentTank;
  final TanksViewModel tanksModel;

  const NotesDialogBody(
      {super.key, required this.tanksModel, required this.currentTank});

  @override
  NotesDialogBodyState createState() => NotesDialogBodyState();
}

class NotesDialogBodyState extends State<NotesDialogBody> {
  // i just moved this field from inside notesItem, 9/3/2023
  final TextEditingController controllerForNotesItem = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the controller text. Assuming 'returnIndexedNoteText(0)' returns the initial text.
    if (widget.currentTank.notes.notesList.isNotEmpty) {
      controllerForNotesItem.text =
          widget.currentTank.notes.returnIndexedNoteText(0);
    }
  }

  @override
  void dispose() {
    controllerForNotesItem.dispose();
    super.dispose();
  }

  Widget notesItem(BuildContext context, Notes notes, int index) {
    // item 0 is the textfield
    if (index > 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom:12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notes.returnIndexedNoteText(index),
                style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                )
            ),
            Text(notes.returnIndexedNoteDate(index)),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            child: const Text("Add New Note"),
            onPressed: () {
              setState(() {
                widget.currentTank.notes
                    .addNote(); // also saves the empty note; by this time, we know the tank_fk.
                // reset the textfield to blank
                controllerForNotesItem.text = "";
              });
            },
          ),
          (widget.currentTank.notes.notesList.isNotEmpty) ?
          TextField(
            controller: controllerForNotesItem,
            onChanged: (value) {
              widget.currentTank.notes.updateNoteText(value);
              widget.tanksModel
                  .callNotifyListeners(); // we need to update the notes display in the parent folder
            },
          ) : Container(),
          // 0 is the first note in the noteslist
          (widget.currentTank.notes.notesList.isNotEmpty) ?
          Text(widget.currentTank.notes.returnIndexedNoteDate(0)) : Container(),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.currentTank.notes.notesList.length,
              itemBuilder: (BuildContext context, int index) {
                return notesItem(context, widget.currentTank.notes, index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
