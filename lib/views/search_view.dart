import 'package:aquarius/view_models/facilities_viewmodel.dart';
import 'package:aquarius/view_models/tankitems_viewmodel.dart';
import 'package:aquarius/views/parent_tanks_view_common.dart';

import '../views/tanks_view.dart';
import '../view_models/search_viewmodel.dart';
import '../views/consts.dart';
import 'package:flutter/material.dart';
import 'utility.dart';
import 'package:provider/provider.dart';
import '../views/typography.dart';
import '../models/tank_model.dart';
import '../view_models/tanks_viewmodel.dart';

import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import 'package:fl_chart/fl_chart.dart';

Widget returnDOBTitle(double value, TitleMeta meta) {
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(
      //meta.formattedValue,
      buildDateOfBirth(() => value.toInt()),
    ),
  );
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {

  int? searchSelection = cTankLineSearch;

  final GlobalKey<SearchDropDownState> singleSearchKey = GlobalKey();

  ValueItem selectedSingleItem = const ValueItem(label: cTankLineLabelNotYetAssigned, value: cTankLineValueNotYetAssigned);

  void addItem(ValueItem item) {
  }

  void updateSelectedItem(ValueItem? newSelectedItem) {
    selectedSingleItem = newSelectedItem!;
    conductSearch(cNotify);
    FocusScope.of(context).unfocus();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildCheckBox(
      BuildContext context, String labelText, bool? Function()? retrieveValue) {
    return CheckboxListTile(
      title: Text(
        labelText,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: retrieveValue?.call() ?? false,
      onChanged: null,
      controlAffinity:
          ListTileControlAffinity.leading, //  <-- leading Checkbox
    );
  }

  Widget searchedItem(context, Tank tank, int index) {

    SearchViewModel searchModel = Provider.of<SearchViewModel>(context);

    TanksLiveViewModel tankViewModel =
    Provider.of<TanksLiveViewModel>(context, listen: false);

    TanksLineViewModel tanksLineViewModel =
    Provider.of<TanksLineViewModel>(context, listen: false);

    FacilityViewModel facilitiesViewModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    ValueItem theTankLineValueItem = tanksLineViewModel.returnTankItemFromDocId((tank.tankLineDocId));

    int? birthDate = tank.getBirthDate();
    int? breedingDate = searchModel.computeBreedingDate(birthDate);

    // BUGbroken could tankview here not have the facility set

    return GestureDetector(
      onTap: () {
        // the user has tapped a tank; jump to it
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TankView(
              incomingRackFk: tank.rackFk,
              incomingTankPosition: tank.absolutePosition,
              tankLiveViewModelNoContext: tankViewModel,
              tankLineViewModelNoContext: tanksLineViewModel,
              facilityViewModelNoContext: facilitiesViewModel,
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
                    theTankLineValueItem.label, //BUGfixed want label, not value
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Row(
                children: [
                  Expanded(
                    flex: (searchSelection == cCrossBreedSearch) ? 4:3,
                    child: Text(
                      (searchSelection == cCrossBreedSearch)
                          ? "Cross-breeding date: ${buildDateOfBirth(() => breedingDate)}"
                          : "DOB: ${buildDateOfBirth(() => birthDate)}",
                      style: (searchSelection == cCrossBreedSearch)
                          ? customTextStyle.bodySmallBold
                          : Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "${tank.getNumberOfFish().toString()} fish",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: buildCheckBox(context, "Screen +", tank.getScreenPositive),
                  ),
                  Expanded(
                    flex:2,
                    child: (tank.getSmallTank() == true) ? Text("3L tank",style: Theme.of(context).textTheme.bodySmall) : Text("10L tank",style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Generation: F${(tank.generation.toString())}",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),

                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, bottom: 15.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: chooseGenoType(context,tank),
                  ),
                  const Spacer(flex: 1),
                  Expanded(
                    flex: 3,
                    child: chooseParents(context, tank, tankViewModel, tanksLineViewModel),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void conductSearch(bool withNotify) {
    SearchViewModel searchModel =
        Provider.of<SearchViewModel>(context, listen: false);
    // "" will have a value for tankline and dob searches
    // we search for the tanklineFk not the label (actual tankline)
    searchModel.prepareSearchTankList(
        selectedSingleItem.value,
        searchSelection,
        withNotify); //prepareSearchTankList will call notifylisteners
  }

  Widget searchRadioButton(String searchLabel, int radioBtnValue) {
    // three possible search buttons
    // const cTankLineSearch = 1;
    // const cCrossBreedSearch = 2;
    return Expanded(
      child: RadioListTile<int>(
        title: Text(searchLabel,),
        value:
            radioBtnValue, // this tells us which of the radio buttons we are addressing
        // below gives the value of the radio buttons as a group
        groupValue: searchSelection,
        onChanged: (value) {
          setState(() {
            searchSelection = value;
            conductSearch(
                cNoNotify); // problem, when searchSelection is cross-breed, first parameter should be ignored or set to all
            // when it's tankline, when it's blank, we show no tanklines! only when a tankline is selected do we show it
          });
          // method here needs to disable all three searches and then enable the selected one
        },
        //contentPadding: const EdgeInsets.all(0),
      ),
    );
  }

  List<ValueItem> returnEmptyTankLineValueList() {
    return <ValueItem>[];
  }

  Widget simpleSearchDropdown(SearchViewModel searchModel) {

    SimpleSearchbarSettings searchBarSettings = const SimpleSearchbarSettings(dropdownWidth: 350, hint:"Select a tank line");

    return SearchDropDown(
      listItems: (searchSelection == cTankLineSearch) ?  searchModel.returnTankLinesAsValueItems(): returnEmptyTankLineValueList(),
      onAddItem: addItem,
      addMode: false,
      deleteMode: false,
      updateSelectedItem: updateSelectedItem,
      selectedItem: null,
      searchBarSettings: searchBarSettings,
    );
  }

  Widget dropDown(SearchViewModel searchModel) {
    return simpleSearchDropdown(searchModel);
  }

  List<BarChartGroupData> getBarGroups(SearchViewModel searchModel) {
    List<BarChartGroupData> barGroups = [];

    Color barColor = const Color.fromARGB(255, 165, 254, 206); // same light green as the tank icons are

    searchModel.dobNumberOfFish.forEach((xValue, yValue) {
      barGroups.add(
        BarChartGroupData(
          x: xValue,
          barRods: [
            BarChartRodData(
              toY: yValue.toDouble(),
              color: barColor,
            ),
          ],
        ),
      );
    });
    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    SearchViewModel searchModel = Provider.of<SearchViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(kProgramName),
      ),
      body: Column(
        children: [
          buildOuterLabelHeadlineSmall(context, "Search Tanks"),
          Row(
            children: [
              searchRadioButton('Tanklines', cTankLineSearch),
              searchRadioButton('Cross-breed', cCrossBreedSearch),
            ],
          ),
          Row(
            children: [
              // BUGfixed fixed layout
              Padding(
                padding: const EdgeInsets.only(left: 75.0),
                child: dropDown(searchModel),
              ),
            ],
          ),
          buildOuterLabelHeadlineSmall(context, "Results"),
          SizedBox(
            height: MediaQuery.of(context).size.height *
                ((searchSelection == cTankLineSearch)
                    ? 5
                    : 7) /
                12,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //BUGfixed print the graph only if there are fish selected
              ((searchSelection == cTankLineSearch) && (searchModel.getTotalNumberOfFish > cNoFishSelected))
                  ? RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge,
                  children: <TextSpan>[
                    const TextSpan(text: 'The average age of the', style: TextStyle(fontWeight: FontWeight.normal)),
                    TextSpan(text: ' ${searchModel.getTotalNumberOfFish} fish ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: 'in tankline ${selectedSingleItem.label} is', style: const TextStyle(fontWeight: FontWeight.normal)),
                    TextSpan(text: ' ${(returnTimeNow() - searchModel.getAverageAgeOfFish.toInt()) ~/ kDayInMilliseconds} days', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ): Container(),
            ],
          ),
        const SizedBox(height:30),
          // BUGfixed print the graph only if there are fish selected
          ((searchSelection == cTankLineSearch) && (searchModel.getTotalNumberOfFish > cNoFishSelected))
              ? Expanded(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 5 / 6,
                    child: BarChart(
                      BarChartData(
                        barGroups: getBarGroups(searchModel),
                        titlesData: const FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true, // Show the titles
                              reservedSize: 30,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true, // Show the titles
                              getTitlesWidget: returnDOBTitle,
                              reservedSize: 30,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false, // Show the titles
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false, // Show the titles
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
