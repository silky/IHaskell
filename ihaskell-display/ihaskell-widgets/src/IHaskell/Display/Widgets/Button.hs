{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}

module IHaskell.Display.Widgets.Button where

import           Prelude

import           Control.Monad                 (when)
import           Data.Aeson                    (ToJSON, Value (..), object,
                                                toJSON, (.=))
import           Data.HashMap.Strict           as Map
import           Data.IORef
import           Data.Text                     (Text)
import qualified Data.Text                     as T
import           IHaskell.Display
import qualified IHaskell.IPython.Message.UUID as U
import           IHaskell.Eval.Widgets
import           IHaskell.Types (WidgetMethod (..))
import           System.IO.Unsafe              (unsafePerformIO)

-- | ADT for a button
data Button = Button { uuid        :: U.UUID
                     , description :: IORef Text
                     , tooltip     :: IORef Text
                     , disabled    :: IORef Bool
                     , buttonStyle :: IORef ButtonStyle
                     }

-- | Pre-defined button-styles
data ButtonStyle = Primary | Success | Info | Warning | Danger | None

-- | Create a new button
mkButton :: IO Button
mkButton = do
  -- Default properties, with a random uuid
  uuid   <- U.random
  sender <- newIORef Nothing
  desc   <- newIORef ""
  ttip   <- newIORef ""
  dis    <- newIORef False
  sty    <- newIORef None

  let b = Button uuid desc ttip dis sty

  -- Open a comm for this widget, and store it in the kernel state
  widgetSendOpen b $ toJSON ButtonInitData

  -- Initial state update
  widgetSendUpdate b . toJSON . UpdateState . toJSON $ b

  -- REMOVE ME: Let's display it too
  widgetSendView b

  -- Return the button widget
  return b

-- send :: Button -> Value -> IO ()
-- send b v = widgetSendData (uuid b) v

-- -- | Set the button style
-- setButtonStyle :: ButtonStyle -> Button -> IO ()
-- setButtonStyle bst b = do
--   modifyIORef (buttonStyle b) (const bst)
--   send b . toJSON $ UpdateState b

-- -- | Set the button label
-- setButtonLabel :: Text -> Button -> IO ()
-- setButtonLabel txt b = do
--   modifyIORef (description b) (const txt)
--   send b . toJSON $ UpdateState b

-- -- | Set the button tooltip
-- setButtonTooltip :: Text -> Button -> IO ()
-- setButtonTooltip txt b = do
--   modifyIORef (tooltip b) (const txt)
--   send b . toJSON $ UpdateState b

-- -- | Disable the button
-- disableButton :: Button -> IO ()
-- disableButton b = do
--   modifyIORef (disabled b) (const True)
--   send b . toJSON $ UpdateState b

-- -- | Enable the button
-- enableButton :: Button -> IO ()
-- enableButton b = do
--   modifyIORef (disabled b) (const False)
--   send b . toJSON $ UpdateState b

-- -- | Toggle the button
-- toggleButtonStatus :: Button -> IO ()
-- toggleButtonStatus b = do
--   modifyIORef (disabled b) not
--   send b . toJSON $ UpdateState b

-- -- | Get the button style
-- getButtonStyle :: Button -> IO ButtonStyle
-- getButtonStyle = readIORef . buttonStyle

-- -- | Get the button text
-- getButtonText :: Button -> IO Text
-- getButtonText = readIORef . description

-- -- | Get the button tooltip
-- getButtonTooltip :: Button -> IO Text
-- getButtonTooltip = readIORef . tooltip

instance ToJSON ButtonStyle where
  toJSON Primary = "primary"
  toJSON Success = "success"
  toJSON Info    = "info"
  toJSON Warning = "warning"
  toJSON Danger  = "danger"
  toJSON None    = ""

--------------------------------------------------------------------------------
-- To be separated out to another module

data ViewName = ButtonWidget

instance ToJSON ViewName where
  toJSON ButtonWidget = "ButtonView"

data InitData = ButtonInitData

instance ToJSON InitData where
  toJSON ButtonInitData = object [ "model_name"   .= str "WidgetModel"
                                 , "widget_class" .= str "IPython.Button"
                                 ]

--------------------------------------------------------------------------------

instance ToJSON Button where
  toJSON b = object [ "_view_name" .= toJSON ButtonWidget
                    , "visible" .= True
                    , "_css" .= object []
                    , "msg_throttle" .= (3 :: Int)
                    , "disabled" .= get disabled b
                    , "description" .= get description b
                    , "tooltip" .= get tooltip b
                    , "button_style" .= get buttonStyle b
                    ]
    where get x y = unsafePerformIO . readIORef . x $ y

instance IHaskellDisplay Button where
  display b = do
    widgetSendView b
    return $ Display []

instance IHaskellWidget Button where
  -- open widget sender = do
  --   sender . toJSON $ UpdateState widget
  -- comm widget (Object dict1) publisher = do
  --   let key1 = "content" :: Text
  --       key2 = "event"   :: Text
  --       Just (Object dict2) = Map.lookup key1 dict1
  --       Just (String event) = Map.lookup key2 dict2
  --   when (event == "click") $ do
  --     modifyIORef (description widget) (flip T.append ";")
  --     publisher . toJSON $ UpdateState widget

str :: String -> String
str = id
