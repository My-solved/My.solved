enum Routes {
  splash("/"),
  login("/login"),
  root("/root");

  const Routes(this.path);
  final String path;
}
