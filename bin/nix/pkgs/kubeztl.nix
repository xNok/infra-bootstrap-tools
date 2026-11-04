{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "kubeztl";
  version = "0.28.4";

  src = fetchFromGitHub {
    owner = "openziti-test-kitchen";
    repo = "kubeztl";
    rev = "bee7d35265a74beb2e35fffb8f926e917c56b7c5";
    hash = "sha256-9o2U0YZYSmq9sny0gt/qSjgTR+xjpfu37dD2DbpuzCc=";
  };

  vendorHash = "sha256-O4N+irJqeS8Tl4Is58K72ciF0zg6z2B6cZa3cggnTOg=";

  # Defaults to ~/.ziti/laptop-client.json and 'k3s', with ZCONFIG / ZITI_SERVICE env overrides
  postPatch = ''
    substituteInPlace main.go \
      --replace-fail 'if configFilePath == "" || serviceName == "" {' \
        'if configFilePath == "" { if env := os.Getenv("ZCONFIG"); env != "" { configFilePath = env } else if home, err := os.UserHomeDir(); err == nil { p := filepath.Join(home, ".ziti", "laptop-client.json"); if _, err := os.Stat(p); err == nil { configFilePath = p } } }; if serviceName == "" { if env := os.Getenv("ZITI_SERVICE"); env != "" { serviceName = env } else { serviceName = "k3s" } }; if false {'
  '';

  # Fix OpenZiti Go SDK nil pointer dereference against modern OpenZiti controllers
  preBuild = ''
    if [ -d vendor ]; then
      chmod -R +w vendor
      substituteInPlace vendor/github.com/openziti/sdk-golang/ziti/ziti.go \
        --replace-fail 'session.Service.ID' '*session.ServiceID'
    fi
  '';

  doCheck = false;

  meta = {
    description = "Zitified kubectl client for OpenZiti zero-trust networks";
    homepage = "https://github.com/openziti-test-kitchen/kubeztl";
    license = lib.licenses.asl20;
    mainProgram = "kubeztl";
  };
}
