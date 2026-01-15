
import std/options

import circom_witnessgen/field
# import circom_witnessgen/div_mod

import circom_witnessgen/types
import circom_witnessgen/load
import circom_witnessgen/input_json
import circom_witnessgen/dependencies
import circom_witnessgen/witness
import circom_witnessgen/partial
import circom_witnessgen/export_wtns

#-------------------------------------------------------------------------------

const graph_file:   string = "./tmp/rln_main.graph"
const input_file:   string = "./tmp/input.json"
const partial_file: string = "./tmp/partial.json"
const wtns_file:    string = "./tmp/output.wtns"

const unchanging_inputs: seq[string] = @["secret_key","msg_limit","merkle_root","leaf_idx","merkle_path"]

#-------------------------------------------------------------------------------

#[
when isMainModule:

  debugDivMod()  
  # divModSanityCheck()
]#

when isMainModule:

  echo "\nloading in " & graph_file
  let gr = loadGraph(graph_file)
  # echo $gr
  echo $gr.meta.inputSignals

  echo "\ncalculating witness mask"
  let mask = calcWitnessMask(gr, unchanging_inputs)
  echo $countMask(mask) & " filled out of " & $(mask.len)

  echo "\nloading in " & partial_file
  let partial_inp = loadInputJSON(partial_file) 
  # printInputs(partial_inp)

  echo "\ngenerating partial witness"
  let partial_wtns = generatePartialWitness(gr, partial_inp)
  let cnt = countSome(partial_wtns)
  echo $cnt & " filled out of " & $(partial_wtns.len)

  echo "\nloading in " & input_file
  let inp = loadInputJSON(input_file) 
  # printInputs(inp)

  echo "\ngenerating witness"
  let wtns = generateWitness( gr, inp )
  exportWitness(wtns_file, wtns)

  echo "\ncomparing partial and full witness"
  var ok = true
  for i in 0..<wtns.len:
    if isSome(partial_wtns[i]):
      let old_val = wtns[i]
      let new_val = partial_wtns[i].unsafeGet()
      if old_val !== new_val:
        if ok:
          echo "first witness index disagreeing = " & $i        
          echo " - full    = " & fToDecimal(old_val)
          echo " - partial = " & fToDecimal(new_val)
        ok = false
  if ok:
    echo "OK."
  else:
    echo "FAILED!"


#-------------------------------------------------------------------------------

