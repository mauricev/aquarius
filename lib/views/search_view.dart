import '../views/tanks_view.dart';
import '../view_models/search_viewmodel.dart';
import '../views/consts.dart';
import 'package:flutter/material.dart';
import 'utility.dart';
import 'package:provider/provider.dart';
import '../views/typography.dart';
import '../models/tank_model.dart';

//https://pub.dev/packages/dropdown_button2
// won't search immediately, rejected
//import 'package:dropdown_button2/dropdown_button2.dart';

//import 'package:dropdown_textfield/dropdown_textfield.dart';
//import 'package:dropdown_search/dropdown_search.dart';

//import 'package:flutter_dropdown_plus/dropdown.dart';
//import 'package:flutter_dropdown_plus/dropdown_item.dart';
//import 'package:flutter_dropdown_plus/dropdown_textfield.dart';
//import 'package:drop_down_search_field/drop_down_search_field.dart'; // accepts broken input; scrolls off the edge of the screen

import 'package:custom_searchable_dropdown/custom_searchable_dropdown.dart'; // awful

import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import 'package:fl_chart/fl_chart.dart';

/*class User {
  final String userId;
  final String userName;
  User({required this.userId, required this.userName});
}*/

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

  //final TextEditingController _conDropdownTextField = TextEditingController();

  int? searchSelection = cTankLineSearch;

  /*//List<DropdownItem> _itemList = [];

  final List<String> items = [
    'baseball',
    'basketball',
    'football',
    'golf',
    'tennis',
    'hockey',
    'weightlifting',
    'judo',
  ];
  String? selectedValue;*/
  /*// late SingleValueDropDownController _cnt;

  final TextEditingController _dropdownSearchFieldController =
      TextEditingController();
  //SuggestionsBoxController suggestionBoxController = SuggestionsBoxController();
  static final List<String> fruits = [
    'Apple',
    'Avocado',
    'Banana',
    'Blueberries',
    'Blackberries',
    'Cherries',
    'Grapes',
    'Grapefruit',
    'Guava',
    'Kiwi',
    'Lychee',
    'Mango',
    'Orange',
    'Papaya',
    'Passion fruit',
    'Peach',
    'Pears',
    'Pineapple',
    'Raspberries',
    'Strawberries',
    'Watermelon',
  ];

  List<Map<String, dynamic>> listToSearch = [
    {'name': 'Amir', 'class': 12},
    {'name': 'Raza', 'class': 11},
    {'name': 'Praksh', 'class': 10},
    {'name': 'Nikhil', 'class': 9},
    {'name': 'Sandeep', 'class': 8},
    {'name': 'Tazeem', 'class': 7},
    {'name': 'Najaf', 'class': 6},
    {'name': 'Izhar', 'class': 5},
  ];

  var selected;
  List<Map<String, dynamic>> selectedList = <Map<String, dynamic>>[];*/

  String? _selectedFruit;

  final GlobalKey<SearchDropDownState> singleSearchKey = GlobalKey();

  ValueItem? selectedSingleItem;

  /*final List<ValueItem> listitems = [
    const ValueItem(label: 'Lorenzo', value: 'Lorenzo'),
    const ValueItem(label: 'Teste', value: 'Teste'),
    const ValueItem(label: '3', value: '3'),
    const ValueItem(label: 'one more', value: 'one more2'),
    const ValueItem(label: 'Lorenzo2', value: 'Lorenzo2'),
    const ValueItem(label: 'Teste2', value: 'Teste2'),
    const ValueItem(label: '32', value: '32'),
    const ValueItem(label: 'one more2', value: 'one more22'),
    const ValueItem(label: 'Lorenzo3', value: 'Lorenzo3'),
    const ValueItem(label: 'Teste3', value: 'Teste3'),
    const ValueItem(label: '33', value: '33'),
    const ValueItem(label: 'one more3', value: 'one more23'),
  ];*/
  //List<ValueItem> selectedMultipleItems = [];

  /*void removeItem(ValueItem item) {
    listitems.remove(item);
  }*/

  void addItem(ValueItem item) {
    //listitems.add(item);
  }

  /*void updateSelectedItems(List<ValueItem> newSelectedItems) {
    selectedMultipleItems = newSelectedItems;
  }*/

  void updateSelectedItem(ValueItem? newSelectedItem) {
    selectedSingleItem = newSelectedItem;
    conductSearch(cNotify);
  }

  /*void clearSingleSelection() {
    singleSearchKey.currentState?.resetSelection();
  }*/

  /*static List<String> getSuggestions(String query) {
    List<String> matches = <String>[];
    matches.addAll(fruits);

    matches.retainWhere((s) => s.toLowerCase().contains(query.toLowerCase()));
    return matches;
  }*/

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

    int? birthDate = tank.getBirthDate();
    int? breedingDate = searchModel.computeBreedingDate(birthDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TankView(
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

  // import 'package:dropdown_button2/dropdown_button2.dart';
  /*Widget dropdown_button2() {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          'Select Item',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
        items: items
            .map((item) => DropdownItem(
                  value: item,
                  height: 40,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ))
            .toList(),
        value: selectedValue,
        onChanged: (value) {
          setState(() {
            selectedValue = value;
          });
        },
        buttonStyleData: const ButtonStyleData(
          padding: EdgeInsets.symmetric(horizontal: 16),
          height: 40,
          width: 200,
        ),
        dropdownStyleData: const DropdownStyleData(
          maxHeight: 200,
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: textEditingController,
          searchBarWidgetHeight: 50,
          searchBarWidget: Container(
            height: 50,
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 4,
              right: 8,
              left: 8,
            ),
            child: TextFormField(
              autofocus: true,
              expands: true,
              maxLines: null,
              controller: textEditingController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                hintText: 'Search for an item...',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          noResultsWidget: const Padding(
            padding: EdgeInsets.all(8),
            child: Text('No Item Found!'),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value.toString().contains(searchValue);
          },
        ),
        //This to clear the search value when you close the menu
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            textEditingController.clear();
          }
        },
      ),
    );
  }*/

  // import 'package:dropdown_textfield/dropdown_textfield.dart';
  /*Widget dropdown_textfield() {
    return DropDownTextField(
      // initialValue: "name4",
      controller: _cnt,
      clearOption: true,
      enableSearch: true,
      dropdownColor: Colors.green,
      searchDecoration: const InputDecoration(
          hintText: "enter your custom hint text here"),
      validator: (value) {
        if (value == null) {
          return "Required field";
        } else {
          return null;
        }
      },
      dropDownItemCount: 6,

      dropDownList: const [
        DropDownValueModel(name: 'baseball', value: "value1"),
        DropDownValueModel(
            name: 'football',
            value: "value2",
            toolTipMsg:
            "DropDownButton is a widget that we can use to select one unique value from a set of values"),
        DropDownValueModel(name: 'basketball', value: "value3"),
        DropDownValueModel(
            name: 'judo',
            value: "value4",
            toolTipMsg:
            "DropDownButton is a widget that we can use to select one unique value from a set of values"),
        DropDownValueModel(name: 'soccer', value: "value5"),
        DropDownValueModel(name: 'golf', value: "value6"),
        DropDownValueModel(name: 'tennis', value: "value7"),
        DropDownValueModel(name: 'hockey', value: "value8"),
      ],
      onChanged: (val) {},
    );
  }
*/
  /*_generateItems() {
    List<DropdownItem> list = [];
    for (int i = 1; i <= 10; i++) {
      list.add(DropdownItem(
          id: "$i",
          value: "Item $i",
          data: User(
              userId: "$i",
              userName:
              "User $i") */ /* User class is another data class (use any datatype in data field )*/ /*
      ));
    }
    setState(() {
      _itemList = list;
    });
  }*/

  /*Widget flutter_dropdown_plus() {
    return DropdownTextField(
      controller: _conDropdownTextField,
      list: _itemList,
      hintText: "Item search",
      labelText: "Item search",
    );
  }*/

  /*Widget drop_down_search_field() {
    return GestureDetector(
      onTap: () {
        print("onTap");
        suggestionBoxController.close();
      },
      child: Form(
        child: DropDownSearchFormField(
            autovalidateMode: AutovalidateMode.always,
          textFieldConfiguration: TextFieldConfiguration(
            decoration: const InputDecoration(labelText: 'Select a tankline'),
            controller: _dropdownSearchFieldController,
          ),
          suggestionsCallback: (pattern) {
            print("suggestionsCallback, ${pattern}");
            return getSuggestions(pattern);
          },
          itemBuilder: (context, String suggestion) {
            return ListTile(
              title: Text(suggestion),
            );
          },
          itemSeparatorBuilder: (context, index) {
            return const Divider();
          },
          transitionBuilder: (context, suggestionsBox, controller) {
            return suggestionsBox;
          },
          onSuggestionSelected: (String suggestion) {
            _dropdownSearchFieldController.text = suggestion;
          },
          suggestionsBoxController: suggestionBoxController,
          validator: (value) => value!.isEmpty ? 'Please select a fruit' : null,
          onSaved: (value) {
            _selectedFruit = "Apple";
            print('onSaved');
            // can I force it to save apple?
            if(value != 'Apple') {
              _dropdownSearchFieldController.text = 'Apple';
            }
          },
          displayAllSuggestionWhenTap: false,
        ),
      ),
    );
  }*/

  /* Widget drop_down_search() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSelectedItems: true,
        disabledItemFn: (String s) => s.startsWith('I'),
      ),
      items: const ["Brazil", "Italia (Disabled)", "Tunisia", 'Canada'],
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Menu mode",
          hintText: "country in menu mode",
        ),
      ),
      onChanged: print,
      selectedItem: "Brazil",
    );
  }*/

  /*Widget custom_searchable_dropdown() {
    return CustomSearchableDropDown(
      menuMode: true,
      items: listToSearch,
      label: 'Select Name',
      decoration: BoxDecoration(
          border: Border.all(
              color: Colors.blue
          )
      ),
      prefixIcon:  Padding(
        padding: const EdgeInsets.all(0.0),
        child: Icon(Icons.search),
      ),
      dropDownMenuItems: listToSearch?.map((item) {
        return item['name'];
      })?.toList() ??
          [],
      onChanged: (value){
        if(value!=null)
        {
          selected = value['class'].toString();
        }
        else{
          selected=null;
        }
      },
    );
  }*/

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
    print("returnEmptyTankLineValueList");
    return <ValueItem>[];
  }

  Widget simple_search_dropdown(SearchViewModel searchModel) {
    return SearchDropDown(
      key: singleSearchKey,
      listItems: (searchSelection == cTankLineSearch) ? searchModel.returnTankLinesAsValueItems():returnEmptyTankLineValueList(),
      onAddItem: addItem,
      addMode: false,
      deleteMode: false,
      updateSelectedItem: updateSelectedItem,
      //verifyInputItem: searchModel.rejectBogusTankLineValueItems,
      selectedItem: null,
      hint: "Select a tank line",
      //newValueItem: (input) => ValueItem(label: input, value: input),
    );
  }

  Widget dropDown(SearchViewModel searchModel) {
    //return dropdown_button2();
    //return dropdown_textfield();
    //return flutter_dropdown_plus();
    //return drop_down_search_field();
    //return drop_down_search();
    //return custom_searchable_dropdown(); // awful
    return simple_search_dropdown(searchModel);
  }

  List<BarChartGroupData> getBarGroups(SearchViewModel searchModel) {
    List<BarChartGroupData> barGroups = [];

    Color barColor = Color.fromARGB(255, 165, 254, 206);

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
        SizedBox(height:30),
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
