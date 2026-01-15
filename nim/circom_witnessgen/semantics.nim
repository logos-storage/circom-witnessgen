
import std/bitops
import std/tables

import pkg/constantine/math/arithmetic
import pkg/constantine/math/io/io_bigints

import ./graph
import ./field

#-------------------------------------------------------------------------------

func bigIntBitwiseComplement(x: B): B =
  var bytes1 : seq[byte] = newSeq[byte](32)
  var bytes2 : seq[byte] = newSeq[byte](32)
  marshal(bytes1, x, littleEndian)
  for i in 0..<32: 
    bytes2[i] = bitxor( bytes1[i] , 0xff )
  var output : B
  unmarshal(output, bytes2, littleEndian)
  return output

func bigIntBitwiseAnd(x, y: B): B =
  var bytes1 : seq[byte] = newSeq[byte](32)
  var bytes2 : seq[byte] = newSeq[byte](32)
  var bytes3 : seq[byte] = newSeq[byte](32)
  marshal(bytes1, x, littleEndian)
  marshal(bytes2, y, littleEndian)
  for i in 0..<32: 
    bytes3[i] = bitand( bytes1[i] , bytes2[i] )
  var output : B
  unmarshal(output, bytes3, littleEndian)
  return output

func bigIntBitwiseOr(x, y: B): B =
  var bytes1 : seq[byte] = newSeq[byte](32)
  var bytes2 : seq[byte] = newSeq[byte](32)
  var bytes3 : seq[byte] = newSeq[byte](32)
  marshal(bytes1, x, littleEndian)
  marshal(bytes2, y, littleEndian)
  for i in 0..<32: 
    bytes3[i] = bitor( bytes1[i] , bytes2[i] )
  var output : B
  unmarshal(output, bytes3, littleEndian)
  return output

func bigIntBitwiseXor(x, y: B): B =
  var bytes1 : seq[byte] = newSeq[byte](32)
  var bytes2 : seq[byte] = newSeq[byte](32)
  var bytes3 : seq[byte] = newSeq[byte](32)
  marshal(bytes1, x, littleEndian)
  marshal(bytes2, y, littleEndian)
  for i in 0..<32: 
    bytes3[i] = bitxor( bytes1[i] , bytes2[i] )
  var output : B
  unmarshal(output, bytes3, littleEndian)
  return output

#-------------------------------------------------------------------------------

func applyFieldMask(big : B) : F =
  return bigToF( bigIntBitwiseAnd( fieldMask, big ) )

func fieldComplement(x: F): F = 
  let big1 = fToBig(x)
  let comp = bigIntBitwiseComplement( big1 ) 
  return applyFieldMask(comp)

#-------------------------------------------------------------------------------

func fieldNegateB(x : B): B = 
  if bool(isZero(x)):
    return x
  else:
    return fieldPrime - x

func smallShiftRightB(x: B, k: int): B = 
  if (k == 0):
    return x
  elif (k < 64):
    var y : B = x
    y.shiftRight(k)
    return y
  else:
    # more constantine limitations...
    var y : B = x
    y.shiftRight(63)
    return smallShiftRightB(y, k-63)

func shiftLeftF*(  x: F, kbig: B ) : F
func shiftRightF*( x: F, kbig: B ) : F 
  
func shiftLeftF*( x: F, kbig: B ) : F = 
  if (isZeroB(kbig)):
    return x
  elif bool(kbig >= halfPrimePlus1):
    return shiftRightF( x , fieldNegateB(kbig) )
  elif bool(kbig > numberOfBitsAsBigInt):
    return zeroF
  else:
    let k = int(kbig.limbs[0])
    var y = fToBig(x)
    for i in 0..<k:                 # constantine has `shiftRight` but no `shiftLeft`, WTF seriously
      let _ = y.double()
    return applyFieldMask( y )

