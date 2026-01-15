
import std/bitops

import pkg/constantine/math/arithmetic
import pkg/constantine/math/io/io_bigints
import pkg/constantine/math/io/io_fields
import pkg/constantine/named/properties_fields

import pkg/constantine/platforms/abstractions
#import pkg/constantine/math_arbitrary_precision/arithmetic/limbs_divmod
#import pkg/constantine/math_arbitrary_precision/arithmetic/limbs_divmod_vartime

#-------------------------------------------------------------------------------

type 
  B* = BigInt[254]
  F* = Fr[BN254Snarks]

const zeroB* : B = fromHex( BigInt[254], "0x00" )
const oneB*  : B = fromHex( BigInt[254], "0x01" )

func isZeroB*   (x: B )    : bool = bool(isZero(x))
func isEqualB*  (x, y: B ) : bool = bool(x == y)

const zeroF* : F = fromHex( Fr[BN254Snarks], "0x00" )
const oneF*  : F = fromHex( Fr[BN254Snarks], "0x01" )

func isZeroF*   (x: F )    : bool = bool(isZero(x))
func isNonZeroF*(x: F )    : bool = not isZeroF(x)
func isEqualF*  (x, y: F ) : bool = bool(x == y)
func `===`*     (x, y: F ) : bool = isEqualF(x,y)
func `!==`*     (x, y: F ) : bool = not isEqualF(x,y)

const fieldMask*            : B = fromHex( BigInt[254] , "0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", bigEndian )
const fieldPrime*           : B = fromHex( BigInt[254] , "0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001", bigEndian )
const halfPrimePlus1*       : B = fromHex( BigInt[254] , "0x183227397098d014dc2822db40c0ac2e9419f4243cdcb848a1f0fac9f8000001", bigEndian )
const numberOfBitsAsBigInt* : B = fromHex( BigInt[254] , "0xfe", bigEndian )

#-------------------------------------------------------------------------------

func uintToB*(a: uint): B =
  var y : B
  y.fromUint(a)
  return y

func intToF*(a: int): F =
  var y : F
  y.fromInt(a)
  return y

func int64ToF*(a: int64): F =
  var y : F
  y.fromInt(a)
  return y

func boolToF*(b: bool): F = 
  return (if b: oneF else: zeroF)

func fToBool*(x: F): bool = 
  return isNonZeroF(x)

func bigToF*(big: B): F = 
  var x : F
  x.fromBig( big )
  return x

func fToBig*(x: F): B = 
  return x.toBig()

proc decimalToB*(s: string): B =
  var y: B
  let ok = y.fromDecimal(s)
  return y

proc decimalToF*(s: string): F = 
  return bigToF(decimalToB(s))
  # var y: F
  # let ok = y.fromDecimal(s)     # wtf nim
  # return y

func bigToDecimal*(x: B): string = 
  return toDecimal(x)

func fToDecimal*(x: F): string = 
  return toDecimal(x)

#-------------------------------------------------------------------------------

func mulTruncB(x: B, y: B): B =
  var z: BigInt[512] 
  prod[512,254,254](z,x,y)
  let us: array[8, SecretWord] = z.limbs
  var vs: array[4, SecretWord]
  vs[0] = us[0]
  vs[1] = us[1]
  vs[2] = us[2]
  vs[3] = SecretWord( bitand( uint64(us[3]) , 0x3fffffffffffffff'u64 ) )
  return BigInt[254](limbs: vs)

#[ 

# note: constantine's `divRem_vartime` doesn't seem to function correctly...

func divB*(x: B, y: B): B = 
  if isZeroB(y):
    return zeroB
  else:
    let a: array[4, SecretWord] = x.limbs
    let b: array[4, SecretWord] = y.limbs
    var q: array[4, SecretWord]
    var r: array[4, SecretWord]
    let _ = divRem_vartime(q,r,a,b)
    return BigInt[254](limbs: q)

func modB*(x: B, y: B): B = 
  if isZeroB(y):
    return zeroB
  else:
    let a: array[4, SecretWord] = x.limbs
    let b: array[4, SecretWord] = y.limbs
    var q: array[4, SecretWord]
    var r: array[4, SecretWord]
    let _ = divRem_vartime(q,r,a,b)
    return BigInt[254](limbs: r)

]#

#-------------------------------------------------------------------------------

func negB* (y: B  ): B  =  ( var z : B = zeroB ; z -= y ; return z )

func `+`*[n](x, y: BigInt[n] ): BigInt[n] = ( var z : BigInt[n] = x ; z += y ; return z )
func `-`*[n](x, y: BigInt[n] ): BigInt[n] = ( var z : BigInt[n] = x ; z -= y ; return z )
func `*`*[n](x, y: BigInt[n] ): BigInt[n] = mulTruncB(x,y)

#---------------------------------------

func negF* (y: F  ): F  =  ( var z : F = zeroF ; z -= y ; return z )
func invF* (y: F  ): F  =  ( var z : F = y ; if isNonZeroF(y): z.inv() ; return z )

func `+`*(x, y: F ): F  =  ( var z : F = x ; z += y ; return z )
func `-`*(x, y: F ): F  =  ( var z : F = x ; z -= y ; return z )
func `*`*(x, y: F ): F  =  ( var z : F = x ; z *= y ; return z )
func `/`*(x, y: F ): F  =  ( var z : F = x ; z *= invF(y) ; return z )

func powF*(x: F, y: B): F = 
  var z: F = x
  z.pow_vartime(y)
  return z

#-------------------------------------------------------------------------------

#[

proc divModSanityCheck*() = 
  # let x: B = decimalToB("12345678901234567890666");
  # let y: B = decimalToB("7654321");
  let x: B = decimalToB("18446744073709551618");
  let y: B = decimalToB("7654321");
  let q = divB(x,y)
  let r = modB(x,y)
  echo "x = " & bigToDecimal(x)
  echo "y = " & bigToDecimal(y)
  echo "q = " & bigToDecimal(q)
  echo "r = " & bigToDecimal(r)
  let check = q * y + r
  echo "reconstr = " & bigToDecimal(check)
  echo "ok = " & $(isEqualB(check,x))

]#

