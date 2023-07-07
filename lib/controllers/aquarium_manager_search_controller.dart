import 'package:aquarium_manager/controllers/aquarium_manager_tanks_controller.dart';
import 'package:aquarium_manager/model/aquarium_manager_search_model.dart';
import 'package:aquarium_manager/views/consts.dart';
import 'package:flutter/material.dart';
import '../views/utility.dart';
import 'package:provider/provider.dart';
import '../model/aquarium_manager_tanks_model.dart';
import 'package:aquarium_manager/views/typography.dart';

class MyAquariumManagerSearchController extends StatelessWidget {
  MyAquariumManagerSearchController({Key? key}) : super(key: key);

  final TextEditingController controllerForSearch = TextEditingController();

  Widget buildCheckBox(BuildContext context, String labelText, bool? Function()? retrieveValue) {
    return SizedBox(
      width: 150,
      child: CheckboxListTile(
        title: Text(
          labelText,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: retrieveValue?.call() ?? false,
        onChanged: null,
        controlAffinity:
            ListTileControlAffinity.leading, //  <-- leading Checkbox
      ),
    );
  }

  Widget searchedItem(context, Tank tank, int index) {
    // we will build a container of items;
    // must be tappable.
    // we need more info; we need the facility, rack and document id to pass onto the other controller
    // what will display
    // 1) tankline, 2) dob 3) smalltank 4) screen positive, 5) generation, 6)

    return GestureDetector(
      onTap: () {
        myPrint("abs position of tank I clicked on is ${tank.absolutePosition}");
        myPrint("abs position of rack on this tank is ${tank.rackFk}");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyAquariumManagerTankController(
              arguments: {
                'incomingRack_Fk': tank.rackFk,
                'incomingTankPosition': tank.absolutePosition,
              },
            ),
          ),
        );
      },
      child: Container(
        color: (index % 2 == 0) ? blueShades[100] : blueShades[200],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Row(
                children: [
                  Text(
                    tank.tankLine!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Row(
                children: [
                  Text(
                    "DOB: ${buildDateOfBirth(tank.getBirthDate)}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  buildCheckBox(context,"Screen Positive", tank.getScreenPositive),
                  buildCheckBox(context,"Small Tank", tank.getSmallTank),
                  Text(
                    "Generation: F${(tank.generation.toString())}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MyAquariumManagerSearchModel searchModel =
        Provider.of<MyAquariumManagerSearchModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(kProgramName),
      ),
      body: Column(
        children: [
          buildOuterLabelHeadlineSmall(context, "Search Tanks"),
          Row(
            children: [
              expandedFlex1(),
              Expanded(
                flex: 2,
                child: TextField(
                    keyboardType: TextInputType.text,
                    controller: controllerForSearch,
                    onChanged: (value) {
                      searchModel.prepareSearchTankList(value); // provider is updating this widget
                    }),
              ),
              expandedFlex1(),
            ],
          ),
          buildOuterLabelHeadlineSmall(context, "Results"),
          SizedBox(
            height: MediaQuery.of(context).size.height * 4 / 6,
            width: MediaQuery.of(context).size.width * 5 / 6,
            child: Center(
              child: ListView.builder(
                itemCount: searchModel.tankListSearched.length,
                itemBuilder: (BuildContext context, int index) {
                  return searchedItem(
                      context, searchModel.tankListSearched[index], index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
