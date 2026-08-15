class SavedPassword {
  final int? id;
  final String site;
  final String username;
  final String password;

  SavedPassword({
    this.id,
    required this.site,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'site': site,
        'username': username,
        'password': password,
      };

  factory SavedPassword.fromMap(Map<String, dynamic> map) => SavedPassword(
        id: map['id'] as int?,
        site: map['site'] as String,
        username: map['username'] as String,
        password: map['password'] as String,
      );
}