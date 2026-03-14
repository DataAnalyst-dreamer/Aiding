# To learn more about how to use Nix to configure your environment
# see: https://firebase.google.com/docs/studio/customize-workspace
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.jdk21
    pkgs.unzip
    # Linux 데스크톱 Flutter 빌드에 필요한 패키지
    pkgs.cmake
    pkgs.ninja
    pkgs.gtk3
    pkgs.pkg-config
  ];
  # Sets environment variables in the workspace
  # TMPDIR을 /home으로 설정 - /ephemeral 디스크 공간 부족 문제 우회
  env = {
    TMPDIR = "/home/user/tmp";
  };
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];
    workspace = {
      # Runs when a workspace is first created with this `dev.nix` file
      onCreate = { };
      # To run something each time the workspace is (re)started, use the `onStart` hook
      onStart = {
        # 임시 디렉토리 생성
        create-tmp = "mkdir -p /home/user/tmp";
      };
    };
    # Enable previews and customize configuration
    previews = {
      enable = true;
      previews = {
        # 웹 미리보기만 사용 (안드로이드는 디스크 공간 부족으로 비활성화)
        web = {
          command = ["flutter" "run" "--machine" "-d" "web-server" "--web-hostname" "0.0.0.0" "--web-port" "$PORT"];
          manager = "flutter";
        };
      };
    };
  };
}
