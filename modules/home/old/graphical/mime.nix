{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nixconf.old.graphical.mime;
  textEditor = [
    "nvim.desktop"
    "emacsclient.desktop"
    "emacs.desktop"
  ];
  # browser = [ "firefox.desktop" ];
  browser = [ "chromium-browser.desktop" ];
  fileManager = [
    "org.gnome.Nautilus.desktop"
    "org.kde.dolphin.desktop"
  ];
  musicPlayer = [
    "rhythmbox.desktop"
    "org.kde.elisa.desktop"
  ];
  videoPlayer = [ "vlc.desktop" ];
  imageViewer = [
    "vimv.desktop"
    "org.kde.gwenview.desktop"
  ];
  documentViewer = [ "org.kde.okular.desktop" ];
  office = [ "writer.desktop" ];
  postman = [ "Postman.desktop" ];
  terminal = [ "alacritty.desktop" ];
in
{
  options.nixconf.old.graphical.mime = {
    enable = mkOption { default = true; };
  };

  config = mkIf (config.nixconf.old.graphical.enable && cfg.enable) (mkMerge [
    {
      home.packages = with pkgs; [
        vlc
        alacritty
        kdePackages.okular
        rhythmbox
      ];

      xdg = {
        mime.enable = true;

        mimeApps = {
          enable = true;
          associations.added = {
            "x-scheme-handler/terminal" = terminal;
            "x-scheme-handler/file" = fileManager;
            "x-directory/normal" = fileManager;
          };

          defaultApplications = {
            "application/pdf" = documentViewer;
            "application/x-shellscript" = textEditor;
            "application/x-perl" = textEditor;
            "application/json" = textEditor;
            "text/x-readme" = textEditor;
            "text/plain" = textEditor;
            "text/markdown" = textEditor;
            "text/x-csrc" = textEditor;
            "text/x-chdr" = textEditor;
            "text/x-python" = textEditor;
            "text/x-tex" = textEditor;
            "text/x-makefile" = textEditor;
            "inode/directory" = fileManager;
            "x-directory/normal" = fileManager;
            "x-scheme-handler/file" = fileManager;
            "x-scheme-handler/terminal" = terminal;
            "image/bmp" = imageViewer;
            "image/gif" = imageViewer;
            "image/jpeg" = imageViewer;
            "image/jp2" = imageViewer;
            "image/jpeg2000" = imageViewer;
            "image/jpx" = imageViewer;
            "image/png" = imageViewer;
            "image/svg" = imageViewer;
            "image/tiff" = imageViewer;

            "text/english" = textEditor;
            "text/x-c++hdr" = textEditor;
            "text/x-c++src" = textEditor;
            "text/x-java" = textEditor;
            "text/x-moc" = textEditor;
            "text/x-pascal" = textEditor;
            "text/x-tcl" = textEditor;
            "text/x-c" = textEditor;
            "text/x-c++" = textEditor;

            "application/x-ogg" = musicPlayer;
            "application/ogg" = musicPlayer;
            "audio/x-vorbis+ogg" = musicPlayer;
            "audio/vorbis" = musicPlayer;
            "audio/x-vorbis" = musicPlayer;
            "audio/x-scpls" = musicPlayer;
            "audio/x-mp3" = musicPlayer;
            "audio/x-mpeg" = musicPlayer;
            "audio/mpeg" = musicPlayer;
            "audio/x-mpegurl" = musicPlayer;
            "audio/x-flac" = musicPlayer;
            "audio/mp4" = musicPlayer;
            "audio/x-it" = musicPlayer;
            "audio/x-mod" = musicPlayer;
            "audio/x-s3m" = musicPlayer;
            "audio/x-stm" = musicPlayer;
            "audio/x-xm" = musicPlayer;

            "video/ogg" = videoPlayer;
            "video/x-msvideo" = videoPlayer;
            "video/divx" = videoPlayer;
            "video/msvideo" = videoPlayer;
            "video/vnd.divx" = videoPlayer;
            "video/avi" = videoPlayer;
            "video/x-avi" = videoPlayer;
            "video/mpeg" = videoPlayer;
            "video/mpeg-system" = videoPlayer;
            "video/x-mpeg" = videoPlayer;
            "video/x-mpeg2" = videoPlayer;
            "video/x-mpeg-system" = videoPlayer;
            "video/mp4" = videoPlayer;
            "video/mp4v-es" = videoPlayer;
            "video/x-m4v" = videoPlayer;
            "video/quicktime" = videoPlayer;
            "video/webm" = videoPlayer;
            "video/3gp" = videoPlayer;
            "video/3gpp" = videoPlayer;
            "video/3gpp2" = videoPlayer;
            "video/x-anim" = videoPlayer;
            "video/x-nsv" = videoPlayer;
            "video/fli" = videoPlayer;
            "video/flv" = videoPlayer;
            "video/x-flc" = videoPlayer;
            "video/x-fli" = videoPlayer;
            "video/x-flv" = videoPlayer;
            "application/x-flash-video" = videoPlayer;

            "image/jpg" = imageViewer;
            "image/pjpeg" = imageViewer;
            "image/x-3fr" = imageViewer;
            "image/x-adobe-dng" = imageViewer;
            "image/x-arw" = imageViewer;
            "image/x-bay" = imageViewer;
            "image/x-bmp" = imageViewer;
            "image/x-canon-cr2" = imageViewer;
            "image/x-canon-crw" = imageViewer;
            "image/x-cap" = imageViewer;
            "image/x-cr2" = imageViewer;
            "image/x-crw" = imageViewer;
            "image/x-dcr" = imageViewer;
            "image/x-dcraw" = imageViewer;
            "image/x-dcs" = imageViewer;
            "image/x-dng" = imageViewer;
            "image/x-drf" = imageViewer;
            "image/x-eip" = imageViewer;
            "image/x-erf" = imageViewer;
            "image/x-fff" = imageViewer;
            "image/x-fuji-raf" = imageViewer;
            "image/x-iiq" = imageViewer;
            "image/x-k25" = imageViewer;
            "image/x-kdc" = imageViewer;
            "image/x-mef" = imageViewer;
            "image/x-minolta-mrw" = imageViewer;
            "image/x-mos" = imageViewer;
            "image/x-mrw" = imageViewer;
            "image/x-nef" = imageViewer;
            "image/x-nikon-nef" = imageViewer;
            "image/x-nrw" = imageViewer;
            "image/x-olympus-orf" = imageViewer;
            "image/x-orf" = imageViewer;
            "image/x-panasonic-raw" = imageViewer;
            "image/x-pef" = imageViewer;
            "image/x-pentax-pef" = imageViewer;
            "image/x-png" = imageViewer;
            "image/x-ptx" = imageViewer;
            "image/x-pxn" = imageViewer;
            "image/x-r3d" = imageViewer;
            "image/x-raf" = imageViewer;
            "image/x-raw" = imageViewer;
            "image/x-rw2" = imageViewer;
            "image/x-rwl" = imageViewer;
            "image/x-rwz" = imageViewer;
            "image/x-sigma-x3f" = imageViewer;
            "image/x-sony-arw" = imageViewer;
            "image/x-sony-sr2" = imageViewer;
            "image/x-sony-srf" = imageViewer;
            "image/x-sr2" = imageViewer;
            "image/x-srf" = imageViewer;
            "image/x-x3f" = imageViewer;
            "image/webp" = imageViewer;

            "application/vnd.comicbook-rar" = documentViewer;
            "application/vnd.comicbook+zip" = documentViewer;
            "application/x-cb7" = documentViewer;
            "application/x-cbr" = documentViewer;
            "application/x-cbt" = documentViewer;
            "application/x-cbz" = documentViewer;
            "application/x-ext-cb7" = documentViewer;
            "application/x-ext-cbr" = documentViewer;
            "application/x-ext-cbt" = documentViewer;
            "application/x-ext-cbz" = documentViewer;
            "application/x-ext-djv" = documentViewer;
            "application/x-ext-djvu" = documentViewer;
            "image/vnd.djvu+multipage" = documentViewer;
            "application/x-bzdvi" = documentViewer;
            "application/x-dvi" = documentViewer;
            "application/x-ext-dvi" = documentViewer;
            "application/x-gzdvi" = documentViewer;
            "application/x-bzpdf" = documentViewer;
            "application/x-ext-pdf" = documentViewer;
            "application/x-gzpdf" = documentViewer;
            "application/x-xzpdf" = documentViewer;
            "application/postscript" = documentViewer;
            "application/x-bzpostscript" = documentViewer;
            "application/x-gzpostscript" = documentViewer;
            "application/x-ext-eps" = documentViewer;
            "application/x-ext-ps" = documentViewer;
            "application/oxps" = documentViewer;
            "application/vnd.ms-xpsdocument" = documentViewer;
            "application/illustrator" = documentViewer;

            "application/x-7z-compressed" = fileManager;
            "application/x-7z-compressed-tar" = fileManager;
            "application/x-bzip" = fileManager;
            "application/x-bzip-compressed-tar" = fileManager;
            "application/x-compress" = fileManager;
            "application/x-compressed-tar" = fileManager;
            "application/x-cpio" = fileManager;
            "application/x-gzip" = fileManager;
            "application/x-lha" = fileManager;
            "application/x-lzip" = fileManager;
            "application/x-lzip-compressed-tar" = fileManager;
            "application/x-lzma" = fileManager;
            "application/x-lzma-compressed-tar" = fileManager;
            "application/x-tar" = fileManager;
            "application/x-tarz" = fileManager;
            "application/x-xar" = fileManager;
            "application/x-xz" = fileManager;
            "application/x-xz-compressed-tar" = fileManager;
            "application/zip" = fileManager;
            "application/gzip" = fileManager;
            "application/bzip2" = fileManager;

            "text/html" = browser;
            "application/rdf+xml" = browser;
            "pplication/rss+xml" = browser;
            "application/xhtml+xml" = browser;
            "application/xhtml_xml" = browser;
            "application/xml" = browser;
            "x-scheme-handler/http" = browser;
            "x-scheme-handler/https" = browser;
            "x-scheme-handler/about" = browser;

            "application/vnd.oasis.opendocument.text" = office;
            "application/vnd.oasis.opendocument.text-template" = office;
            "application/vnd.oasis.opendocument.text-web" = office;
            "application/vnd.oasis.opendocument.text-master" = office;
            "application/vnd.oasis.opendocument.text-master-template" = office;
            "application/vnd.sun.xml.writer" = office;
            "application/vnd.sun.xml.writer.template" = office;
            "application/vnd.sun.xml.writer.global" = office;
            "application/msword" = office;
            "application/vnd.ms-word" = office;
            "application/x-doc" = office;
            "application/x-hwp" = office;
            "application/rtf" = office;
            "text/rtf" = office;
            "application/vnd.wordperfect" = office;
            "application/wordperfect" = office;
            "application/vnd.lotus-wordpro" = office;
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = office;
            "application/vnd.ms-word.document.macroEnabled.12" = office;
            "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = office;
            "application/vnd.ms-word.template.macroEnabled.12" = office;
            "application/vnd.ms-works" = office;
            "application/vnd.stardivision.writer-global" = office;
            "application/x-extension-txt" = office;
            "application/x-t602" = office;
            "application/vnd.oasis.opendocument.text-flat-xml" = office;
            "application/x-fictionbook+xml" = office;
            "application/macwriteii" = office;
            "application/x-aportisdoc" = office;
            "application/prs.plucker" = office;
            "application/vnd.palm" = office;
            "application/clarisworks" = office;
            "application/x-sony-bbeb" = office;
            "application/x-abiword" = office;
            "application/x-iwork-pages-sffpages" = office;
            "application/x-mswrite" = office;
            "application/x-starwriter" = office;

            "x-scheme-handler/postman" = postman;
          };
        };
      };
    }
  ]);
}
