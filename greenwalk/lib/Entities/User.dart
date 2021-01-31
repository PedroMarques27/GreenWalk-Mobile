class User1 {
  String email, username, password, gender;
  String image_url;

  User1({this.email, this.password, this.username, this.gender, this.image_url});

  factory User1.fromMap(Map<dynamic, dynamic> responseData) {
    return User1(
        password: responseData['password'],
        username: responseData['username'],
        gender: responseData['gender'],
        image_url: responseData['image_url']);
  }

}