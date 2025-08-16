class Buyer {
  final int id;
  final int orderNo;
  final String companyName;
  final String? country;
  final String? shipmentDate;
  final String? packing;
  final String? contactPerson;

  Buyer({
    required this.id,
    required this.orderNo,
    required this.companyName,
    this.country,
    this.shipmentDate,
    this.packing,
    this.contactPerson,
  });

  factory Buyer.fromMap(Map<String, dynamic> map) {
    return Buyer(
      id: map['id'] ?? 0,
      orderNo: map['order_no'] ?? 0,
      companyName: map['company_name'] ?? '',
      country: map['country'],
      shipmentDate: map['shipment_date'],
      packing: map['packing'],
      contactPerson: map['contact_person'],
    );
  }
}
