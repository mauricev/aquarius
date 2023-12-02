class TankLine {
  String? documentId = "bad value"; // this should never say this
  String tankline;

  TankLine({
    this.documentId,
    required this.tankline,
  });

  void updateTankDocumentId (String tankLineDocumentId) {
    documentId = tankLineDocumentId;
  }
}