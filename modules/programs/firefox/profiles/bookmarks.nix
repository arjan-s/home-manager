{
  config,
  lib,
  pkgs,
  modulePath,
}:

let
  inherit (lib)
    escapeXML
    concatStringsSep
    mkOption
    maintainers
    types
    literalExpression
    ;

  inherit (bookmarkTypes) settingsType;

  bookmarkTypes = import ./bookmark-types.nix { inherit lib; };

  bookmarksFile =
    bookmarks:
    let
      indent = level: lib.concatStringsSep "" (map (lib.const "  ") (lib.range 1 level));

      bookmarkToHTML =
        indentLevel: bookmark:
        ''${indent indentLevel}<DT><A HREF="${escapeXML bookmark.url}" ADD_DATE="1" LAST_MODIFIED="1"${
          lib.optionalString (bookmark.keyword != null) " SHORTCUTURL=\"${escapeXML bookmark.keyword}\""
        }${
          lib.optionalString (
            bookmark.tags != [ ]
          ) " TAGS=\"${escapeXML (concatStringsSep "," bookmark.tags)}\""
        }>${escapeXML bookmark.name}</A>'';

      directoryToHTML = indentLevel: directory: ''
        ${indent indentLevel}<DT>${
          if directory.toolbar then
            ''<H3 ADD_DATE="1" LAST_MODIFIED="1" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks Toolbar''
          else
            ''<H3 ADD_DATE="1" LAST_MODIFIED="1">${escapeXML directory.name}''
        }</H3>
        ${indent indentLevel}<DL><p>
        ${allItemsToHTML (indentLevel + 1) directory.bookmarks}
        ${indent indentLevel}</DL><p>'';

      separatorToHTML = indentLevel: "${indent indentLevel}<HR>";

      itemToHTMLOrRecurse =
        indentLevel: item:
        if item ? "url" then
          bookmarkToHTML indentLevel item
        else if item == "separator" then
          separatorToHTML indentLevel
        else
          directoryToHTML indentLevel item;

      allItemsToHTML =
        indentLevel: bookmarks: lib.concatStringsSep "\n" (map (itemToHTMLOrRecurse indentLevel) bookmarks);

      bookmarkEntries = allItemsToHTML 1 bookmarks;
    in
    pkgs.writeText "bookmarks.html" ''
      <!DOCTYPE NETSCAPE-Bookmark-file-1>
      <!-- This is an automatically generated file.
        It will be read and overwritten.
        DO NOT EDIT! -->
      <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
      <TITLE>Bookmarks</TITLE>
      <H1>Bookmarks Menu</H1>
      <DL><p>
      ${bookmarkEntries}
      </DL>
    '';
in
{
  imports = [
    (pkgs.path + "/nixos/modules/misc/assertions.nix")
    (pkgs.path + "/nixos/modules/misc/meta.nix")
  ];

  # We're currently looking for a maintainer who actively uses bookmarks!
  meta.maintainers = with maintainers; [ kira-bruneau ];

  options = {
    enable = mkOption {
      type = with types; bool;
      default = config.settings != [ ];
      internal = true;
    };

    force = mkOption {
      type = with types; bool;
      default = false;
      description = ''
        Whether to force override existing custom bookmarks.
      '';
    };

    settings = mkOption {
      type = settingsType;
      default = [ ];
      example = literalExpression ''
        [
          {
            name = "wikipedia";
            tags = [ "wiki" ];
            keyword = "wiki";
            url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
          }
          {
            name = "kernel.org";
            url = "https://www.kernel.org";
          }
          "separator"
          {
            name = "Nix sites";
            toolbar = true;
            bookmarks = [
              {
                name = "homepage";
                url = "https://nixos.org/";
              }
              {
                name = "wiki";
                tags = [ "wiki" "nix" ];
                url = "https://wiki.nixos.org/";
              }
            ];
          }
        ]
      '';
      description = ''
        Custom bookmarks.
      '';
    };

    configFile = mkOption {
      type = with types; nullOr path;
      default = if config.enable then bookmarksFile config.settings else null;
      description = ''
        Configuration file to define custom bookmarks.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = config.enable -> config.force;
        message = ''
          Using '${lib.showAttrPath (modulePath ++ [ "settings" ])}' will override all previous bookmarks.
          Enable ${lib.showAttrPath (modulePath ++ [ "force" ])}' to acknowledge this.
        '';
      }
    ];
  };
}
