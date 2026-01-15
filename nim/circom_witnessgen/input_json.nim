
import std/sequtils
import std/json
import std/tables

import ./field
import ./types

#-------------------------------------------------------------------------------

proc printInputs*(inputs: Inputs) = 
  for key, list in pairs(inputs):
    echo key
    for y in list:
      echo " - " & fToDecimal(y)

proc flattenNode(node: JsonNode): seq[F] = 
  case node.kind:
    of JString: return @[decimalToF(node.str)]
    of JInt:    return @[int64ToF(node.num)]
    of JArray:  return node.elems.map(flattenNode).concat()
    else:       assert( false, "parseInputJSON: expecting a number or a list (of numbers)" )

proc parseInputJSON*(json: JsonNode): Inputs = 
  doAssert json.kind == JObject
  var stuff: Inputs
  for key, node in pairs(json.fields):
    stuff[key] = flattenNode(node)
  return stuff

proc loadInputJSON*(fpath: string): Inputs = 
  let text = readFile(fpath)
  let json = parseJson(text)
  return parseInputJSON(json)

#-------------------------------------------------------------------------------

