class TankLine {
  String? documentId = "bad value"; // documentId should never say this
  String tankLine;
  bool tankLineInUse = true;

  TankLine({
    this.documentId,
    required this.tankLineInUse,
    required this.tankLine,
  });
}