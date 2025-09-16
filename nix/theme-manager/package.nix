{
  lib,
  python3,
}:
python3.pkgs.buildPythonApplication {
  pname = "theme-manager";
  version = "0.1.0";

  src = ./.;
  format = "pyproject";

  nativeBuildInputs = with python3.pkgs; [
    setuptools
    wheel
  ];

  propagatedBuildInputs = with python3.pkgs; [
    pyyaml
  ];

  meta = with lib; {
    description = "Daemon & CLI for managing themes";
    license = licenses.mit;
    maintainers = ["cunbidun"];
    platforms = platforms.all;
  };
}
