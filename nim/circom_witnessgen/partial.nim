
# compute *partial* witness (based on partially set inputs)

import std/tables
import std/options
#import std/strformat

import ./field
import ./types
import ./graph
import ./semantics

#-------------------------------------------------------------------------------

# the indices here are the witness indices, not the graph node indices!
proc expandPartialInputs(circuitInputs: seq[(string, SignalDescription)] , partialInputs: Inputs): Table[int, F] =
  var table: Table[int, F]
  table[0] = oneF
  for (key, desc) in circuitInputs:
    let k: int = int(desc.length)
    let o: int = int(desc.offset)
    if partialInputs.hasKey(key):
      let list: seq[F] = partialInputs[key]
      assert( list.len == k , "(partial) input signal `" & key & "` has unexpected size" )
      for i in 0..<k:
        table[o + i] = list[i]
        # echo "input value " & (fToDecimal(list[i])) & " at offset " & ($(o+i))
  return table

#-------------------------------------------------------------------------------

func fromOptionF(mbF: Option[F]): F = mbF.get(zeroF)

# please nim, just go home, you are drunk!! (again!!!)
proc fromOptionNode(mbNode: Node[Option[F]] ): Option[Node[F]] =
  case mbNode.kind:

    of Input: return some( Node[F](kind: Input, inp: mbNode.inp) )
    of Const: return some( Node[F](kind: Const, kst: mbNode.kst) )

    of Uno:   
      if isSome(mbNode.uno.arg1):
        return some( fmap[Option[F],F]( fromOptionF , mbNode ) )
      else:
        return none(Node[F])

    of Duo:   
      if isSome(mbNode.duo.arg1) and isSome(mbNode.duo.arg2):
        return some( fmap[Option[F],F]( fromOptionF , mbNode ) )
      else:
        return none(Node[F])

    of Tres:  
      if isSome(mbNode.tres.arg1) and isSome(mbNode.tres.arg2) and isSome(mbNode.tres.arg3):
        return some( fmap[Option[F],F]( fromOptionF , mbNode ) )
      else:
        return none(Node[F])

#---------------------------------------

func lookup[T](table: Table[int,T], idx: int): Option[T] =
  if table.hasKey(idx):
    return some(table[idx])
  else:
    return none(T)

proc maybeEvalNode( partialInputs: Table[int,F] , almost_node: Node[Option[F]] ): Option[F] = 
  let mb_node: Option[Node[F]] = fromOptionNode(almost_node)
  if isSome(mb_node):
    let node: Node[F] = unsafeGet(mb_node)
    case node.kind:
      of Input: return lookup[F]( partialInputs, int(node.inp.idx) )    # we still may have undefined input!
      of Const: return some( evalNode( partialInputs, node ) )
      of Uno:   return some( evalNode( partialInputs, node ) )
      of Duo:   return some( evalNode( partialInputs, node ) )
      of Tres:  return some( evalNode( partialInputs, node ) )
  else:
    return none(F)

#-------------------------------------------------------------------------------

# note: this contains temporary values which are not present in the actual witness
proc runPartialComputation(graph: Graph, partialInputs: Inputs): seq[Option[F]] =

  let sequence      : seq[Node[uint32]]                = graph.nodes
  let graphMeta     : GraphMetaData                    = graph.meta
  let circuitInputs : seq[(string, SignalDescription)] = graphMeta.inputSignals

  let inpTable = expandPartialInputs(circuitInputs, partialInputs)

  var output: seq[Option[F]] = newSeq[Option[F]]( sequence.len )

  for (i, node_orig) in sequence.pairs():
    let node: Node[Option[F]] = fmap[uint32,Option[F]]( proc (idx: uint32): Option[F] = output[int(idx)] , node_orig )
    output[i] = maybeEvalNode( inpTable , node )
  
  return output

proc generatePartialWitness*(graph: Graph, inputs: Inputs): PartialWitness =
  let mapping: seq[uint32] = graph.meta.witnessMapping.mapping
  let pre_witness = runPartialComputation(graph, inputs)
  var output: seq[Option[F]] = newSeq[Option[F]](mapping.len)
  for (j, idx) in mapping.pairs():
    output[j] = pre_witness[int(idx)]

  let full = mapping.len
  let cnt  = countSome(output)
  echo "full witness size = " & $full
  echo "computed values   = " & $cnt
  echo "unknown values    = " & $(full-cnt)

  return output

#-------------------------------------------------------------------------------
