/// Local owner binding — never written into a share URL.
library;

class ShareOwnership {
  const ShareOwnership({
    required this.id,
    required this.ownerUserId,
    this.localResultKey,
  });

  final String id;
  final String ownerUserId;
  final String? localResultKey;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUserId': ownerUserId,
        if (localResultKey != null) 'localResultKey': localResultKey,
      };

  factory ShareOwnership.fromJson(Map<String, dynamic> json) {
    return ShareOwnership(
      id: '${json['id']}',
      ownerUserId: '${json['ownerUserId']}',
      localResultKey: json['localResultKey'] as String?,
    );
  }
}
