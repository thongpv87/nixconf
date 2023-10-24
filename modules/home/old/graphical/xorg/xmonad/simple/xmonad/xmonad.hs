{-# LANGUAGE RecordWildCards #-}

module Main where

import Common (MyWorkspace (..), myWorkspaceNames, wsName)
import Config
  ( XMonadConfig (..),
    mkDefaultXMonadConfig,
  )
import KeyBindings (myKeyBindings, myMouseBindings)
import Layouts (namedScratchpads, tallOrFull)
import XMonad
  ( Default (def),
    ManageHook,
    X,
    XConfig (..),
    appName,
    className,
    composeAll,
    doFloat,
    doIgnore,
    doShift,
    mod4Mask,
    resource,
    spawn,
    xmonad,
    (-->),
    (<+>),
    (=?),
  )
import XMonad.Config.Gnome (gnomeConfig)
import XMonad.Hooks.DynamicLog
  ( PP (..),
    filterOutWsPP,
    shorten,
    wrap,
    xmobarBorder,
    xmobarColor,
    xmobarRaw,
    xmobarStrip,
  )
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.ManageDocks (manageDocks)
import XMonad.Hooks.ManageHelpers
  ( doCenterFloat,
    doFullFloat,
    isDialog,
    isFullscreen,
  )
import XMonad.Hooks.RefocusLast (refocusLastLogHook)
import XMonad.Hooks.StatusBar (statusBarProp, withSB)
import XMonad.Hooks.WallpaperSetter
  ( Wallpaper (..),
    WallpaperConf (..),
    WallpaperList (..),
    defWallpaperConf,
    wallpaperSetter,
  )
import XMonad.Layout.Fullscreen (fullscreenManageHook)
import XMonad.Util.Loggers (logTitles)
import XMonad.Util.NamedScratchpad (namedScratchpadManageHook, nsHideOnFocusLoss, scratchpadWorkspaceTag)
import XMonad.Util.SpawnOnce (spawnOnce)

data Terminal
  = Alacritty
  | GnomeTerminal

instance Show Terminal where
  show Alacritty = "alacritty"
  show GnomeTerminal = "gnome-terminal"

-- mkXConfig :: XMonadConfig -> XConfig l
mkXConfig XMonadConfig {..} =
  gnomeConfig
    { terminal = show Alacritty,
      modMask = mod4Mask,
      clickJustFocuses = True,
      focusFollowsMouse = False,
      borderWidth = 2,
      normalBorderColor = "#3b4252",
      focusedBorderColor = "#E57254", -- "#E95065"
      keys = myKeyBindings,
      mouseBindings = myMouseBindings,
      workspaces = myWorkspaceNames,
      manageHook = myManageHook,
      layoutHook = tallOrFull,
      startupHook = myStartupHook,
      logHook = refocusLastLogHook >> nsHideOnFocusLoss namedScratchpads
    }

statusbarPP :: PP
statusbarPP =
  filterOutWsPP [scratchpadWorkspaceTag] $
    def
      { ppSep = blue " | ",
        ppTitleSanitize = xmobarStrip,
        ppCurrent = yellow . xmobarBorder "Top" "#8be9fd" 2 . wsSpacing,
        ppVisible = yellow . wsSpacing,
        ppHidden = white . wsSpacing,
        ppHiddenNoWindows = gray . wsSpacing,
        ppUrgent = red . wrap (yellow "!") (yellow "!"),
        ppOrder = \[ws, l, _, wins] -> [ws, l],
        ppExtras = [logTitles formatFocused formatUnfocused]
      }
  where
    formatFocused = wrap (white "[") (white "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue . ppWindow

    -- Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, gray, yellow :: String -> String
    magenta = xmobarColor "#ff79c6" ""
    blue = xmobarColor "#bd93f9" ""
    white = xmobarColor "#fbfbf8" ""
    yellow = xmobarColor "#f1fa8c" ""
    red = xmobarColor "#ff5555" ""
    gray = xmobarColor "#666666" ""
    lowWhite = xmobarColor "#bbbbbb" ""
    wsSpacing = wrap "" " "

myManageHook :: ManageHook
myManageHook =
  fullscreenManageHook
    <+> manageDocks
    <+> composeAll
      [ className =? "confirm" --> doFloat,
        className =? "file_progress" --> doFloat,
        className =? "dialog" --> doFloat,
        className =? "download" --> doFloat,
        className =? "error" --> doFloat,
        className =? "notification" --> doFloat,
        className =? "pinentry-gtk-2" --> doFloat,
        className =? "splash" --> doFloat,
        className =? "toolbar" --> doFloat,
        className =? "org.gnome.Nautilus" --> doCenterFloat,
        className =? "music-hub" --> doCenterFloat,
        appName =? "Music" --> doCenterFloat,
        className =? "Thunderbird" --> shiftToWs Mail,
        className =? "Gnome-calculator" --> doCenterFloat,
        className =? "Pavucontrol" --> doCenterFloat,
        className =? "Gimp" --> doFloat,
        className =? "Xmessage" --> doCenterFloat,
        resource =? "desktop_window" --> doIgnore,
        resource =? "kdesktop" --> doIgnore,
        className =? "trayer" --> doIgnore,
        isDialog --> doCenterFloat,
        isFullscreen --> doFullFloat
      ]
    <+> namedScratchpadManageHook namedScratchpads
  where
    shiftToWs = doShift . wsName

myStartupHook :: X ()
myStartupHook = do
  -- spawnOnce "trayer --edge top --align right --SetDockType true --SetPartialStrut true  --expand true --width 8 --transparent true --alpha 0 --tint 0x22242b --height 24 --padding 5 --iconspacing 3"
  spawnOnce "systemctl --user start emacs"
  spawn "xrandr --setprovideroutputsource modesetting NVIDIA-0 && autorandr --change"
  spawn "ibus-daemon"
  spawn "xsetroot -cursor_name left_ptr"
  spawn "nm-applet"
  spawn "blueman-applet"
  -- spawn "feh --bg-fill ~/.wallpapers/default"
  spawn "systemctl --user start random-background"

setWallpaper :: X ()
setWallpaper =
  wallpaperSetter
    defWallpaperConf
      { wallpapers = WallpaperList ((\ws -> (ws, WallpaperDir "default")) <$> myWorkspaceNames),
        wallpaperBaseDir = "~/.wallpapers/"
      }

main :: IO ()
main = do
  myConfig <- mkDefaultXMonadConfig
  xmonad
    . ewmh
    -- . withSB (statusBarProp "statusbar" (pure statusbarPP))
    $ mkXConfig myConfig
