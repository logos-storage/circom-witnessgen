
# some more types (other than the graph type)

import std/options
import std/tables

import ./field

#-------------------------------------------------------------------------------

type
  Inputs*         = Table[string, seq[F]]

  Witness*        = seq[F]
  WitnessMask*    = seq[bool]
  PartialWitness* = seq[Option[F]]

#-------------------------------------------------------------------------------

func countMask*(mask: WitnessMask): int = 
  var cnt = 0
  for b in mask:
    if b:
      cnt += 1
  return cnt

func countSome*[T](maybes: seq[Option[T]]): int = 
  var cnt = 0
  for mb in maybes:
    if isSome(mb):
      cnt += 1
  return cnt

#-------------------------------------------------------------------------------
