{ pkgs, config, lib, ... }:
with lib;
let cfg = config.nixconf.old.git;
in {
  options.nixconf.old.git = {
    enable = mkOption {
      description = "Enable git";
      type = types.bool;
      default = false;
    };

    userName = mkOption {
      description = "Name for git";
      type = types.str;
      default = "Thong Pham";
    };

    userEmail = mkOption {
      description = "Email for git";
      type = types.str;
      default = "thongpv87@gmail.com";
    };

    signByDefault = mkOption {
      description = "GPG signing key for git";
      type = types.bool;
      default = true;
    };

    allowedSignerFile = mkOption {
      description = "Allowed ssh file for signing";
      type = types.str;
      default = "";
    };
  };

  config = mkIf (cfg.enable) {
    programs.git = {
      enable = true;
      userName = cfg.userName;
      userEmail = cfg.userEmail;
      extraConfig = {
        # commit.gpgSign = cfg.signByDefault;
        # gpg = {
        #   format = "ssh";
        #   ssh = {
        #     defaultKeyCommand = "${pkgs.openssh}/bin/ssh-add -L";
        #     program = "${pkgs.openssh}/bin/ssh-keygen";
        #     allowedSignersFile = cfg.allowedSignerFile;
        #   };
        # };
        # Use SSH now, don't need credential helper/libsecret
        # credential.helper = "${
        #     pkgs.git.override { withLibsecret = true; }
        #   }/bin/git-credential-libsecret";
        pull.rebase = false;
        # https://blog.nilbus.com/take-the-pain-out-of-git-conflict-resolution-use-diff3/
        # https://stackoverflow.com/questions/27417656/should-diff3-be-default-conflictstyle-on-git
        merge.conflictstyle = "zdiff3";
      };
      aliases = {
        a = "add -p";
        co = "checkout";
        cob = "checkout -b";
        f = "fetch -p";
        c = "commit";
        p = "push";
        ba = "branch -a";
        bd = "branch -d";
        bD = "branch -D";
        d = "diff";
        dc = "diff --cached";
        ds = "diff --staged";
        r = "restore";
        rs = "restore --staged";
        st = "status -sb";

        # reset
        soft = "reset --soft";
        hard = "reset --hard";
        s1ft = "soft HEAD~1";
        h1rd = "hard HEAD~1";

        # logging
        lg =
          "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        plog =
          "log --graph --pretty='format:%C(red)%d%C(reset) %C(yellow)%h%C(reset) %ar %C(green)%aN%C(reset) %s'";
        tlog =
          "log --stat --since='1 Day Ago' --graph --pretty=oneline --abbrev-commit --date=relative";
        rank = "shortlog -sn --no-merges";

        # delete merged branches
        bdm = "!git branch --merged | grep -v '*' | xargs -n 1 git branch -d";
      };
    };
  };
}
