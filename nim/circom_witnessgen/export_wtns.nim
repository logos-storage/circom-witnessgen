
import std/streams

import pkg/constantine/math/io/io_bigints

import ./types
import ./field

#-------------------------------------------------------------------------------

proc writeBigInt(s: Stream, big: B) = 
  var bytes : seq[byte] = newSeq[byte](32)
  marshal(bytes, big, littleEndian)
  # s.write(bytes)                    # ??!?!! go home Nim, you are drunk
  for b in bytes: s.write(b)

proc writeFelt(s: Stream, x: F) =
  s.writeBigInt(fToBig(x))

#-------------------------------------------------------------------------------

proc writeHeader(s: Stream, witnessLen: int) = 

  # global header
  s.write("wtns")                    # magic word "wtns"
  s.write(uint32(2))                 # version
  s.write(uint32(2))                 # number of sections

  # section 1
  s.write(uint32(1)   )              # section id
  s.write(uint64(0x28))              # section length
  s.write(uint32(32)  )              # 32 bytes per field element
  s.writeBigInt(fieldPrime)          # the field prime
  s.write(uint32(witnessLen))        # number of witness elements

  let nbytes: uint64 = 32 * uint64(witnessLen)
  # section 2
  s.write(uint32(2)  )               # section id
  s.write(nbytes)                    # section length

#-------------------------------------------------------------------------------

proc exportFeltSequence*(filepath: string, values: seq[F]) = 
  var stream = newFileStream(filepath, fmWrite)
  for i in 0..<values.len:
    stream.writeFelt( values[i] )

proc exportWitness*(filepath: string, witness: Witness) = 
  var stream = newFileStream(filepath, fmWrite)
  stream.writeHeader(witness.len) 
  for i in 0..<witness.len:
    stream.writeFelt( witness[i] )

#-------------------------------------------------------------------------------
