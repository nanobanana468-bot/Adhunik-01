class Employee {
  final String punchingId;
  final String name;
  final String workerType;
  final String designation;
  final String department;
  final String mobile;
  final DateTime joiningDate;
  final String shift;
  final String? photoPath;
  final String? faceData;
  final bool isActive;

  const Employee({
    required this.punchingId,
    required this.name,
    required this.workerType,
    required this.designation,
    required this.department,
    required this.mobile,
    required this.joiningDate,
    required this.shift,
    this.photoPath,
    this.faceData,
    this.isActive = true,
  });

  Employee copyWith({
    String? punchingId,
    String? name,
    String? workerType,
    String? designation,
    String? department,
    String? mobile,
    DateTime? joiningDate,
    String? shift,
    String? photoPath,
    String? faceData,
    bool? isActive,
  }) {
    return Employee(
      punchingId: punchingId ?? this.punchingId,
      name: name ?? this.name,
      workerType: workerType ?? this.workerType,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      mobile: mobile ?? this.mobile,
      joiningDate: joiningDate ?? this.joiningDate,
      shift: shift ?? this.shift,
      photoPath: photoPath ?? this.photoPath,
      faceData: faceData ?? this.faceData,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'punchingId': punchingId,
      'name': name,
      'workerType': workerType,
      'designation': designation,
      'department': department,
      'mobile': mobile,
      'joiningDate': joiningDate.toIso8601String(),
      'shift': shift,
      'photoPath': photoPath,
      'faceData': faceData,
      'isActive': isActive,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      punchingId: map['punchingId'] ?? '',
      name: map['name'] ?? '',
      workerType: map['workerType'] ?? 'WORKER',
      designation: map['designation'] ?? '',
      department: map['department'] ?? '',
      mobile: map['mobile'] ?? '',
      joiningDate: DateTime.parse(
        map['joiningDate'],
      ),
      shift: map['shift'] ?? '',
      photoPath: map['photoPath'],
      faceData: map['faceData'],
      isActive: map['isActive'] ?? true,
    );
  }
}
