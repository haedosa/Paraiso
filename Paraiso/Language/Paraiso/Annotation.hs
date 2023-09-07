{-# LANGUAGE CPP #-}
{-# OPTIONS -Wall #-}
-- | 'Annotation' is a collection of 'Typeable's
-- with which you can annotate each OM node.

module Language.Paraiso.Annotation
    (
     Annotation, add, empty, map, set, weakSet, toList, toMaybe
    ) where

import           Control.Monad
import           Data.Dynamic
import           Data.Typeable (typeOf)
import           Data.Maybe
import           Prelude hiding (map)
import qualified Prelude as P (map)

type Annotation = [Dynamic]

-- | An empty collection.
empty :: Annotation
empty = []

-- | Add an annotation to a collection.
add :: (Typeable a) => a -> Annotation -> Annotation
add x ys = toDyn x : ys

-- | Remove all elements of type @a@ from the collection, and
--   set @x@ as the only member of the type in the collection.
set :: (Typeable a) => a -> Annotation -> Annotation
set x ys = toDyn x : filter ((/= typeOf x) . dynTypeRep) ys

-- | set @x@ as the only member of the type in the collection,
-- only if no annotation of the same type pre-exists.
weakSet :: (Typeable a) => a -> Annotation -> Annotation
weakSet x ys
  | any ((== typeOf x) . dynTypeRep) ys = ys
  | otherwise                           = toDyn x : ys



-- | Extract all annotations of type @a@ from
-- the collection.
toList :: (Typeable a) => Annotation -> [a]
toList =  catMaybes . P.map fromDynamic

-- | Extract the first annotation of the given type,
-- if it exists.
toMaybe :: (Typeable a) => Annotation -> Maybe a
toMaybe = msum . P.map fromDynamic

-- | Map all annotations of type @a@ to type @b@,
-- while leaving the others untouched.
map :: (Typeable a, Typeable b) => (a->b) -> Annotation -> Annotation
map f = P.map (maybeApply f)

maybeApply :: (Typeable a, Typeable b) => (a->b) -> Dynamic -> Dynamic
maybeApply f x =
    case dynApply (toDyn f) x of
      Just y  -> y
      Nothing -> x
