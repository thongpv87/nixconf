{-# LANGUAGE RecordWildCards  #-}
module Config where

import Graphics.X11.Xlib.Types
import Graphics.X11.Xlib.Display

data DisplayConfig = DisplayConfig
    { dcPrimary :: !Bool
    , dcEnable :: !Bool
    , dcOutput :: !String
    , dcPosX :: !Integer
    , dcPosY :: !Integer
    , dcWidth :: !Integer
    , dcHeight :: !Integer
    } deriving (Show, Eq)

data XMobarPlacement
    = OnAllDisplay
    | OnPrimaryDisplay
    | OnSecondaryDisplay
    deriving (Show, Eq, Enum, Bounded)

data XMobarTheme
    = XMobarThemeSimple
    deriving (Show, Eq)

data DisplayMode
    = DisplayOff
    | DisplayOn
    deriving (Show)

data DualDisplayMode
    = IntegratedDisplayOnly
    | ExternalDisplayOnly
    | DualDisplayVertical
    | DualDisplayHorizontal
    deriving (Show, Eq)

data XMonadConfig = XMonadConfig
    { xcDisplay :: !Display
    , xcXMobarPlacement :: !XMobarPlacement
    , xcXMobarTheme :: !XMobarTheme
    , xcDualDisplayMode :: !DualDisplayMode
    } deriving (Show)

mkDefaultXMonadConfig :: IO XMonadConfig
mkDefaultXMonadConfig = do
    xcDisplay <- openDisplay ""
    let xcXMobarPlacement = OnAllDisplay
        xcXMobarTheme = XMobarThemeSimple
        xcDualDisplayMode = IntegratedDisplayOnly
    pure $ XMonadConfig {..}
