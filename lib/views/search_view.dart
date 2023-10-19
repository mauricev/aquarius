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
  const SearchView({Key? key}) : super(key: key);

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController controllerForSearch = TextEditingController();
  final TextEditingController textEditingController = TextEditingController();

  int? searchSelection = cTankLineSearch;

  final GlobalKey<SearchDropDownState> singleSearchKey = GlobalKey();

  ValueItem? selectedSingleItem;

  void addItem(ValueItem item) {
  }

  void updateSelectedItem(ValueItem? newSelectedItem) {
    selectedSingleItem = newSelectedItem;
    conductSearch(cNotify);
  }

  @override
  void initState() {
    //_cnt = SingleValueDropDownController();
    //_generateItems();
    super.initState();
  }

  @override
  void dispose() {
    controllerForSearch.dispose();
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
    // we will build a container of items;
    // must be tappable.
    // we need more info; we need the facility, rack and document id to pass onto the other controller
    // what will display
    // 1) tankline, 2) dob 3) smalltank 4) screen positive, 5) generation, 6)

    SearchViewModel searchModel = Provider.of<SearchViewModel>(context);

    TanksViewModel tankViewModel =
    Provider.of<TanksViewModel>(context, listen: false);

    int? birthDate = tank.getBirthDate();
    int? breedingDate = searchModel.computeBreedingDate(birthDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TankView(
              incomingRackFk: tank.rackFk,
              incomingTankPosition: tank.absolutePosition,
              tankViewModelNoContext: tankViewModel,
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
                    child: buildCheckBox(context, "Screen Positive", tank.getScreenPositive),
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
                  const Spacer(flex: 1),
                ],
              )
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
    searchModel.prepareSearchTankList(
        selectedSingleItem?.label ?? "",
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
    return SearchDropDown(
      key: singleSearchKey,
      listItems: (searchSelection == cTankLineSearch) ? searchModel.returnTankLinesAsValueItems():returnEmptyTankLineValueList(),
      onAddItem: addItem,
      addMode: false,
      deleteMode: false,
      updateSelectedItem: updateSelectedItem,
      selectedItem: null,
      hint: "Select a tank line",
    );
  }

  Widget dropDown(SearchViewModel searchModel) {
    //return dropdown_button2();
    //return dropdown_textfield();
    //return flutter_dropdown_plus();
    //return drop_down_search_field();
    //return drop_down_search();
    //return custom_searchable_dropdown(); // awful
    return simpleSearchDropdown(searchModel);
  }

  List<BarChartGroupData> getBarGroups(SearchViewModel searchModel) {
    List<BarChartGroupData> barGroups = [];

    Color barColor = const Color.fromARGB(255, 165, 254, 206);

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
              Expanded(
                flex: 2,
                child: dropDown(searchModel),
              ),
              expandedFlex1(),
              expandedFlex1(),
            ],
          ),
          buildOuterLabelHeadlineSmall(context, "Results"),
          SizedBox(
            height: MediaQuery.of(context).size.height *
                (((searchSelection == cTankLineSearch) &&
                        (selectedSingleItem != null))
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
              ((searchSelection == cTankLineSearch) &&
                      (selectedSingleItem != null))
                  ? RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge,
                  children: <TextSpan>[
                    const TextSpan(text: 'The average age of the', style: TextStyle(fontWeight: FontWeight.normal)),
                    TextSpan(text: ' ${searchModel.getTotalNumberOfFish} fish ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: 'in tankline ${selectedSingleItem?.label ?? ""} is', style: const TextStyle(fontWeight: FontWeight.normal)),
                    TextSpan(text: ' ${(returnTimeNow() - searchModel.getAverageAgeOfFish.toInt()) ~/ kDayInMilliseconds} days', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ): Container(),
            ],
          ),
        const SizedBox(height:30),
          ((searchSelection == cTankLineSearch) && (selectedSingleItem != null))
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