func shiftRightF*( x: F, kbig: B ) : F = 
  if (isZeroB(kbig)):
    return x                                  # WTF constantine ?!?!?!
  if bool(kbig >= halfPrimePlus1):
    return shiftLeftF( x , fieldNegateB(kbig) )
  elif bool(kbig > numberOfBitsAsBigInt):
    return zeroF
  else:
    let k = int(kbig.limbs[0])
    var y : B = fToBig(x)
    return bigToF( smallShiftRightB( y , k ) )

#[
proc shiftSanityCheck*() = 
  let x:  F = intToF(12345678903)
  let k:  B = uintToB(8)
  let nk: B = fieldPrime - k
  echo fToDecimal( shiftLeftF( x,k)  )
  echo fToDecimal( shiftRightF(x,k)  )
  echo fToDecimal( shiftLeftF( x,nk) )
  echo fToDecimal( shiftRightF(x,nk) )
  let x2:  F = decimalToF("21051029818893485635560069555360071249585393429228441201546820650188605022495")   # intToF(12345678903)
  let k2:  B = uintToB(0)
  echo fToDecimal( shiftLeftF( x2,k2)  )
  echo fToDecimal( shiftRightF(x2,k2)  )
  let x3:  F = decimalToF("21051029818893485635560069555360071249585393429228441201546820650188605022495")   # intToF(12345678903)
  let k3:  B = uintToB(100)
  echo fToDecimal( shiftRightF(x3,k3)  )
]#

#-------------------------------------------------------------------------------

func evalUnoOpNode*(op: UnoOp, x: F): F =  
  case op:
    of Neg:  return negF(x)
    of Id:   return x
    of LNot: return boolToF( not (fToBool x) )
    of Bnot: return fieldComplement(x)

func evalDuoOpNode*(op: DuoOp, x: F, y: F): F =  
  case op:
    of Mul:  return x * y
    of Div:  return if isZeroF(y): zeroF else: x / y
    of Add:  return x + y
    of Sub:  return x - y
    of Pow:  return powF(x, fToBig(y)) 
    # of Idiv: return bigToF( divB( fToBig(x) , fToBig(y) ) ) 
    # of Mod:  return bigToF( modB( fToBig(x) , fToBig(y) ) ) 
    of Idiv: assert( false, "Idiv: not yet implemented" )
    of Mod:  assert( false, "Mod: not yet implemented"  )
    of Eq:   return boolToF( x === y )
    of Neq:  return boolToF( not (x === y) )
    of Lt:   return boolToF( bool( fToBig(x) <  fToBig(y) ) )
    of Gt:   return boolToF( bool( fToBig(x) >  fToBig(y) ) )
    of Leq:  return boolToF( bool( fToBig(x) <= fToBig(y) ) )
    of Geq:  return boolToF( bool( fToBig(x) >= fToBig(y) ) )
    of Land: return boolToF( fToBool(x) and fToBool(y) )
    of Lor:  return boolToF( fToBool(x) or  fToBool(y) )
    of Shl:  return shiftLeftF(  x , fToBig(y) )
    of Shr:  return shiftRightF( x , fToBig(y) )
    of Bor:  return bigToF( bigIntBitwiseOr(  fToBig(x) , fToBig(y) ) )
    of Band: return bigToF( bigIntBitwiseAnd( fToBig(x) , fToBig(y) ) )
    of Bxor: return bigToF( bigIntBitwiseXor( fToBig(x) , fToBig(y) ) )

func evalTresOpNode*(op: TresOp, x: F, y: F, z: F): F =  
  case op:
    of TernCond:
      return (if fToBool(x): y else: z)

#-------------------------------------------------------------------------------

func evalNode*( inputs: Table[int,F] , node: Node[F] ): F = 
  case node.kind:
    of Input: return inputs[int(node.inp.idx)]
    of Const: return fromBigUInt(node.kst.bigVal)
    of Uno:   return evalUnoOpNode( node.uno.op , node.uno.arg1 )
    of Duo:   return evalDuoOpNode( node.duo.op , node.duo.arg1 , node.duo.arg2 )
    of Tres:  return evalTresOpNode(node.tres.op, node.tres.arg1, node.tres.arg2, node.tres.arg3 )

#-------------------------------------------------------------------------------
