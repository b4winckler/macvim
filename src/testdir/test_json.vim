" Test for JSON functions.

" JSON requires using utf-8.  Conversion breaks the asserts, therefore set
" 'encoding' to utf-8.
if !has('multi_byte')
  finish
endif
set encoding=utf-8
scriptencoding utf-8

let s:json1 = '"str\"in\\g"'
let s:var1 = "str\"in\\g"
let s:json2 = '"\u0001\u0002\u0003\u0004\u0005\u0006\u0007"'
let s:var2 = "\x01\x02\x03\x04\x05\x06\x07"
let s:json3 = '"\b\t\n\u000b\f\r\u000e\u000f"'
let s:var3 = "\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
let s:json4 = '"\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017"'
let s:var4 = "\x10\x11\x12\x13\x14\x15\x16\x17"
let s:json5 = '"\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u001f"'
let s:var5 = "\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"

" surrogate pair
let s:jsonsp1 = '"\ud83c\udf63"'
let s:varsp1 = "\xf0\x9f\x8d\xa3"
let s:jsonsp2 = '"\ud83c\u00a0"'
let s:varsp2 = "\ud83c\u00a0"

let s:jsonmb = '"s¢cĴgё"'
let s:varmb = "s¢cĴgё"
let s:jsonnr = '1234'
let s:varnr = 1234
if has('float')
  let s:jsonfl = '12.34'
  let s:varfl = 12.34
  let s:jsoninf = 'Infinity'
  let s:varinf = 1.0 / 0.0
  let s:jsonnan = 'NaN'
  let s:varnan = 0.0 / 0.0
endif

let s:jsonl1 = '[1,"a",3]'
let s:varl1 = [1, "a", 3]
let s:jsonl2 = '[1,["a",[],"c"],3]'
let s:jsonl2s = "  [\r1  ,  [  \"a\"  ,  [  ]  ,  \"c\"  ]  ,  3\<Tab>]\r\n"
let s:varl2 = [1, 2, 3]
let l2 = ['a', s:varl2, 'c']
let s:varl2[1] = l2
let s:varl2x = [1, ["a", [], "c"], 3]
let s:jsonl3 = '[[1,2],[1,2]]'
let l3 = [1, 2]
let s:varl3 = [l3, l3]

let s:jsond1 = '{"a":1,"b":"bee","c":[1,2]}'
let s:jsd1 = '{a:1,b:"bee",c:[1,2]}'
let s:vard1 = {"a": 1, "b": "bee","c": [1,2]}
let s:jsond2 = '{"1":1,"2":{"a":"aa","b":{},"c":"cc"},"3":3}'
let s:jsd2 = '{"1":1,"2":{a:"aa",b:{},c:"cc"},"3":3}'
let s:jsond2s = "  { \"1\" : 1 , \"2\" :\n{ \"a\"\r: \"aa\" , \"b\" : {\<Tab>} , \"c\" : \"cc\" } , \"3\" : 3 }\r\n"
let s:jsd2s = "  { \"1\" : 1 , \"2\" :\n{ a\r: \"aa\" , b : {\<Tab>} , c : \"cc\" } , \"3\" : 3 }\r\n"
let s:vard2 = {"1": 1, "2": 2, "3": 3}
let d2 = {"a": "aa", "b": s:vard2, "c": "cc"}
let s:vard2["2"] = d2
let s:vard2x = {"1": 1, "2": {"a": "aa", "b": {}, "c": "cc"}, "3": 3}
let d3 = {"a": 1, "b": 2}
let s:vard3 = {"x": d3, "y": d3}
let s:jsond3 = '{"x":{"a":1,"b":2},"y":{"a":1,"b":2}}'
let s:jsd3 = '{x:{a:1,b:2},y:{a:1,b:2}}'
let s:vard4 = {"key": v:none}
let s:vard4x = {"key": v:null}
let s:jsond4 = '{"key":null}'
let s:jsd4 = '{key:null}'

let s:jsonvals = '[true,false,null,null]'
let s:varvals = [v:true, v:false, v:null, v:null]

