import 'package:aquarium_manager/views/aquarium_manager_tanks_view.dart';
import 'package:aquarium_manager/models/aquarium_manager_search_model.dart';
import 'package:aquarium_manager/views/consts.dart';
import 'package:flutter/material.dart';
import 'utility.dart';
import 'package:provider/provider.dart';
import '../models/aquarium_manager_tanks_model.dart';
import 'package:aquarium_manager/views/typography.dart';

class MyAquariumManagerSearchView extends StatefulWidget {
  const MyAquariumManagerSearchView({Key? key}) : super(key: key);

  @override
  State<MyAquariumManagerSearchView> createState() =>
      _MyAquariumManagerSearchViewState();
}

class _MyAquariumManagerSearchViewState
    extends State<MyAquariumManagerSearchView> {

  final TextEditingController controllerForSearch = TextEditingController();

  bool isPlainSearch = kPlainSearch;

  @override
  void dispose() {
    controllerForSearch.dispose();
    super.dispose();
  }

  // it's not demanding i make this final
  Widget displayCrossBreedingDate() {
    return CheckboxListTile(
      title: Text(
        "Display cross-breeding times (reverse chronological order)",
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: !isPlainSearch, // this checkbox is the opposite of the isPlainSearch value
      onChanged: (newValue) {
        setState(() {
          isPlainSearch = !newValue!;
          // we should redo the search here
          controllerForSearch.text= "";
          MyAquariumManagerSearchModel searchModel =
          Provider.of<MyAquariumManagerSearchModel>(context, listen: false);
          searchModel.prepareSearchTankList("",
              isPlainSearch); // we pass the checkbox value to change search to sort by cross-breed date
        });
      },
      controlAffinity: ListTileControlAffinity.leading, //  <-- leading Checkbox
    );
  }

  Widget buildCheckBox(
      BuildContext context, String labelText, bool? Function()? retrieveValue) {
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

    MyAquariumManagerSearchModel searchModel =
    Provider.of<MyAquariumManagerSearchModel>(context);

    int? birthDate = tank.getBirthDate();
    int? breedingDate = searchModel.computeBreedingDate(birthDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyAquariumManagerTankView(
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
                    isPlainSearch
                        ? "DOB: ${buildDateOfBirth(() => birthDate)}"
                        : "Cross-breeding date: ${buildDateOfBirth(() => breedingDate)}",
                    style: isPlainSearch ? Theme.of(context).textTheme.bodySmall : customTextStyle.bodySmallBold,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text("${tank.getNumberOfFish().toString()} fish", style: Theme.of(context).textTheme.bodySmall),
                  ),
                  buildCheckBox(
                      context, "Screen Positive", tank.getScreenPositive),
                  buildCheckBox(context,"Thin Tank", tank.getSmallTank),
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
                    enabled: isPlainSearch,
                    keyboardType: TextInputType.text,
                    controller: controllerForSearch,
                    onChanged: (value) {
                      searchModel.prepareSearchTankList(value,
                          kPlainSearch);
                    }),
              ),
              expandedFlex1(),
            ],
          ),
          Row(
            children: [
              expandedFlex1(),
              Expanded(
                flex: 2,
                child: displayCrossBreedingDate(),
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
