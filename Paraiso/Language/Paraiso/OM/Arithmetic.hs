{-# LANGUAGE CPP, NoImplicitPrelude #-}
{-# OPTIONS -Wall #-}
module Language.Paraiso.OM.Arithmetic
    (
     Arity(..), arityI, arityO,
     Operator(..)
    ) where

import           NumericPrelude hiding (Ordering(..), Eq(..), Ord(..))
import qualified NumericPrelude as P
import qualified Data.Typeable as Typeable

class Arity a where
  arity :: a -> (Int, Int)

arityI, arityO :: (Arity a) => a -> Int
arityI = fst.arity
arityO = snd.arity

data Operator =
  Identity |
  Add |
  Sub |
  Neg |
  Mul |
  Div |
  --DivRm |   TODO
  --DivRp |
  Mod |
  DivMod |
  Inv |
  Not |
  And |
  Or |
  EQ |
  NE |
  LT |
  LE |
  GT |
  GE |
  Max |
  Min |
  Abs |
  Signum |
  Select |
  -- | x^y where y is an integer
  Ipow |
  -- | x^y where y is real number
  Pow |
  Madd |
  Msub |
  Nmadd |
  Nmsub |
  Sqrt |
  Exp |
  Log |
  Sin |
  Cos |
  Tan |
  Asin |
  Acos |
  Atan |
  Atan2 |
  Sincos |
  Cast Typeable.TypeRep
  deriving (P.Eq, P.Ord, P.Show)

instance Arity Operator where
  arity a = case a of
    Identity -> (1,1)
    Add -> (2,1)
    Sub -> (2,1)
    Neg -> (1,1)
    Mul -> (2,1)
    Div -> (2,1)
    Mod -> (2,1)
    DivMod -> (2,2)
    Inv -> (1,1)
    Not -> (1,1)
    And -> (2,1)
    Or -> (2,1)
    EQ -> (2,1)
    NE -> (2,1)
    LT -> (2,1)
    LE -> (2,1)
    GT -> (2,1)
    GE -> (2,1)
    Max -> (2,1)
    Min -> (2,1)
    Abs -> (1,1)
    Signum -> (1,1)
    Select -> (3,1)
    Ipow -> (2,1)
    Pow -> (2,1)
    Madd -> (3,1)
    Msub -> (3,1)
    Nmadd -> (3,1)
    Nmsub -> (3,1)
    Sqrt -> (1,1)
    Exp -> (1,1)
    Log -> (1,1)
    Sin -> (1,1)
    Cos -> (1,1)
    Tan -> (1,1)
    Asin -> (1,1)
    Acos -> (1,1)
    Atan -> (1,1)
    Atan2 -> (2,1)
    Sincos -> (1,2)
    Cast _ -> (1,1)
