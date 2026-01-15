
# figure out the part of the witness which depends on a given set of inputs
#
# this is intended to be used when a significant part of the witness is
# either constant or rarely changes, so a part of the proof generation
# can be precomputed

#-------------------------------------------------------------------------------

import std/sequtils
import std/sets

import ./types
import ./graph

#-------------------------------------------------------------------------------

func isElem[T](what: T, list: seq[T]): bool = count(list,what) > 0

# note: the resulting set contains the _normal_ witness indices of the _unchanging_ inputs
# these indices are _different_ from the graph indices, because normally there 
# are much more graph nodes than witness elements
proc unchangingInputIndices(circuitInputs: seq[(string, SignalDescription)], unchanging: seq[string]): HashSet[int] =
  var table: HashSet[int]
  incl(table, 0)           # index 0 is constant 1, it never changes
  for (key, desc) in circuitInputs:
    if isElem(key,unchanging):
      let k: int = int(desc.length)
      let o: int = int(desc.offset)
      for i in 0..<k:
        incl(table, o + i)
  return table

#-------------------------------------------------------------------------------

func symbolicEvalNode( inputs: HashSet[int] , node: Node[bool] ): bool = 
  case node.kind:
    of Input: return contains(inputs, int(node.inp.idx))
    of Const: return true
    of Uno:   return node.uno.arg1 
    of Duo:   return (node.duo.arg1 and node.duo.arg2)
    of Tres:  return (node.tres.arg1 and node.tres.arg2 and node.tres.arg3)

#-------------------------------------------------------------------------------

# this returns an bool for each graph node 
proc runSymbolicComputation(graph: Graph, unchanging: seq[string]): seq[bool] =

  let sequence     : seq[Node[uint32]]  = graph.nodes
  let graphMeta    : GraphMetaData      = graph.meta
  var markedInputs : HashSet[int]       = unchangingInputIndices(graphMeta.inputSignals, unchanging)

  var output: seq[bool] = newSeq[bool]( sequence.len )

  for (i, node_orig) in sequence.pairs():
    let node: Node[bool] = fmap[uint32,bool]( proc (idx: uint32): bool = output[int(idx)] , node_orig )
    output[i] = symbolicEvalNode( markedInputs , node )

  return output

proc calcWitnessMask*(graph: Graph, unchanging: seq[string]): WitnessMask =
 
  let mapping: seq[uint32] = graph.meta.witnessMapping.mapping
  let pre_witness = runSymbolicComputation(graph, unchanging)
  var mask: seq[bool] = newSeq[bool](mapping.len)
  for (j, idx) in mapping.pairs():
    mask[j] = pre_witness[int(idx)]

  let full = mapping.len
  let cnt  = countMask(mask)
  echo "witness size = " & $full
  echo "unchanging   = " & $cnt
  echo "remaining    = " & $(full-cnt)

  return mask

#-------------------------------------------------------------------------------