func Test_json_encode()
  call assert_equal(s:json1, json_encode(s:var1))
  call assert_equal(s:json2, json_encode(s:var2))
  call assert_equal(s:json3, json_encode(s:var3))
  call assert_equal(s:json4, json_encode(s:var4))
  call assert_equal(s:json5, json_encode(s:var5))

  if has('multi_byte')
    call assert_equal(s:jsonmb, json_encode(s:varmb))
    " no test for surrogate pair, json_encode() doesn't create them.
  endif

  call assert_equal(s:jsonnr, json_encode(s:varnr))
  if has('float')
    call assert_equal(s:jsonfl, json_encode(s:varfl))
    call assert_equal(s:jsoninf, json_encode(s:varinf))
    call assert_equal(s:jsonnan, json_encode(s:varnan))
  endif

  call assert_equal(s:jsonl1, json_encode(s:varl1))
  call assert_equal(s:jsonl2, json_encode(s:varl2))
  call assert_equal(s:jsonl3, json_encode(s:varl3))

  call assert_equal(s:jsond1, json_encode(s:vard1))
  call assert_equal(s:jsond2, json_encode(s:vard2))
  call assert_equal(s:jsond3, json_encode(s:vard3))
  call assert_equal(s:jsond4, json_encode(s:vard4))

  call assert_equal(s:jsonvals, json_encode(s:varvals))

  call assert_fails('echo json_encode(function("tr"))', 'E474:')
  call assert_fails('echo json_encode([function("tr")])', 'E474:')

  silent! let res = json_encode(function("tr"))
  call assert_equal("", res)
endfunc

func Test_json_decode()
  call assert_equal(s:var1, json_decode(s:json1))
  call assert_equal(s:var2, json_decode(s:json2))
  call assert_equal(s:var3, json_decode(s:json3))
  call assert_equal(s:var4, json_decode(s:json4))
  call assert_equal(s:var5, json_decode(s:json5))

  if has('multi_byte')
    call assert_equal(s:varmb, json_decode(s:jsonmb))
    call assert_equal(s:varsp1, json_decode(s:jsonsp1))
    call assert_equal(s:varsp2, json_decode(s:jsonsp2))
  endif

  call assert_equal(s:varnr, json_decode(s:jsonnr))
  if has('float')
    call assert_equal(s:varfl, json_decode(s:jsonfl))
  endif

  call assert_equal(s:varl1, json_decode(s:jsonl1))
  call assert_equal(s:varl2x, json_decode(s:jsonl2))
  call assert_equal(s:varl2x, json_decode(s:jsonl2s))
  call assert_equal(s:varl3, json_decode(s:jsonl3))

  call assert_equal(s:vard1, json_decode(s:jsond1))
  call assert_equal(s:vard2x, json_decode(s:jsond2))
  call assert_equal(s:vard2x, json_decode(s:jsond2s))
  call assert_equal(s:vard3, json_decode(s:jsond3))
  call assert_equal(s:vard4x, json_decode(s:jsond4))

  call assert_equal(s:varvals, json_decode(s:jsonvals))

  call assert_equal(v:true, json_decode('true'))
  call assert_equal(type(v:true), type(json_decode('true')))
  call assert_equal(v:none, json_decode(''))
  call assert_equal(type(v:none), type(json_decode('')))
  call assert_equal("", json_decode('""'))

  call assert_equal({'n': 1}, json_decode('{"n":1,}'))

  call assert_fails('call json_decode("\"")', "E474:")
  call assert_fails('call json_decode("blah")', "E474:")
  call assert_fails('call json_decode("true blah")', "E474:")
  call assert_fails('call json_decode("<foobar>")', "E474:")

  call assert_fails('call json_decode("{")', "E474:")
  call assert_fails('call json_decode("{foobar}")', "E474:")
  call assert_fails('call json_decode("{\"n\",")', "E474:")
  call assert_fails('call json_decode("{\"n\":")', "E474:")
  call assert_fails('call json_decode("{\"n\":1")', "E474:")
  call assert_fails('call json_decode("{\"n\":1,")', "E474:")
  call assert_fails('call json_decode("{\"n\",1}")', "E474:")
  call assert_fails('call json_decode("{-}")', "E474:")

  call assert_fails('call json_decode("[foobar]")', "E474:")
  call assert_fails('call json_decode("[")', "E474:")
  call assert_fails('call json_decode("[1")', "E474:")
  call assert_fails('call json_decode("[1,")', "E474:")
  call assert_fails('call json_decode("[1 2]")', "E474:")

  call assert_fails('call json_decode("[1,,2]")', "E474:")
endfunc

let s:jsl5 = '[7,,,]'
let s:varl5 = [7, v:none, v:none]

