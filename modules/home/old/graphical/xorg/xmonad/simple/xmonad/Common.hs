module Common (MyWorkspace (..), myWorkspaceNames, wsName) where

data MyWorkspace
  = Cmd
  | Web
  | Code
  | Doc
  | Tasks
  | Mail
  | Media
  | Remote
  | Float
  deriving (Show, Eq, Enum, Bounded)

wsName :: MyWorkspace -> String
wsName Cmd = "\62601"
wsName Web = "\63288"
wsName Code = "\58911"
wsName Doc = "\57995"
wsName Tasks = "\61953"
wsName Mail = "\63215"
wsName Media = "\xf001"
wsName Remote = "\63074"
wsName Float = "\xf313"

myWorkspaces :: [MyWorkspace]
myWorkspaces = [minBound :: MyWorkspace .. maxBound]

myWorkspaceNames :: [String]
myWorkspaceNames = wsName <$> myWorkspaces
