
import std/sugar
import std/tables

import pkg/constantine/math/io/io_bigints

import ./field

#-------------------------------------------------------------------------------

type

  UnoOp* = enum
    Neg,
    Id,
    Lnot,
    Bnot

  DuoOp* = enum
    Mul,
    Div,
    Add,
    Sub,
    Pow,
    Idiv,
    Mod,
    Eq,
    Neq,
    Lt,
    Gt,
    Leq,
    Geq,
    Land,
    Lor,
    Shl,
    Shr,
    Bor,
    Band,
    Bxor

  TresOp* = enum
    TernCond

  BigUInt* = object
    bytes*: seq[byte]

  InputNode* = object
    idx*: uint32

  ConstantNode* = object
    bigVal*: BigUInt

  UnoOpNode*[T]  = object
    op*: UnoOp
    arg1*: T

  DuoOpNode*[T]  = object
    op*: DuoOp
    arg1*: T
    arg2*: T

  TresOpNode*[T] = object 
    op*: TresOp
    arg1*: T
    arg2*: T
    arg3*: T

  NodeKind* = enum Input, Const, Uno, Duo, Tres

  Node*[T] = object
    case kind*: NodeKind
      of Input: inp*:  InputNode
      of Const: kst*:  ConstantNode
      of Uno:   uno*:  UnoOpNode[T]
      of Duo:   duo*:  DuoOpNode[T]
      of Tres:  tres*: TresOpNode[T]

  SignalDescription* = object
    offset*: uint32
    length*: uint32

  WitnessMapping* = object
    mapping*: seq[uint32]

  CircuitInputs* = seq[(string, SignalDescription)]

  Prime* = object
    primeNumber*: BigUInt
    primeName*:   string

  GraphMetaData* = object
    witnessMapping*: WitnessMapping
    inputSignals*:   CircuitInputs  
    prime*: Prime

  Graph* = object
    nodes*: seq[Node[uint32]]
    meta*:  GraphMetaData

#-------------------------------------------------------------------------------

func unwrapBigUInt*(x: BigUInt): seq[byte] = x.bytes

func bigFromBigUInt*(big: BigUInt): B =
  let bytes = unwrapBigUInt(big)
  var buf: seq[byte] = newSeq[byte](32)
  for i, x in bytes.pairs(): 
    buf[i] = x
  var output : B
  unmarshal(output, buf, littleEndian)
  return output

func fromBigUInt*(big: BigUInt): F =
  return bigToF(bigFromBigUInt(big))

#-------------------------------------------------------------------------------

proc fmapUno[S,T]( fun: (S) -> T , node: UnoOpNode[S]): UnoOpNode[T] = 
  UnoOpNode[T]( op: node.op, arg1: fun(node.arg1) )

proc fmapDuo[S,T]( fun: (S) -> T , node: DuoOpNode[S]): DuoOpNode[T] = 
  DuoOpNode[T]( op: node.op, arg1: fun(node.arg1), arg2: fun(node.arg2) )

proc fmapTres[S,T]( fun: (S) -> T , node: TresOpNode[S]): TresOpNode[T] = 
  TresOpNode[T]( op: node.op, arg1: fun(node.arg1), arg2: fun(node.arg2), arg3: fun(node.arg3) )

proc fmap* [S,T]( fun: (S) -> T , node: Node[S]): Node[T] = 
  case node.kind:
    of Input: Node[T](kind: Input , inp:  node.inp )
    of Const: Node[T](kind: Const , kst:  node.kst )
    of Uno:   Node[T](kind: Uno   , uno:  fmapUno( fun, node.uno ) )
    of Duo:   Node[T](kind: Duo   , duo:  fmapDuo( fun, node.duo ) )
    of Tres:  Node[T](kind: Tres  , tres: fmapTres(fun, node.tres) )

#-------------------------------------------------------------------------------

proc showNodeUint32*( node: Node[uint32] ): string = 
  case node.kind:
    of Input: "Input idx=" & ($node.inp.idx)
    of Const: "Const kst=" & bigToDecimal(bigFromBigUInt(node.kst.bigVal))
    of Uno:   "Uno   op=" & ($node.uno.op ) & " | arg1=" & ($node.uno.arg1 )
    of Duo:   "Duo   op=" & ($node.duo.op ) & " | arg1=" & ($node.duo.arg1 ) & " | arg2=" & ($node.duo.arg2 )
    of Tres:  "Tres  op=" & ($node.tres.op) & " | arg1=" & ($node.tres.arg1) & " | arg2=" & ($node.tres.arg2) & " | arg3=" & ($node.tres.arg3)

proc printNodeUint32*( node: Node[uint32] ) = echo showNodeUint32(node)

#-------------------------------------------------------------------------------
