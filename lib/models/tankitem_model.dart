class TankItem {
  String? documentId = "bad value"; // documentId should never say this
  String tankItemName;
  bool tankItemInUse = true;

  TankItem({
    this.documentId,
    required this.tankItemInUse,
    required this.tankItemName,
  });
}