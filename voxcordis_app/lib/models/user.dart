class UserModel {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;

  UserModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName ${lastName.toUpperCase()}';
  String get initials =>
      '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        firstName: map['firstName'],
        lastName: map['lastName'],
        email: map['email'],
      );
}