func Test_js_encode()
  call assert_equal(s:json1, js_encode(s:var1))
  call assert_equal(s:json2, js_encode(s:var2))
  call assert_equal(s:json3, js_encode(s:var3))
  call assert_equal(s:json4, js_encode(s:var4))
  call assert_equal(s:json5, js_encode(s:var5))

  if has('multi_byte')
    call assert_equal(s:jsonmb, js_encode(s:varmb))
    " no test for surrogate pair, js_encode() doesn't create them.
  endif

  call assert_equal(s:jsonnr, js_encode(s:varnr))
  if has('float')
    call assert_equal(s:jsonfl, js_encode(s:varfl))
    call assert_equal(s:jsoninf, js_encode(s:varinf))
    call assert_equal(s:jsonnan, js_encode(s:varnan))
  endif

  call assert_equal(s:jsonl1, js_encode(s:varl1))
  call assert_equal(s:jsonl2, js_encode(s:varl2))
  call assert_equal(s:jsonl3, js_encode(s:varl3))

  call assert_equal(s:jsd1, js_encode(s:vard1))
  call assert_equal(s:jsd2, js_encode(s:vard2))
  call assert_equal(s:jsd3, js_encode(s:vard3))
  call assert_equal(s:jsd4, js_encode(s:vard4))

  call assert_equal(s:jsonvals, js_encode(s:varvals))

  call assert_fails('echo js_encode(function("tr"))', 'E474:')
  call assert_fails('echo js_encode([function("tr")])', 'E474:')

  silent! let res = js_encode(function("tr"))
  call assert_equal("", res)

  call assert_equal(s:jsl5, js_encode(s:varl5))
endfunc

func Test_js_decode()
  call assert_equal(s:var1, js_decode(s:json1))
  call assert_equal(s:var2, js_decode(s:json2))
  call assert_equal(s:var3, js_decode(s:json3))
  call assert_equal(s:var4, js_decode(s:json4))
  call assert_equal(s:var5, js_decode(s:json5))

  if has('multi_byte')
    call assert_equal(s:varmb, js_decode(s:jsonmb))
    call assert_equal(s:varsp1, js_decode(s:jsonsp1))
    call assert_equal(s:varsp2, js_decode(s:jsonsp2))
  endif

  call assert_equal(s:varnr, js_decode(s:jsonnr))
  if has('float')
    call assert_equal(s:varfl, js_decode(s:jsonfl))
    call assert_equal(s:varinf, js_decode(s:jsoninf))
    call assert_true(isnan(js_decode(s:jsonnan)))
  endif

  call assert_equal(s:varl1, js_decode(s:jsonl1))
  call assert_equal(s:varl2x, js_decode(s:jsonl2))
  call assert_equal(s:varl2x, js_decode(s:jsonl2s))
  call assert_equal(s:varl3, js_decode(s:jsonl3))

  call assert_equal(s:vard1, js_decode(s:jsond1))
  call assert_equal(s:vard1, js_decode(s:jsd1))
  call assert_equal(s:vard2x, js_decode(s:jsond2))
  call assert_equal(s:vard2x, js_decode(s:jsd2))
  call assert_equal(s:vard2x, js_decode(s:jsond2s))
  call assert_equal(s:vard2x, js_decode(s:jsd2s))
  call assert_equal(s:vard3, js_decode(s:jsond3))
  call assert_equal(s:vard3, js_decode(s:jsd3))
  call assert_equal(s:vard4x, js_decode(s:jsond4))
  call assert_equal(s:vard4x, js_decode(s:jsd4))

  call assert_equal(s:varvals, js_decode(s:jsonvals))

  call assert_equal(v:true, js_decode('true'))
  call assert_equal(type(v:true), type(js_decode('true')))
  call assert_equal(v:none, js_decode(''))
  call assert_equal(type(v:none), type(js_decode('')))
  call assert_equal("", js_decode('""'))

  call assert_equal({'n': 1}, js_decode('{"n":1,}'))

  call assert_fails('call js_decode("\"")', "E474:")
  call assert_fails('call js_decode("blah")', "E474:")
  call assert_fails('call js_decode("true blah")', "E474:")
  call assert_fails('call js_decode("<foobar>")', "E474:")

  call assert_fails('call js_decode("{")', "E474:")
  call assert_fails('call js_decode("{foobar}")', "E474:")
  call assert_fails('call js_decode("{\"n\",")', "E474:")
  call assert_fails('call js_decode("{\"n\":")', "E474:")
  call assert_fails('call js_decode("{\"n\":1")', "E474:")
  call assert_fails('call js_decode("{\"n\":1,")', "E474:")
  call assert_fails('call js_decode("{\"n\",1}")', "E474:")
  call assert_fails('call js_decode("{-}")', "E474:")

  call assert_fails('call js_decode("[foobar]")', "E474:")
  call assert_fails('call js_decode("[")', "E474:")
  call assert_fails('call js_decode("[1")', "E474:")
  call assert_fails('call js_decode("[1,")', "E474:")
  call assert_fails('call js_decode("[1 2]")', "E474:")

  call assert_equal(s:varl5, js_decode(s:jsl5))
endfunc
